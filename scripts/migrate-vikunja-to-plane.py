#!/usr/bin/env python3
"""Migrate one Vikunja project to an isolated Plane staging project.

The default mode is a read-only dry run. Plane writes require both --apply and
an API token stored outside the Git worktree. The source PostgreSQL transaction
is explicitly read-only; attachments are only streamed from Vikunja's volume.

This script intentionally does not promote FQI to FQ. Promotion is a separate,
human-approved operation after the staging import has been verified.
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import stat
import subprocess
import sys
import tempfile
import time
import uuid
from collections.abc import Iterable
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urljoin
from urllib.request import Request, urlopen

EXTERNAL_SOURCE = "vikunja"
CONTENT_FORMAT_MARKER = "Vikunja readable content v2"
# Plane's project API rejects parentheses and other special characters in names.
STAGING_NAME = "Faudrait Que Vikunja import"
STAGING_IDENTIFIER = "FQI"
EXPECTED = {
    "tasks": 337,
    "completed": 310,
    "open": 27,
    "descriptions": 70,
    "comments": 88,
    "due_dates": 14,
    "start_dates": 1,
    "priorities": 1,
    "labels": 5,
    "label_assignments": 23,
    "attachments": 5,
}
EXPECTED_BUCKETS = {"À faire": 18, "En cours": 5, "Bloqué": 4, "Fini": 310}
STATE_SPECS = {
    "À faire": {"group": "unstarted", "color": "#6B7280"},
    "En cours": {"group": "started", "color": "#F59E0B"},
    "Bloqué": {"group": "started", "color": "#EF4444"},
    "Fini": {"group": "completed", "color": "#16A34A"},
}
PLANE_DEFAULT_STATES = {
    "Backlog": "backlog",
    "Todo": "unstarted",
    "In Progress": "started",
    "Done": "completed",
    "Cancelled": "cancelled",
}
PRIORITIES = {0: "none", 1: "low", 2: "medium", 3: "high", 4: "urgent", 5: "urgent"}


SOURCE_SQL = r"""
BEGIN TRANSACTION READ ONLY;
WITH source_project AS (
  SELECT * FROM projects WHERE id = %(project_id)s
), active_tasks AS (
  SELECT
    t.*,
    (SELECT b.title
       FROM task_buckets tb
       JOIN buckets b ON b.id = tb.bucket_id
      WHERE tb.task_id = t.id
      ORDER BY tb.project_view_id, b.position
      LIMIT 1) AS bucket
  FROM tasks t
  WHERE t.project_id = %(project_id)s AND t.deleted_at IS NULL
)
SELECT json_build_object(
  'project', (SELECT row_to_json(p) FROM (
    SELECT id, title, description, identifier, created, updated
    FROM source_project
  ) p),
  'tasks', (SELECT coalesce(json_agg(row_to_json(t) ORDER BY t.id), '[]'::json)
    FROM (
      SELECT id, title, description, done, done_at, due_date, start_date,
             priority, created, updated, bucket
      FROM active_tasks
    ) t),
  'labels', (SELECT coalesce(json_agg(row_to_json(l) ORDER BY l.id), '[]'::json)
    FROM (
      SELECT DISTINCT l.id, l.title, l.description, l.hex_color, l.created, l.updated
      FROM labels l
      JOIN label_tasks lt ON lt.label_id = l.id
      JOIN active_tasks t ON t.id = lt.task_id
    ) l),
  'label_links', (SELECT coalesce(json_agg(row_to_json(lt) ORDER BY lt.task_id, lt.label_id), '[]'::json)
    FROM (
      SELECT lt.id, lt.task_id, lt.label_id, lt.created
      FROM label_tasks lt
      JOIN active_tasks t ON t.id = lt.task_id
    ) lt),
  'comments', (SELECT coalesce(json_agg(row_to_json(c) ORDER BY c.id), '[]'::json)
    FROM (
      SELECT c.id, c.task_id, c.comment, c.created, c.updated,
             coalesce(nullif(u.name, ''), u.username, 'unknown') AS author
      FROM task_comments c
      JOIN active_tasks t ON t.id = c.task_id
      LEFT JOIN users u ON u.id = c.author_id
    ) c),
  'attachments', (SELECT coalesce(json_agg(row_to_json(a) ORDER BY a.id), '[]'::json)
    FROM (
      SELECT a.id, a.task_id, a.file_id, f.name, f.mime, f.size, a.created
      FROM task_attachments a
      JOIN active_tasks t ON t.id = a.task_id
      JOIN files f ON f.id = a.file_id
    ) a),
  'deleted_task_ids', (SELECT coalesce(json_agg(t.id ORDER BY t.id), '[]'::json)
    FROM tasks t WHERE t.project_id = %(project_id)s AND t.deleted_at IS NOT NULL)
);
ROLLBACK;
"""


class MigrationError(RuntimeError):
    """A migration precondition or operation failed."""


def run_checked(argv: list[str], *, input_bytes: bytes | None = None) -> bytes:
    try:
        process = subprocess.run(
            argv, input=input_bytes, capture_output=True, check=False
        )
    except OSError as exc:
        raise MigrationError(f"could not execute {argv[0]!r}: {exc}") from exc
    if process.returncode:
        stderr = process.stderr.decode("utf-8", "replace").strip()
        raise MigrationError(f"command failed ({argv[0]}): {stderr}")
    return process.stdout


def extract_source(args: argparse.Namespace) -> dict[str, Any]:
    sql = SOURCE_SQL % {"project_id": int(args.vikunja_project_id)}
    argv = [
        "ssh",
        args.ssh_host,
        "docker",
        "exec",
        "-i",
        args.db_container,
        "psql",
        "-X",
        "--no-psqlrc",
        "-qAt",
        "-v",
        "ON_ERROR_STOP=1",
        "-U",
        args.db_user,
        "-d",
        args.db_name,
    ]
    output = run_checked(argv, input_bytes=sql.encode()).decode("utf-8").strip()
    lines = [line for line in output.splitlines() if line.strip()]
    if len(lines) != 1:
        raise MigrationError(
            f"expected one JSON row from Vikunja, received {len(lines)}"
        )
    try:
        source = json.loads(lines[0])
    except json.JSONDecodeError as exc:
        raise MigrationError(f"Vikunja query did not return valid JSON: {exc}") from exc
    if not source.get("project"):
        raise MigrationError(
            f"Vikunja project {args.vikunja_project_id} does not exist"
        )
    return source


def stream_attachment(
    args: argparse.Namespace, file_id: int, *, return_data: bool
) -> tuple[str, int, bytes | None]:
    remote_path = f"{args.attachment_root.rstrip('/')}/{int(file_id)}"
    try:
        process = subprocess.Popen(
            ["ssh", args.ssh_host, "cat", "--", remote_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as exc:
        raise MigrationError(f"could not read attachment {file_id}: {exc}") from exc
    assert process.stdout is not None
    digest = hashlib.sha256()
    size = 0
    chunks: list[bytes] | None = [] if return_data else None
    while True:
        chunk = process.stdout.read(1024 * 1024)
        if not chunk:
            break
        size += len(chunk)
        digest.update(chunk)
        if chunks is not None:
            chunks.append(chunk)
    stderr = (
        process.stderr.read().decode("utf-8", "replace").strip()
        if process.stderr
        else ""
    )
    if process.wait() != 0:
        raise MigrationError(f"could not read attachment {file_id}: {stderr}")
    return digest.hexdigest(), size, b"".join(chunks) if chunks is not None else None


def inline_markdown(value: str) -> str:
    escaped = html.escape(value, quote=True)
    escaped = re.sub(r"`([^`]+)`", r"<code>\1</code>", escaped)
    escaped = re.sub(
        r"\[([^\]]+)\]\(((?:https?://|mailto:)[^\s)]+)\)",
        r'<a href="\2">\1</a>',
        escaped,
    )
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    escaped = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", escaped)
    return escaped


def markdown_to_safe_html(markdown: str) -> str:
    """Render a conservative Markdown subset after escaping all raw HTML."""
    if not markdown.strip():
        return ""
    rendered: list[str] = []
    paragraph: list[str] = []
    list_kind: str | None = None
    in_code = False
    code_lines: list[str] = []

    def close_paragraph() -> None:
        if paragraph:
            rendered.append(
                f"<p>{'<br>'.join(inline_markdown(x) for x in paragraph)}</p>"
            )
            paragraph.clear()

    def close_list() -> None:
        nonlocal list_kind
        if list_kind:
            rendered.append(f"</{list_kind}>")
            list_kind = None

    for line in markdown.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if line.startswith("```"):
            close_paragraph()
            close_list()
            if in_code:
                rendered.append(
                    "<pre><code>" + html.escape("\n".join(code_lines)) + "</code></pre>"
                )
                code_lines.clear()
                in_code = False
            else:
                in_code = True
            continue
        if in_code:
            code_lines.append(line)
            continue
        heading = re.match(r"^(#{1,6})\s+(.*)$", line)
        item = re.match(r"^\s*([-*+] |\d+[.] )(.*)$", line)
        quote = re.match(r"^>\s?(.*)$", line)
        if heading:
            close_paragraph()
            close_list()
            level = len(heading.group(1))
            rendered.append(f"<h{level}>{inline_markdown(heading.group(2))}</h{level}>")
        elif item:
            close_paragraph()
            wanted = "ol" if item.group(1)[0].isdigit() else "ul"
            if list_kind != wanted:
                close_list()
                rendered.append(f"<{wanted}>")
                list_kind = wanted
            rendered.append(f"<li>{inline_markdown(item.group(2))}</li>")
        elif quote:
            close_paragraph()
            close_list()
            rendered.append(
                f"<blockquote><p>{inline_markdown(quote.group(1))}</p></blockquote>"
            )
        elif not line.strip():
            close_paragraph()
            close_list()
        else:
            close_list()
            paragraph.append(line)
    if in_code:
        rendered.append(
            "<pre><code>" + html.escape("\n".join(code_lines)) + "</code></pre>"
        )
    close_paragraph()
    close_list()
    return "".join(rendered)


class ReadableHTMLParser(HTMLParser):
    """Turn Vikunja's editor HTML into conservative, readable plain text."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.list_depth = 0
        self.suppressed_depth = 0
        self.links: list[tuple[str, list[str]]] = []

    def newline(self) -> None:
        if self.parts and not self.parts[-1].endswith("\n"):
            self.parts.append("\n")

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = dict(attrs)
        if tag in {"script", "style"}:
            self.suppressed_depth += 1
            return
        if self.suppressed_depth:
            return
        if tag in {"ul", "ol"}:
            self.newline()
            self.list_depth += 1
        elif tag == "li":
            self.newline()
            checked = attributes.get("data-checked")
            marker = (
                f"[{('x' if checked == 'true' else ' ')}] "
                if checked is not None
                else ""
            )
            self.parts.append("  " * max(0, self.list_depth - 1) + f"- {marker}")
        elif tag == "br":
            self.newline()
        elif tag in {"p", "div", "blockquote", "h1", "h2", "h3", "h4", "h5", "h6"}:
            current = self.parts[-1] if self.parts else ""
            if not re.search(r"(?:- |\[[ x]\] )$", current):
                self.newline()
        elif tag == "a":
            self.links.append((attributes.get("href") or "", []))

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style"}:
            self.suppressed_depth = max(0, self.suppressed_depth - 1)
            return
        if self.suppressed_depth:
            return
        if tag in {"li", "p", "div", "blockquote", "h1", "h2", "h3", "h4", "h5", "h6"}:
            self.newline()
        elif tag in {"ul", "ol"}:
            self.list_depth = max(0, self.list_depth - 1)
            self.newline()
        elif tag == "a" and self.links:
            href, link_text = self.links.pop()
            visible = "".join(link_text).strip()
            if href and href != visible and re.match(r"^(?:https?://|mailto:)", href):
                self.parts.append(f" ({href})")

    def handle_data(self, data: str) -> None:
        if self.suppressed_depth:
            return
        self.parts.append(data)
        for _, link_text in self.links:
            link_text.append(data)

    def text(self) -> str:
        lines = [
            re.sub(r"[ \t]+", " ", line).strip()
            for line in "".join(self.parts).splitlines()
        ]
        compact: list[str] = []
        for line in lines:
            if line or (compact and compact[-1]):
                compact.append(line)
        return "\n".join(compact).strip()


