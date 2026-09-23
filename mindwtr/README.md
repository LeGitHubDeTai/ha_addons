# Mindwtr Add-on

Self-hosted mind mapping and task management with cloud sync and REST API.

## Installation

1. Go to **Add-ons** in Home Assistant
2. Click the three dots (⋮) → **Add add-on from URL**
3. Add the repository URL: `https://github.com/LeGitHubDeTai/ha_addons`
4. Search for **Mindwtr** and click **Install**

## Configuration

### Quick Sync Setup

1. Generate a token (at least 20 characters):
   ```bash
   cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1
   ```
2. Set the sync token and CORS origin in the add-on options:

```yaml
timezone: "Europe/Paris"
mindwtr_cloud_auth_tokens: "your_long_random_token_here"
mindwtr_cloud_cors_origin: "http://homeassistant.local:8080"
```

3. Restart the add-on and access Mindwtr at `http://<home-assistant-ip>:8080`
4. In Mindwtr Settings → Sync → Self-Hosted, use: `http://<home-assistant-ip>:8787`

### All Options

| Option | Description | Default |
|--------|-------------|---------|
| `timezone` | Container timezone | `Europe/Paris` |
| `mindwtr_cloud_auth_tokens` | Sync token(s), comma-separated (20+ chars) | `""` |
| `mindwtr_cloud_cors_origin` | CORS origin for the cloud server | `""` |
| `mindwtr_cloud_max_body_bytes` | Max request body size (bytes) | `2000000` |
| `mindwtr_cloud_max_attachment_bytes` | Max attachment size (bytes) | `50000000` |
| `mindwtr_default_cloud_url` | Preseed cloud URL for new browsers | `""` |
| `mindwtr_cloud_data_dir` | Data directory path | `"/app/cloud_data"` |
| `env_vars_list` | Additional env vars (format: `KEY: value`) | `[]` |

### Setting Sync Variables

The easiest way to configure Mindwtr sync variables is through `env_vars_list`:

```yaml
env_vars_list:
  - "MINDWTR_CLOUD_AUTH_TOKENS: your_token_here"
  - "MINDWTR_CLOUD_CORS_ORIGIN: http://homeassistant.local:8080"
  - "MINDWTR_CLOUD_MAX_BODY_BYTES: 2000000"
  - "MINDWTR_CLOUD_MAX_ATTACHMENT_BYTES: 50000000"
  - "MINDWTR_DEFAULT_CLOUD_URL: http://homeassistant.local:8787"
```

### Multiple Users / Tokens

Multiple tokens are supported, comma-separated. Each distinct token gets its own private dataset:

```yaml
mindwtr_cloud_auth_tokens: "alices-long-token,bobs-long-token"
```

Or via `env_vars_list`:
```yaml
env_vars_list:
  - "MINDWTR_CLOUD_AUTH_TOKENS: alices-long-token,bobs-long-token"
```

### Sync Methods

#### Self-Hosted Cloud (Recommended)
The bundled Mindwtr Cloud server provides full sync and REST API support. Point Mindwtr Settings → Sync → Self-Hosted at `http://<home-assistant-ip>:8787`.

#### WebDAV Sync
Mindwtr Cloud supports WebDAV sync as an alternative. Configure your Mindwtr client to connect to the WebDAV endpoint at `http://<home-assistant-ip>:8787/webdav` using your auth token.

#### Dropbox Sync
**Not available in Docker.** Native Dropbox OAuth sync is implemented by the native desktop and mobile apps only. Supplying `VITE_DROPBOX_APP_KEY` or `DROPBOX_APP_KEY` will not enable Dropbox in the Docker runtime. Use the self-hosted cloud server or WebDAV instead.

### Ports

- **8080/tcp** - Mindwtr web interface (PWA + API proxy)
- **8787/tcp** - Mindwtr Cloud sync server API (normally not exposed)

### Volumes

- **config** - Configuration data persistence
- **share** - Shared data directory for cloud data

## Usage

Access Mindwtr at `http://<home-assistant-ip>:8080` after the add-on starts.

The Cloud sync server is available at `http://<home-assistant-ip>:8787`.

In Mindwtr Settings → Sync → Self-Hosted, use:
```
http://<home-assistant-ip>:8787
```

Mindwtr will automatically append `/v1/data`.

## API

Create a task:
```bash
curl -X POST \
  -H "Authorization: Bearer your_token_here" \
  -H "Content-Type: application/json" \
  -d '{"input":"Review task"}' \
  http://<home-assistant-ip>:8787/v1/tasks
```

List tasks:
```bash
curl -H "Authorization: Bearer your_token_here" \
  "http://<home-assistant-ip>:8787/v1/tasks?status=next"
```

## Support

If you encounter issues, check the add-on logs or visit the [GitHub repository](https://github.com/LeGitHubDeTai/ha_addons).
