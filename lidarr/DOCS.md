# Lidarr Add-on Documentation

## Overview

This add-on provides a self-hosted **[Lidarr](https://lidarr.audio/)** instance
(music collection manager for Usenet and BitTorrent users), based on the official
**[LinuxServer.io image](https://docs.linuxserver.io/images/docker-lidarr/)**.

The Lidarr web UI is exposed **directly** on port `8686` (no Home Assistant
Ingress): this allows indexers (Prowlarr, …) and download clients (SABnzbd,
NZBGet, qBittorrent, Transmission, …) to reach it.

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

1. Start the add-on and open it via the **Open Web UI** button
   (`http://[IP_DE_HOME_ASSISTANT]:8686`).
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

## Access (no Ingress)

This add-on intentionally does **not** use Home Assistant Ingress. The web UI is
always exposed directly on the local network:

```
http://[IP_DE_HOME_ASSISTANT]:8686
```

The host port can be changed in the add-on's **Network** settings. Direct access
is required so Prowlarr and download clients can communicate with Lidarr.

## Port mapping

Port `8686/tcp` (container) is mapped to host port `8686` by default. The
Develop and Nightly variants default to host ports `8687` and `8688` so all
three can run side by side.

## Available directories

| Path | Description |
| ---- | ----------- |
| `/config` | Lidarr configuration and database (private add-on storage) |
| `/share` | Shared data (`/share/music` and `/share/downloads` created on first start) |
| `/media` | Media shared with Home Assistant |
| `/backup` | Home Assistant backups |