def source_content_to_safe_html(content: str) -> str:
    if re.search(r"<[A-Za-z][^>]*>", content):
        parser = ReadableHTMLParser()
        parser.feed(content)
        parser.close()
        content = parser.text()
    return markdown_to_safe_html(content)


def source_note(task: dict[str, Any]) -> str:
    completion = (
        task["done_at"]
        if task.get("done_at")
        else task["updated"]
        if task["bucket"] == "Fini"
        else None
    )
    fields = [
        f"Vikunja task #{task['id']}",
        f"created {task['created']}",
        f"updated {task['updated']}",
        CONTENT_FORMAT_MARKER,
    ]
    if completion:
        fields.append(f"source completion {completion}")
    return (
        "<hr><p><em>Imported metadata: " + html.escape("; ".join(fields)) + ".</em></p>"
    )


def summarize(source: dict[str, Any]) -> dict[str, Any]:
    tasks = source["tasks"]
    bucket_counts = {name: 0 for name in EXPECTED_BUCKETS}
    for task in tasks:
        bucket = task.get("bucket")
        bucket_counts[bucket] = bucket_counts.get(bucket, 0) + 1
    completed = sum(1 for task in tasks if task.get("bucket") == "Fini")
    return {
        "tasks": len(tasks),
        "completed": completed,
        "open": len(tasks) - completed,
        "bucket_counts": bucket_counts,
        "descriptions": sum(
            bool((task.get("description") or "").strip()) for task in tasks
        ),
        "comments": len(source["comments"]),
        "due_dates": sum(task.get("due_date") is not None for task in tasks),
        "start_dates": sum(task.get("start_date") is not None for task in tasks),
        "priorities": sum(int(task.get("priority") or 0) != 0 for task in tasks),
        "labels": len(source["labels"]),
        "label_assignments": len(source["label_links"]),
        "attachments": len(source["attachments"]),
        "deleted_tasks_excluded": len(source["deleted_task_ids"]),
    }


