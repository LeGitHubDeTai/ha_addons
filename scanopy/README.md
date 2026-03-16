# Scanopy Home Assistant Add-on

Network documentation that updates itself - Automatic network discovery and visualization for Home Assistant.

## Description

Scanopy is a powerful network discovery and documentation tool that automatically scans your network to identify hosts, services, and their relationships. This Home Assistant add-on makes it easy to deploy Scanopy alongside your existing Home Assistant installation.

## Features

- **Automatic Discovery**: Scans networks to identify hosts, services, and their relationships
- **200+ Service Definitions**: Auto-detects databases, web servers, containers, network infrastructure, monitoring tools, and enterprise applications
- **Interactive Topology**: Generates visual network diagrams with extensive customization options
- **Docker Integration**: Discovers containerized services automatically
- **Scheduled Discovery**: Automated scanning to keep documentation current
- **Multi-user Support**: Organization management with role-based permissions

## Installation

1. Add this repository to Home Assistant Supervisor:
   ```
   https://github.com/LeGitHubDeTai/ha_addons
   ```

2. Install the "Scanopy" add-on from the add-on store

3. Configure the add-on settings as needed

4. Start the add-on

## Configuration

### Basic Configuration

- **Log Level**: Set the logging verbosity (info, debug, warn, error)
- **PostgreSQL Password**: Database password for the internal PostgreSQL instance
- **Public URL**: The URL where Scanopy will be accessible
- **Enable Docker Discovery**: Whether to scan for Docker containers
- **Scan Intervals**: Configure how often scans run

### Advanced Configuration

The add-on includes the following services:
- PostgreSQL database (port 5432, internal)
- Scanopy Daemon (port 60073, internal)
- Scanopy Server (port 60072, exposed)
- Nginx reverse proxy

### Network Access

The add-on exposes the following ports:
- **60072/tcp**: Main Scanopy web interface and API
- **60073/tcp**: Scanopy daemon API and health checks

### Data Persistence

All data is stored in the add-on's data directory:
- PostgreSQL data: `/data/scanopy/postgres_data`
- Daemon configuration: `/data/scanopy/daemon_config`
- Static files: `/data/scanopy/static`

## Usage

1. Once the add-on is running, access Scanopy via:
   - Home Assistant Ingress (recommended)
   - Direct URL: `http://your-home-assistant:60072`

2. Create your Scanopy account when first accessing the web interface

3. Wait for the initial network discovery to complete (usually takes a few minutes)

4. Explore your network topology and discovered services

## Integration with Home Assistant

This add-on provides:
- **Ingress Support**: Access through Home Assistant's secure proxy
- **Home Assistant API Integration**: Can interact with Home Assistant services
- **Backup Integration**: Automatically included in Home Assistant backups (excluding cache and logs)

## Troubleshooting

### Common Issues

1. **Add-on won't start**: Check the logs for PostgreSQL initialization errors
2. **No devices discovered**: Ensure the add-on has network access and proper permissions
3. **Docker discovery not working**: Verify Docker socket is accessible and discovery is enabled

### Logs

Check the add-on logs in Home Assistant Supervisor for detailed information about:
- PostgreSQL database status
- Scanopy daemon operations
- Scanopy server operations
- Nginx proxy status

## Support

- **Scanopy Documentation**: https://scanopy.net/docs
- **Scanopy Community**: https://discord.gg/b7ffQr8AcZ
- **GitHub Issues**: https://github.com/scanopy/scanopy/issues
- **Home Assistant Add-on Issues**: https://github.com/LeGitHubDeTai/ha_addons/issues

## License

This add-on is based on Scanopy, which is licensed under AGPL-3.0. Please refer to the Scanopy repository for licensing details.

## Contributing

Contributions to this Home Assistant add-on are welcome! Please submit pull requests to the repository.
