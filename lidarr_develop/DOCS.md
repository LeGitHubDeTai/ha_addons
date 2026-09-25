# Lidarr Develop Add-on Documentation

## Overview

This add-on provides a **[Lidarr](https://lidarr.audio/) `develop` branch** instance,
based on the **[LinuxServer.io `develop` image](https://docs.linuxserver.io/images/docker-lidarr/)**.

The web UI is exposed **directly** on host port `8687` (no Home Assistant
Ingress), so indexers and download clients can reach it.

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

1. Start the add-on and open it via the **Open Web UI** button
   (`http://[IP_DE_HOME_ASSISTANT]:8687`).
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
- distinct default host ports (`8686` stable, `8687` develop, `8688` nightly),
  changeable in each add-on's **Network** settings.

## Access (no Ingress)

This add-on intentionally does **not** use Home Assistant Ingress. The web UI is
always exposed directly on the local network:

```
http://[IP_DE_HOME_ASSISTANT]:8687
```

## Port mapping

Port `8686/tcp` (container) is mapped to host port `8687` by default so this
variant can run side by side with the stable (`8686`) and nightly (`8688`)
variants.

## Available directories

| Path | Description |
| ---- | ----------- |
| `/config` | Lidarr configuration and database (private `lidarr_develop` storage) |
| `/share` | Shared data (`/share/music` and `/share/downloads` created on first start) |
| `/media` | Media shared with Home Assistant |
| `/backup` | Home Assistant backups |