def validate_source(source: dict[str, Any], summary: dict[str, Any]) -> None:
    errors = []
    for key, expected in EXPECTED.items():
        if summary[key] != expected:
            errors.append(f"{key}: expected {expected}, found {summary[key]}")
    if summary["bucket_counts"] != EXPECTED_BUCKETS:
        errors.append(
            f"bucket counts: expected {EXPECTED_BUCKETS}, found {summary['bucket_counts']}"
        )
    if summary["deleted_tasks_excluded"] != 1:
        errors.append(
            f"deleted tasks: expected 1 excluded, found {summary['deleted_tasks_excluded']}"
        )
    missing_buckets = [
        task["id"] for task in source["tasks"] if task.get("bucket") not in STATE_SPECS
    ]
    if missing_buckets:
        errors.append(f"tasks with unknown/missing buckets: {missing_buckets}")
    if errors:
        raise MigrationError("source validation failed:\n  - " + "\n  - ".join(errors))


def build_manifest(
    source: dict[str, Any],
    summary: dict[str, Any],
    attachment_meta: dict[int, dict[str, Any]],
) -> dict[str, Any]:
    links_by_task: dict[int, list[int]] = {}
    for link in source["label_links"]:
        links_by_task.setdefault(link["task_id"], []).append(link["label_id"])
    comments_by_task: dict[int, list[int]] = {}
    for comment in source["comments"]:
        comments_by_task.setdefault(comment["task_id"], []).append(comment["id"])
    attachments_by_task: dict[int, list[int]] = {}
    for attachment in source["attachments"]:
        attachments_by_task.setdefault(attachment["task_id"], []).append(
            attachment["id"]
        )
    return {
        "schema_version": 1,
        "mode": "dry-run",
        "source": {
            "system": "vikunja",
            "project_id": source["project"]["id"],
            "project_title": source["project"]["title"],
            "project_created": source["project"]["created"],
            "project_updated": source["project"]["updated"],
            "deleted_task_ids_excluded": source["deleted_task_ids"],
        },
        "target": {
            "project_name": STAGING_NAME,
            "project_identifier": STAGING_IDENTIFIER,
            "project_id": None,
        },
        "summary": summary,
        "state_mappings": {
            name: {**spec, "target_id": None} for name, spec in STATE_SPECS.items()
        },
        "label_mappings": {
            str(label["id"]): {"name": label["title"], "target_id": None}
            for label in source["labels"]
        },
        "task_mappings": {
            str(task["id"]): {
                "target_id": None,
                "bucket": task["bucket"],
                "created": task["created"],
                "updated": task["updated"],
                "source_done": task["done"],
                "source_done_at": task["done_at"],
                "completion_time": task["done_at"]
                or (task["updated"] if task["bucket"] == "Fini" else None),
                "label_ids": sorted(links_by_task.get(task["id"], [])),
                "comment_ids": comments_by_task.get(task["id"], []),
                "attachment_ids": attachments_by_task.get(task["id"], []),
            }
            for task in source["tasks"]
        },
        "comment_mappings": {
            str(item["id"]): {"task_id": item["task_id"], "target_id": None}
            for item in source["comments"]
        },
        "attachment_mappings": {
            str(item["id"]): {
                "task_id": item["task_id"],
                "file_id": item["file_id"],
                "filename": item["name"],
                "mime": item["mime"],
                "size": item["size"],
                "sha256": attachment_meta[item["id"]]["sha256"],
                "target_id": None,
            }
            for item in source["attachments"]
        },
        "failures": [],
    }


