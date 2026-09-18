#!/usr/bin/env python3
"""Rewrite devcontainer /workspaces/<repo> paths in a compile_commands.json to
the host worktree path, so host clangd can index a devcontainer project without
the container running.

Cross-compiled firmware DBs (e.g. TI tiarmclang) are generated inside the
container, so every path is /workspaces/<repo>/...  Host clangd matches files by
path and can't find them, so project-wide go-to-definition breaks. This rewrites
the paths in place. SDK/toolchain headers under /opt/... stay unresolved (you
don't have the toolchain on the host) but your own symbols index fine.

Idempotent. Re-run after each in-container build regenerates the DB.
Usage: clangd-rehost [compile_commands.json ...]   (defaults to build/**)"""
import glob
import json
import os
import re
import subprocess
import sys

WS = re.compile(r"/workspaces/[^/\s\"']+")


def git_root():
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], text=True
        ).strip()
    except Exception:
        return os.getcwd()


def find_dbs(root, args):
    if args:
        return args
    return glob.glob(
        os.path.join(root, "build", "**", "compile_commands.json"), recursive=True
    )


def rehost(db, root):
    with open(db) as f:
        data = json.load(f)
    old = None
    for e in data:
        for k in ("directory", "file"):
            m = WS.search(e.get(k, ""))
            if m:
                old = m.group(0)
                break
        if old:
            break
    if not old:
        print(f"  {db}: already host paths, skipped")
        return
    n = 0
    for e in data:
        for k in ("directory", "file", "command", "output"):
            if k in e and old in e[k]:
                e[k] = e[k].replace(old, root)
                n += 1
        if "arguments" in e:
            e["arguments"] = [a.replace(old, root) for a in e["arguments"]]
    with open(db, "w") as f:
        json.dump(data, f, indent=1)
    print(f"  {db}: {old} -> {root} ({n} fields)")


def main():
    root = git_root()
    dbs = find_dbs(root, sys.argv[1:])
    if not dbs:
        print("no compile_commands.json found under build/", file=sys.stderr)
        return 1
    print(f"host root: {root}")
    for db in dbs:
        rehost(db, root)
    return 0


sys.exit(main())
