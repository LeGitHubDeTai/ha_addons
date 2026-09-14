# Portainer Add-on

Manage Docker environments through a web interface.

## Installation

1. Go to **Add-ons** in Home Assistant
2. Click the three dots (⋮) → **Add add-on from URL**
3. Add the repository URL: `https://github.com/legithubdetai/ha_addons`
4. Search for **Portainer** and click **Install**

## Configuration

The add-on provides the following options:

| Option | Description | Default |
|--------|-------------|---------|
| `timezone` | Set the timezone for the container | `Europe/Berlin` |
| `env_vars_list` | Additional environment variables (format: `KEY: value`) | `[]` |
| `cmd_line_args` | Command-line arguments to pass to Portainer | `""` |

### Ports

- **9000/tcp** - Portainer web interface UI

### Volumes

- **config** - Configuration data persistence

## Usage

Access Portainer at `http://<home-assistant-ip>:9000` after the add-on starts.

You will be prompted to create a default administrator account and add Docker endpoints.

## Support

If you encounter issues, check the add-on logs or visit the [GitHub repository](https://github.com/legithubdetai/ha_addons).