def write_manifest(path: Path, manifest: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=path.parent, prefix=f".{path.name}.", delete=False
    ) as handle:
        json.dump(manifest, handle, ensure_ascii=False, indent=2, sort_keys=True)
        handle.write("\n")
        temporary = Path(handle.name)
    temporary.replace(path)


class PlaneClient:
    def __init__(self, base_url: str, workspace: str, token: str) -> None:
        self.base_url = base_url.rstrip("/") + "/"
        self.workspace = workspace
        self.token = token

    def request(
        self, method: str, path: str, payload: dict[str, Any] | None = None
    ) -> Any:
        url = urljoin(self.base_url, path.lstrip("/"))
        data = json.dumps(payload).encode() if payload is not None else None
        headers = {
            "X-API-Key": self.token,
            "Accept": "application/json",
            # Cloudflare rejects urllib's default signature before it reaches Plane.
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/140.0 Safari/537.36",
        }
        if data is not None:
            headers["Content-Type"] = "application/json"
        for attempt in range(6):
            request = Request(url, data=data, headers=headers, method=method)
            try:
                with urlopen(request, timeout=90) as response:
                    body = response.read()
                    return json.loads(body) if body else None
            except HTTPError as exc:
                body = exc.read().decode("utf-8", "replace")[:1000]
                if exc.code == 429 and attempt < 5:
                    reset = exc.headers.get("X-RateLimit-Reset")
                    delay = (
                        max(1.0, float(reset) - time.time())
                        if reset
                        else 15.0 * (attempt + 1)
                    )
                    time.sleep(min(delay, 65.0))
                    continue
                raise MigrationError(
                    f"Plane {method} {path} returned HTTP {exc.code}: {body}"
                ) from exc
            except URLError as exc:
                raise MigrationError(
                    f"Plane {method} {path} failed: {exc.reason}"
                ) from exc
        raise MigrationError(f"Plane {method} {path} exhausted retries")

    def all(self, path: str) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        cursor: str | None = None
        while True:
            separator = "&" if "?" in path else "?"
            suffix = f"{separator}{urlencode({'per_page': 100, **({'cursor': cursor} if cursor else {})})}"
            response = self.request("GET", path + suffix)
            if isinstance(response, list):
                items.extend(response)
                break
            if not isinstance(response, dict) or "results" not in response:
                raise MigrationError(f"unexpected paginated response from {path}")
            items.extend(response["results"])
            if not response.get("next_page_results"):
                break
            cursor = response.get("next_cursor")
            if not cursor:
                raise MigrationError(
                    f"Plane said another page exists for {path} but supplied no cursor"
                )
        return items

    def workspace_path(self, suffix: str) -> str:
        return f"/api/v1/workspaces/{self.workspace}/{suffix.lstrip('/')}"


