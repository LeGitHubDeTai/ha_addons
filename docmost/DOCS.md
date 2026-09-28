# Docmost - Home Assistant Add-on

Docmost is an open-source alternative to Confluence and Notion. It is a self-hosted documentation and wiki tool.

## Configuration

Add-on configuration:

| Option | Description | Default |
|---|---|---|
| `timezone` | Timezone for the application | `Europe/Berlin` |
| `app_secret` | Secret key for the application (auto-generated if empty) | (auto-generated) |
| `DATABASE.db_host` | PostgreSQL host. `localhost` uses the bundled database, anything else an external one | `localhost` |
| `DATABASE.db_port` | PostgreSQL port | `5432` |
| `DATABASE.db_name` | Database name | `docmost` |
| `DATABASE.db_user` | Database user | `docmost` |
| `DATABASE.db_password` | Password for the database user | (required) |
| `smtp_host` | SMTP server for sending emails | (optional) |
| `smtp_port` | SMTP port | `587` |
| `smtp_username` | SMTP username | (optional) |
| `smtp_password` | SMTP password | (optional) |
| `smtp_from_address` | Sender email address | (optional) |
| `smtp_from_name` | Sender display name | `Docmost` |

### Database

By default (`db_host: localhost`), the add-on runs its own PostgreSQL instance inside the container
and creates the role/database for you on every start.

Set `db_host` to another host (e.g. a PostgreSQL add-on or a remote server) to use an external
database instead: the bundled instance is then not started, the add-on waits for the remote server
and tries to create the database if it does not exist yet.

> Upgrading from a version that only had `db_password`: re-save your configuration once, the
> password now lives in `DATABASE.db_password`.

## Ports

| Port | Protocol | Description |
|---|---|---|
| 3000 | TCP | Web UI (exposed only via Ingress by default) |

## First Run

After installing and starting the add-on, open the Docmost Web UI through the Home Assistant Ingress. You will be redirected to the setup page to create your workspace and admin account.
