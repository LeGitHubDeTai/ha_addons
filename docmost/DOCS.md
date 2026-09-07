# Docmost - Home Assistant Add-on

Docmost is an open-source alternative to Confluence and Notion. It is a self-hosted documentation and wiki tool.

## Configuration

Add-on configuration:

| Option | Description | Default |
|---|---|---|
| `timezone` | Timezone for the application | `Europe/Berlin` |
| `app_secret` | Secret key for the application (auto-generated if empty) | (auto-generated) |
| `db_password` | Password for the PostgreSQL database | (required) |
| `smtp_host` | SMTP server for sending emails | (optional) |
| `smtp_port` | SMTP port | `587` |
| `smtp_username` | SMTP username | (optional) |
| `smtp_password` | SMTP password | (optional) |
| `smtp_from_address` | Sender email address | (optional) |
| `smtp_from_name` | Sender display name | `Docmost` |

## Ports

| Port | Protocol | Description |
|---|---|---|
| 3000 | TCP | Web UI (exposed only via Ingress by default) |

## First Run

After installing and starting the add-on, open the Docmost Web UI through the Home Assistant Ingress. You will be redirected to the setup page to create your workspace and admin account.