def read_token(path: Path, repo_root: Path) -> str:
    resolved = path.expanduser().resolve()
    try:
        resolved.relative_to(repo_root.resolve())
    except ValueError:
        pass
    else:
        raise MigrationError("the Plane token file must be outside the Git worktree")
    info = resolved.stat()
    if not stat.S_ISREG(info.st_mode):
        raise MigrationError("the Plane token path is not a regular file")
    if info.st_mode & (stat.S_IRWXG | stat.S_IRWXO):
        raise MigrationError("the Plane token file must be private (chmod 600)")
    token = resolved.read_text(encoding="utf-8").strip()
    if not token:
        raise MigrationError("the Plane token file is empty")
    return token


def project_path(client: PlaneClient, project_id: str, suffix: str = "") -> str:
    base = client.workspace_path(f"projects/{project_id}/")
    return base + suffix.lstrip("/")


def find_external(
    items: Iterable[dict[str, Any]], external_id: int | str
) -> dict[str, Any] | None:
    wanted = str(external_id)
    matches = [
        item
        for item in items
        if item.get("external_source") == EXTERNAL_SOURCE
        and str(item.get("external_id")) == wanted
    ]
    if len(matches) > 1:
        raise MigrationError(
            f"Plane contains duplicate {EXTERNAL_SOURCE} external_id {wanted}"
        )
    return matches[0] if matches else None


