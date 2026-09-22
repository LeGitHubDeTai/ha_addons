# Mindwtr Add-on

Self-hosted mind mapping and task management with cloud sync and REST API.

## Installation

1. Go to **Add-ons** in Home Assistant
2. Click the three dots (⋮) → **Add add-on from URL**
3. Add the repository URL: `https://github.com/LeGitHubDeTai/ha_addons`
4. Search for **Mindwtr** and click **Install**

## Configuration

The add-on provides the following options:

| Option | Description | Default |
|--------|-------------|---------|
| `timezone` | Set the timezone for the container | `Europe/Berlin` |
| `mindwtr_cloud_auth_tokens` | Auth token(s) for the cloud server (comma-separated) | `""` |
| `mindwtr_cloud_cors_origin` | CORS origin for the cloud server | `""` |
| `env_vars_list` | Additional environment variables (format: `KEY: value`) | `[]` |
| `cmd_line_args` | Command-line arguments to pass to Mindwtr | `""` |

### Setting the auth token

The easiest way to set the auth token is through the `mindwtr_cloud_auth_tokens` option in the add-on configuration, or through `env_vars_list`:

```yaml
env_vars_list:
  - "MINDWTR_CLOUD_AUTH_TOKENS: your_long_random_token"
  - "MINDWTR_CLOUD_CORS_ORIGIN: http://<home-assistant-ip>:8080"
```

Or use the dedicated option:

```yaml
mindwtr_cloud_auth_tokens: "your_long_random_token"
mindwtr_cloud_cors_origin: "http://<home-assistant-ip>:8080"
```

Multiple tokens are supported, comma-separated. Each distinct token gets its own private dataset.

### Data persistence

The `share` volume is mapped for data persistence. Set `MINDWTR_CLOUD_DATA_DIR=/share` through `env_vars_list` to store cloud data on the share volume.

### Ports

- **8080/tcp** - Mindwtr web interface (PWA + API proxy)
- **8787/tcp** - Mindwtr Cloud sync server API (normally not exposed)

### Volumes

- **config** - Configuration data persistence
- **share** - Shared data directory for cloud data

## Usage

Access Mindwtr at `http://<home-assistant-ip>:8080` after the add-on starts.

The Cloud sync server is available at `http://<home-assistant-ip>:8787`.

- **Self-Hosted URL**: `http://<home-assistant-ip>:8787`
- **REST API base URL**: `http://<home-assistant-ip>:8787/v1`

In Mindwtr Settings -> Sync -> Self-Hosted, use:
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
