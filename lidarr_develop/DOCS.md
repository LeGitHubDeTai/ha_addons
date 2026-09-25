# Lidarr Develop Add-on Documentation

## Overview

This add-on provides a **[Lidarr](https://lidarr.audio/) `develop` branch** instance,
based on the **[LinuxServer.io `develop` image](https://docs.linuxserver.io/images/docker-lidarr/)**
and integrated with Home Assistant via Ingress.

It tracks Lidarr pre-releases: newest features first, stability not guaranteed.
For daily use, install the stable [**Lidarr**](../lidarr/) add-on instead.

## Requirements

- Home Assistant Supervisor 2023.12 or later
- Internet access at build time (to fetch the LinuxServer base image)

## Add-on options

### `PUID` / `PGID`

Linux User ID / Group ID used to read and write your music files.
Defaults (`0`/`0`, root) give full access to `/share` and `/media`.

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
2. Add a **Root Folder** under Settings → Media Management. If you run the stable
   variant side by side, use a **separate** folder (e.g. `/share/music-develop`).
3. Add an **indexer** and a **download client** (completed folder e.g.
   `/share/downloads`).

### Notes

- This variant uses its own private `/config` storage (`lidarr_develop`), fully
  isolated from the stable and nightly variants.
- Do **not** update Lidarr from inside its own UI: with Docker-based installs,
  updates are delivered through new add-on versions.
- `develop` builds can contain breaking changes or database migrations that
  cannot be downgraded. Back up before updating.

## Side-by-side variants

`lidarr`, `lidarr_develop` and `lidarr_nightly` can be installed together:

- separate configurations (no shared database);
- use distinct music root folders per variant;
- only **one** variant at a time may expose host port `8686` (Ingress always works).

## Ingress

Lidarr Develop is accessible through Home Assistant's Ingress feature. The
`ingress_port` is set to `8686`.

## Port mapping

Map port `8686/tcp` for direct access (required for other *arr apps or download
clients running outside Home Assistant). Home Assistant Ingress remains
recommended for browser access.

## Available directories

| Path | Description |
| ---- | ----------- |
| `/config` | Lidarr configuration and database (private `lidarr_develop` storage) |
| `/share` | Shared data (`/share/music` and `/share/downloads` created on first start) |
| `/media` | Media shared with Home Assistant |
| `/backup` | Home Assistant backups |