def encode_multipart(
    fields: dict[str, str], filename: str, mime: str, content: bytes
) -> tuple[bytes, str]:
    boundary = "----vikunja-plane-" + uuid.uuid4().hex
    chunks: list[bytes] = []
    for name, value in fields.items():
        chunks.extend(
            [
                f"--{boundary}\r\n".encode(),
                f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode(),
                str(value).encode(),
                b"\r\n",
            ]
        )
    safe_filename = filename.replace('"', "_").replace("\r", "_").replace("\n", "_")
    chunks.extend(
        [
            f"--{boundary}\r\n".encode(),
            f'Content-Disposition: form-data; name="file"; filename="{safe_filename}"\r\n'.encode(),
            f"Content-Type: {mime}\r\n\r\n".encode(),
            content,
            b"\r\n",
            f"--{boundary}--\r\n".encode(),
        ]
    )
    return b"".join(chunks), boundary


def upload_presigned(
    upload_data: dict[str, Any], filename: str, mime: str, content: bytes
) -> None:
    body, boundary = encode_multipart(upload_data["fields"], filename, mime, content)
    request = Request(
        upload_data["url"],
        data=body,
        headers={
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            # Cloudflare rejects urllib's default Python signature on uploads.
            "User-Agent": (
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                "Chrome/140.0 Safari/537.36"
            ),
            "Origin": "https://plane.ludovicvanasse.com",
            "Referer": "https://plane.ludovicvanasse.com/",
        },
        method="POST",
    )
    try:
        with urlopen(request, timeout=180) as response:
            response.read()
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")[:1000]
        raise MigrationError(
            f"attachment upload returned HTTP {exc.code}: {detail}"
        ) from exc
    except URLError as exc:
        raise MigrationError(f"attachment upload failed: {exc.reason}") from exc


