# ISOMan Home Assistant Addon

ISO management tool for downloading and managing ISO images with web interface.

## About

ISOMan is a web-based ISO image management tool that allows you to:
- Download ISO images from various sources
- Manage and organize your ISO collection
- Browse and search through available ISOs
- Monitor download progress

## Installation

1. Add this repository to your Home Assistant Supervisor
2. Install the ISOMan addon from the store
3. Configure the addon as needed
4. Start the addon

## Configuration

The addon can be configured through the Home Assistant Supervisor UI. Most settings have sensible defaults.

### Options

- **env_vars_list**: List of additional environment variables (advanced users only)

## Network

The addon runs on port 8080 and is accessible through Home Assistant's ingress system for secure access.

## Data Storage

- ISO files are stored in `/data/isos`
- Database files are stored in `/data/db`
- Configuration and logs are stored in the addon data directory

## Development

This addon is based on the official ISOMan project:
https://github.com/aloks98/isoman

## Version

Current version: 0.3.3
