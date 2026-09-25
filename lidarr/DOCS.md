# Lidarr Add-on Documentation

## Overview

This add-on provides a self-hosted **[Lidarr](https://lidarr.audio/)** instance
(music collection manager for Usenet and BitTorrent users), based on the official
**[LinuxServer.io image](https://docs.linuxserver.io/images/docker-lidarr/)**
and integrated with Home Assistant via Ingress.

Use it to manage your music library: monitor artists, grab releases automatically
via indexers (Prowlarr, …) and download clients (SABnzbd, NZBGet, qBittorrent,
Transmission, …), organize files and fetch metadata.

## Requirements

- Home Assistant Supervisor 2023.12 or later
- Internet access at build time (to fetch the LinuxServer base image)

## Add-on options

### `PUID` / `PGID`

Linux User ID / Group ID used to read and write your music files.
Defaults (`0`/`0`, root) give full access to `/share` and `/media`.
If your music files belong to a specific user (e.g. `1000:1000`), set these
accordingly.

### `TZ`

Timezone (e.g. `Europe/Paris`). Used for timestamps in the Lidarr UI and logs.

Example:

```yaml
PUID: 0
PGID: 0
TZ: Europe/Paris
```

## How to use

1. Start the add-on and open it (sidebar via Ingress, or port `8686` if exposed).
2. Go through the Lidarr setup wizard if shown.
3. Add a **Root Folder** under Settings → Media Management, e.g. `/share/music`
   or `/media/music`.
4. Add an **indexer** (manually or via Prowlarr: Settings → Indexers) and a
   **download client** (Settings → Download Clients), pointing its completed
   folder to `/share/downloads`.
5. Add artists and let Lidarr organize your library.

### Notes

- The add-on's `/config` holds Lidarr's database and settings. It is stored in
  the add-on's private storage and included in (partial) Home Assistant backups.
  `logs/`, `MediaCover/` cache and SQLite journals are excluded from backups.
- Do **not** update Lidarr from inside its own UI (Settings → General →
  Updates): with Docker-based installs, updates are delivered through new
  add-on versions. Automatic in-app updates are disabled by the LinuxServer image.

## Ingress

Lidarr is accessible through Home Assistant's Ingress feature. The
`ingress_port` is set to `8686`.

If Ingress ever renders a blank page, expose port `8686` (Configuration tab →
Network) and use the direct URL below.

## Port mapping

If you need to expose Lidarr directly (required for other *arr apps or download
clients running outside Home Assistant), map port `8686/tcp`. Home Assistant
Ingress remains recommended for browser access.

## Available directories

| Path | Description |
| ---- | ----------- |
| `/config` | Lidarr configuration and database (private add-on storage) |
| `/share` | Shared data (`/share/music` and `/share/downloads` created on first start) |
| `/media` | Media shared with Home Assistant |
| `/backup` | Home Assistant backups |