def apply_import(
    args: argparse.Namespace,
    source: dict[str, Any],
    manifest: dict[str, Any],
    token: str,
) -> None:
    client = PlaneClient(args.plane_url, args.workspace, token)
    projects_path = client.workspace_path("projects/")
    projects = client.all(projects_path)
    staging_matches = [
        project
        for project in projects
        if project.get("identifier") == STAGING_IDENTIFIER
    ]
    if len(staging_matches) > 1:
        raise MigrationError(
            f"multiple Plane projects use identifier {STAGING_IDENTIFIER}"
        )
    if staging_matches:
        project = staging_matches[0]
        if project.get("name") != STAGING_NAME:
            raise MigrationError(
                f"identifier {STAGING_IDENTIFIER} belongs to unexpected project {project.get('name')!r}"
            )
    else:
        project = client.request(
            "POST",
            projects_path,
            {
                "name": STAGING_NAME,
                "identifier": STAGING_IDENTIFIER,
                "description": (
                    f"Staging import from Vikunja project {source['project']['id']}. "
                    "Verify before promotion."
                ),
            },
        )
    project_id = project["id"]
    manifest["target"]["project_id"] = project_id

    states_path = project_path(client, project_id, "states/")
    states = client.all(states_path)
    state_ids: dict[str, str] = {}
    for name, spec in STATE_SPECS.items():
        matches = [state for state in states if state.get("name") == name]
        if len(matches) > 1:
            raise MigrationError(f"duplicate state name {name!r} in staging project")
        if matches:
            state = matches[0]
            if state.get("group") != spec["group"]:
                raise MigrationError(
                    f"state {name!r} has group {state.get('group')!r}, expected {spec['group']!r}"
                )
        else:
            state = client.request("POST", states_path, {"name": name, **spec})
            states.append(state)
        state_ids[name] = state["id"]
        manifest["state_mappings"][name]["target_id"] = state["id"]

    labels_path = project_path(client, project_id, "labels/")
    existing_labels = client.all(labels_path)
    label_ids: dict[int, str] = {}
    for label in source["labels"]:
        external = find_external(existing_labels, label["id"])
        matches = [
            candidate
            for candidate in existing_labels
            if candidate.get("name") == label["title"]
        ]
        if len(matches) > 1:
            raise MigrationError(f"duplicate Plane label {label['title']!r}")
        if external and matches and external["id"] != matches[0]["id"]:
            raise MigrationError(
                f"Vikunja label {label['id']} conflicts with Plane label {label['title']!r}"
            )
        if external:
            target = external
        elif matches:
            target = client.request(
                "PATCH",
                labels_path + f"{matches[0]['id']}/",
                {
                    "external_source": EXTERNAL_SOURCE,
                    "external_id": str(label["id"]),
                },
            )
        else:
            target = client.request(
                "POST",
                labels_path,
                {
                    "name": label["title"],
                    "description": label.get("description") or "",
                    "color": "#" + (label.get("hex_color") or "6B7280").lstrip("#"),
                    "external_source": EXTERNAL_SOURCE,
                    "external_id": str(label["id"]),
                },
            )
            existing_labels.append(target)
        label_ids[label["id"]] = target["id"]
        manifest["label_mappings"][str(label["id"])]["target_id"] = target["id"]

    links_by_task: dict[int, list[int]] = {}
    for link in source["label_links"]:
        links_by_task.setdefault(link["task_id"], []).append(link["label_id"])
    items_path = project_path(client, project_id, "work-items/")
    existing_items = client.all(items_path)
    item_ids: dict[int, str] = {}
    for task in source["tasks"]:
        target = find_external(existing_items, task["id"])
        if target is None:
            description = source_content_to_safe_html(task.get("description") or "")
            if description:
                description += source_note(task)
            payload: dict[str, Any] = {
                "name": task["title"],
                "priority": PRIORITIES.get(int(task.get("priority") or 0), "urgent"),
                "state": state_ids[task["bucket"]],
                "labels": [
                    label_ids[label_id]
                    for label_id in sorted(links_by_task.get(task["id"], []))
                ],
                "external_source": EXTERNAL_SOURCE,
                "external_id": str(task["id"]),
            }
            if description:
                payload["description_html"] = description
            if task.get("start_date"):
                payload["start_date"] = task["start_date"][:10]
            if task.get("due_date"):
                payload["target_date"] = task["due_date"][:10]
            target = client.request("POST", items_path, payload)
            existing_items.append(target)
        elif (task.get("description") or "").strip() and CONTENT_FORMAT_MARKER not in (
            target.get("description_html") or ""
        ):
            description = source_content_to_safe_html(
                task["description"]
            ) + source_note(task)
            target = client.request(
                "PATCH",
                items_path + f"{target['id']}/",
                {"description_html": description},
            )
        item_ids[task["id"]] = target["id"]
        manifest["task_mappings"][str(task["id"])]["target_id"] = target["id"]

    for comment in source["comments"]:
        item_id = item_ids[comment["task_id"]]
        comments_path = project_path(
            client, project_id, f"work-items/{item_id}/comments/"
        )
        existing = client.all(comments_path)
        target = find_external(existing, comment["id"])
        if target is None:
            attribution = (
                f"<p><em>Imported from Vikunja comment #{comment['id']} by "
                f"{html.escape(comment['author'])}; created {html.escape(comment['created'])}; "
                f"updated {html.escape(comment['updated'])}; {CONTENT_FORMAT_MARKER}.</em></p>"
            )
            target = client.request(
                "POST",
                comments_path,
                {
                    "comment_html": attribution
                    + source_content_to_safe_html(comment.get("comment") or ""),
                    "comment_json": {},
                    "access": "INTERNAL",
                    "external_source": EXTERNAL_SOURCE,
                    "external_id": str(comment["id"]),
                },
            )
        elif CONTENT_FORMAT_MARKER not in (target.get("comment_html") or ""):
            attribution = (
                f"<p><em>Imported from Vikunja comment #{comment['id']} by "
                f"{html.escape(comment['author'])}; created {html.escape(comment['created'])}; "
                f"updated {html.escape(comment['updated'])}; {CONTENT_FORMAT_MARKER}.</em></p>"
            )
            target = client.request(
                "PATCH",
                comments_path + f"{target['id']}/",
                {
                    "comment_html": attribution
                    + source_content_to_safe_html(comment.get("comment") or ""),
                    "comment_json": {},
                    "access": "INTERNAL",
                    "external_source": EXTERNAL_SOURCE,
                    "external_id": str(comment["id"]),
                },
            )
        manifest["comment_mappings"][str(comment["id"])]["target_id"] = target["id"]

    for attachment in source["attachments"]:
        item_id = item_ids[attachment["task_id"]]
        attachments_path = project_path(
            client, project_id, f"work-items/{item_id}/attachments/"
        )
        existing = client.all(attachments_path)
        target = find_external(existing, attachment["id"])
        if target is None:
            checksum, size, content = stream_attachment(
                args, attachment["file_id"], return_data=True
            )
            expected_meta = manifest["attachment_mappings"][str(attachment["id"])]
            if size != attachment["size"] or checksum != expected_meta["sha256"]:
                raise MigrationError(
                    f"attachment {attachment['id']} changed after dry-run validation"
                )
            assert content is not None
            target = client.request(
                "POST",
                attachments_path,
                {
                    "name": attachment["name"],
                    "type": attachment["mime"],
                    "size": size,
                    "external_source": EXTERNAL_SOURCE,
                    "external_id": str(attachment["id"]),
                },
            )
            upload_presigned(
                target["upload_data"], attachment["name"], attachment["mime"], content
            )
            completed = client.request(
                "PATCH", attachments_path + f"{target['asset_id']}/"
            )
            target = completed or target.get("attachment") or target
        manifest["attachment_mappings"][str(attachment["id"])]["target_id"] = (
            target.get("id") or target.get("asset_id")
        )

    refreshed_items = client.all(items_path)
    used_state_ids = {
        str(
            item["state"]["id"]
            if isinstance(item.get("state"), dict)
            else item.get("state")
        )
        for item in refreshed_items
    }
    unstarted_state = next(state for state in states if state.get("name") == "À faire")
    if not unstarted_state.get("default"):
        client.request(
            "PATCH",
            states_path + f"{unstarted_state['id']}/",
            {"default": True},
        )
    for state in states:
        expected_group = PLANE_DEFAULT_STATES.get(state.get("name"))
        if expected_group is None or state.get("group") != expected_group:
            continue
        if str(state["id"]) in used_state_ids:
            raise MigrationError(
                f"refusing to remove in-use default state {state['name']!r}"
            )
        if state.get("default"):
            client.request(
                "PATCH",
                states_path + f"{state['id']}/",
                {"default": False},
            )
        client.request("DELETE", states_path + f"{state['id']}/")
    manifest["mode"] = "apply"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="read and validate Vikunja only (default)",
    )
    mode.add_argument(
        "--apply",
        action="store_true",
        help="create/update only the isolated FQI staging import",
    )
    parser.add_argument("--ssh-host", default="server")
    parser.add_argument("--vikunja-project-id", type=int, default=5)
    parser.add_argument("--db-container", default="vikunja-postgres")
    parser.add_argument("--db-user", default="vikunja")
    parser.add_argument("--db-name", default="vikunja")
    parser.add_argument(
        "--attachment-root", default="/mnt/ssd/appdata/docker/vikunja/files"
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("migration-artifacts/vikunja-plane-manifest.json"),
    )
    parser.add_argument("--plane-url", default="https://plane.ludovicvanasse.com")
    parser.add_argument(
        "--workspace", help="Plane workspace slug; required with --apply"
    )
    parser.add_argument(
        "--token-file",
        type=Path,
        help="private short-lived Plane token file outside this repository",
    )
    args = parser.parse_args()
    if args.apply and (not args.workspace or not args.token_file):
        parser.error("--apply requires --workspace and --token-file")
    return args


