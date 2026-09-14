# Scanopy Home Assistant Addon

Network scanning tool for discovering and analyzing network devices with web interface.

## About

Scanopy is a web-based network scanning tool that allows you to:
- Discover network devices automatically
- Analyze network topology and connections
- Monitor network activity and changes
- Visualize network infrastructure
- Generate network documentation

## Installation

1. Add this repository to your Home Assistant Supervisor:
   ```
   https://github.com/LeGitHubDeTai/ha_addons
   ```

2. Install the "Scanopy" addon from the addon store

3. Configure the addon settings as needed

4. Start the addon

## Configuration

The addon can be configured through the Home Assistant Supervisor UI. Most settings have sensible defaults.

### Options

- **env_vars_list**: List of additional environment variables (advanced users only)

## Network

The addon runs on port 8080 and is accessible through Home Assistant's ingress system for secure access.

## Data Storage

- Scan results are stored in `/data/scans`
- Database files are stored in `/data/db`
- Configuration and logs are stored in the addon data directory

## Development

This addon is based on the official Scanopy project:
https://github.com/scanopy/scanopy

## Version

Current version: 0.14.19
