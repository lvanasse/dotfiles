# Server SSD Fast Tier

This server config declares the Samsung SSD 840 PRO fast tier with Disko:

- device: `/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S12JNEAD201328N`
- filesystem: ext4
- label: `ssd-fast`
- mountpoint: `/mnt/ssd`

The SSD is not part of mergerfs and is not part of SnapRAID data or parity. It is
for appdata, metadata, databases, and bounded scratch only. Permanent media stays
on the HDD pool under `/mnt/storage`.

Normal deploys with `nohm server --target-host 192.168.0.50`,
`nh os switch`, or `nixos-rebuild switch` do not partition or format disks. They
only evaluate the existing Disko declaration and mount the filesystem once it
exists.

## Disko Provisioning

Only run Disko provisioning mode after confirming the target device with
`lsblk -f` and `readlink -f /dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S12JNEAD201328N`.

This is the explicit destructive step. `disko --mode disko` partitions and
formats selected disks. On an already installed server, select only `fastTier`
so the OS SSD is not touched:

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --arg diskNames '[ "fastTier" ]' ./hardware/server/disko.nix
```

## Migration

Do not delete existing appdata during the first switch.

1. Provision the SSD with Disko if needed.
2. Stop the affected containers.
3. Copy old appdata into the new SSD roots, preserving ownership and metadata:

```bash
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/jellyfin/ /mnt/ssd/appdata/docker/jellyfin/config/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/audiobookshelf/config/ /mnt/ssd/appdata/docker/audiobookshelf/config/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/audiobookshelf/metadata/ /mnt/ssd/appdata/docker/audiobookshelf/metadata/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/calibre-web-automated/config/ /mnt/ssd/appdata/docker/cwa/config/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/calibre-web-automated/plugins/ /mnt/ssd/appdata/docker/cwa/plugins/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/vaultwarden/ /mnt/ssd/appdata/docker/vaultwarden/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/linkwarden/ /mnt/ssd/appdata/docker/linkwarden/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/actual/ /mnt/ssd/appdata/docker/actual-budget/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/sonarr/ /mnt/ssd/appdata/docker/sonarr/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/radarr/ /mnt/ssd/appdata/docker/radarr/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/bazarr/ /mnt/ssd/appdata/docker/bazarr/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/lidarr/ /mnt/ssd/appdata/docker/lidarr/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/prowlarr/ /mnt/ssd/appdata/docker/prowlarr/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/jellyseerr/ /mnt/ssd/appdata/docker/jellyseerr/
sudo rsync -aHAX --numeric-ids /mnt/storage/appdata/qbittorrent/ /mnt/ssd/appdata/docker/qbittorrent/
sudo rsync -aHAX --numeric-ids /mnt/storage/appdata/mariadb/ /mnt/ssd/appdata/docker/mariadb/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/nextcloud/ /mnt/ssd/appdata/docker/nextcloud/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/vikunja/ /mnt/ssd/appdata/docker/vikunja/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/cloudflared/ /mnt/ssd/appdata/docker/cloudflared/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/headplane/ /mnt/ssd/appdata/docker/headplane/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/mousehole/ /mnt/ssd/appdata/docker/mousehole/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/shelfmark/ /mnt/ssd/appdata/docker/shelfmark/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/annotationsync/ /mnt/ssd/appdata/docker/annotationsync/
sudo rsync -aHAX --numeric-ids /mnt/data3/appdata/dockhand/ /mnt/ssd/appdata/docker/dockhand/
```

Repeat the same pattern for other moved service roots, for example:

```bash
sudo rsync -aHAX --numeric-ids /old/path/ /mnt/ssd/appdata/docker/<service>/
```

4. Verify ownership and permissions, especially services running as `99:100`.
5. Switch the NixOS config.
6. Run `nixos-rebuild switch`.
7. Start containers and verify the services.
8. Only after successful service verification, remove old appdata.

## Placement Policy

Back up:

- `/mnt/ssd/appdata/docker`
- compose/config files if any are added outside this repo
- important service databases

Do not back up:

- `/mnt/ssd/scratch/downloads`
- `/mnt/ssd/scratch/transcodes`
- `/mnt/ssd/scratch/processing`
- `/mnt/ssd/scratch/imports`
- `/mnt/ssd/scratch/hot-media`

Priority on the 500 GB SSD:

1. Docker appdata, config, and databases.
2. Jellyfin, Audiobookshelf, and CWA metadata.
3. Jellyfin transcodes.
4. Downloads, imports, and conversions.
5. Hot-media cache only if there is enough free space.