def main() -> int:
    args = parse_args()
    manifest: dict[str, Any] | None = None
    try:
        source = extract_source(args)
        summary = summarize(source)
        validate_source(source, summary)
        attachment_meta: dict[int, dict[str, Any]] = {}
        for attachment in source["attachments"]:
            checksum, actual_size, _ = stream_attachment(
                args, attachment["file_id"], return_data=False
            )
            if actual_size != attachment["size"]:
                raise MigrationError(
                    f"attachment {attachment['id']} size mismatch: database={attachment['size']} volume={actual_size}"
                )
            attachment_meta[attachment["id"]] = {
                "sha256": checksum,
                "size": actual_size,
            }
        manifest = build_manifest(source, summary, attachment_meta)
        if args.apply:
            repo_root = Path(__file__).resolve().parent.parent
            token = read_token(args.token_file, repo_root)
            apply_import(args, source, manifest, token)
        write_manifest(args.manifest, manifest)
        print(
            json.dumps(
                {"mode": manifest["mode"], "manifest": str(args.manifest), **summary},
                ensure_ascii=False,
                indent=2,
            )
        )
        return 0
    except (MigrationError, OSError) as exc:
        if manifest is not None:
            manifest["failures"].append(str(exc))
            write_manifest(args.manifest, manifest)
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
