{ ... }:
{
  flake.modules.nixos."services.audiobookshelf" =
    { pkgs, ... }:
    let
      appDataRoot = "/mnt/ssd/appdata/docker/audiobookshelf";
      audiobookLibraryRoot = "/mnt/storage/data/media/audiobooks";
      podcastLibraryRoot = "/mnt/storage/data/media/podcasts";
      normalizeSingleFileAudiobooks = pkgs.writeShellScript "normalize-single-file-audiobooks" ''
        set -euo pipefail

        root="${audiobookLibraryRoot}"
        [ -d "$root" ] || exit 0

        ${pkgs.python3}/bin/python3 - <<'PY'
        import json
        import os
        import pathlib
        import re
        import shutil
        import subprocess
        import sys

        root = pathlib.Path("${audiobookLibraryRoot}")
        supported_exts = {".m4b", ".mp3", ".m4a", ".flac", ".ogg"}

        def canonical(value: str) -> str:
            value = value.casefold()
            value = re.sub(r"\s+", " ", value)
            value = re.sub(r"[^\w\s]", "", value)
            return value.strip()

        def clean_book_name(value: str) -> str:
            value = re.sub(r"\s+\((unabridged|abridged)\)$", "", value, flags=re.IGNORECASE)
            value = re.sub(r"\s+", " ", value)
            return value.strip().rstrip(".")

        def read_tags(path: pathlib.Path) -> tuple[str, str] | tuple[None, None]:
            proc = subprocess.run(
                [
                    "${pkgs.ffmpeg-headless}/bin/ffprobe",
                    "-v",
                    "error",
                    "-show_entries",
                    "format_tags=artist,album,title,album_artist",
                    "-of",
                    "json",
                    str(path),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            if proc.returncode != 0:
                return None, None

            try:
                tags = json.loads(proc.stdout).get("format", {}).get("tags", {})
            except json.JSONDecodeError:
                return None, None

            author = (tags.get("album_artist") or tags.get("artist") or "").strip()
            book = clean_book_name((tags.get("album") or tags.get("title") or "").strip())
            return (author or None), (book or None)

        for path in root.glob("*/*"):
            if not path.is_file():
                continue
            if path.suffix.casefold() not in supported_exts:
                continue

            parent = path.parent
            parent_name = parent.name
            author, book = read_tags(path)

            if not author or not book:
                print(f"[audiobookshelf-normalize] skipping {path}: missing author/album metadata", file=sys.stderr)
                continue

            if canonical(parent_name) != canonical(author):
                continue

            if canonical(parent_name) == canonical(book):
                continue

            target_dir = parent / book
            target_file = target_dir / path.name

            if path == target_file:
                continue

            if target_file.exists():
                print(f"[audiobookshelf-normalize] target exists, skipping: {target_file}", file=sys.stderr)
                continue

            if not path.exists():
                continue

            target_dir.mkdir(parents=True, exist_ok=True)
            try:
                shutil.move(str(path), str(target_file))
            except FileNotFoundError:
                continue

            subprocess.run(["chown", "-R", "99:100", str(target_dir)], check=True)
            for current_root, dirnames, filenames in os.walk(target_dir):
                os.chmod(current_root, 0o755)
                for dirname in dirnames:
                    os.chmod(os.path.join(current_root, dirname), 0o755)
                for filename in filenames:
                    os.chmod(os.path.join(current_root, filename), 0o644)

            print(f"[audiobookshelf-normalize] moved {path} -> {target_file}")
        PY
      '';
      watchSingleFileAudiobooks = pkgs.writeShellScript "watch-single-file-audiobooks" ''
        set -euo pipefail

        root="${audiobookLibraryRoot}"
        mkdir -p "$root"

        while true; do
          ${pkgs.inotify-tools}/bin/inotifywait \
            --recursive \
            --event close_write \
            --event moved_to \
            --event create \
            "$root" || sleep 10
          ${normalizeSingleFileAudiobooks}
          sleep 2
        done
      '';
    in
    {
      environment.systemPackages = [
        pkgs.ffmpeg-headless
        pkgs.inotify-tools
      ];

      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0775 99 100 -"
        "d ${appDataRoot}/config 0775 99 100 -"
        "d ${appDataRoot}/metadata 0775 99 100 -"
        "d ${audiobookLibraryRoot} 0775 99 100 -"
        "z ${audiobookLibraryRoot} 0775 99 100 -"
        "d ${podcastLibraryRoot} 0775 99 100 -"
        "z ${podcastLibraryRoot} 0775 99 100 -"
      ];

      virtualisation.oci-containers.containers.audiobookshelf = {
        image = "ghcr.io/advplyr/audiobookshelf:latest";
        environment = {
          TZ = "America/Toronto";
        };
        volumes = [
          "${audiobookLibraryRoot}:/audiobooks"
          "${podcastLibraryRoot}:/podcasts"
          "${appDataRoot}/metadata:/metadata"
          "${appDataRoot}/config:/config"
        ];
        ports = [ "13378:80" ];
        extraOptions = [
          "--user=99:100"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };

      systemd.services.docker-audiobookshelf = {
        requires = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
          "audiobookshelf-normalize-single-file-books.service"
        ];
        wants = [ "audiobookshelf-normalize-single-file-books-watch.service" ];
        after = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
          "audiobookshelf-normalize-single-file-books.service"
          "audiobookshelf-normalize-single-file-books-watch.service"
        ];
      };

      systemd.services.audiobookshelf-normalize-single-file-books = {
        description = "Normalize single-file Audiobookshelf imports into per-book folders";
        requires = [ "mnt-storage.mount" ];
        after = [ "mnt-storage.mount" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = normalizeSingleFileAudiobooks;
        };
      };

      systemd.services.audiobookshelf-normalize-single-file-books-watch = {
        description = "Watch Audiobookshelf imports and normalize single-file books";
        wantedBy = [ "multi-user.target" ];
        requires = [ "mnt-storage.mount" ];
        after = [ "mnt-storage.mount" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = watchSingleFileAudiobooks;
          Restart = "always";
          RestartSec = "10s";
        };
      };

      networking.firewall.allowedTCPPorts = [ 13378 ];
    };
}
