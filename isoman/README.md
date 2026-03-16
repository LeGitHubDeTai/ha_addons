# Isoman Home Assistant Addon

This addon provides [ISOMan](https://github.com/aloks98/isoman) - a modern, self-hosted Linux ISO download manager with real-time progress tracking and verification - as a Home Assistant addon.

## Features

- **Multiple File Format Support**: Download ISO, QCOW2, VMDK, VDI, IMG, and other disk image formats
- **Organized Storage**: Automatic organization by distribution name, version, and architecture
- **Checksum Verification**: Automatic SHA256/SHA512/MD5 verification during download
- **Real-time Progress**: WebSocket-based live progress updates for all downloads
- **Concurrent Downloads**: Configurable worker pool for parallel downloads
- **Modern UI**: Clean, responsive interface with dark mode support
- **Grid and List Views**: Flexible viewing options with sorting and pagination
- **Apache-style Directory Listing**: Browse and download files directly via HTTP
- **RESTful API**: Full API access for automation and integration

## Installation

1. Add this repository to your Home Assistant Supervisor
2. Install the "Isoman" addon from the store
3. Configure the addon settings
4. Start the addon

## Configuration

### Basic Settings

- **Timezone**: Set your local timezone (default: Europe/Berlin)
- **ISO Storage Path**: Where ISO files will be stored (default: /share/isoman)
- **Max Concurrent Downloads**: Number of simultaneous downloads (default: 3)
- **Log Level**: Logging verbosity (debug, info, warn, error)
- **Log Format**: Log output format (json, text)

### Storage

The addon uses the following Home Assistant mounts:
- **share**: For ISO file storage (recommended)
- **config**: For application configuration
- **media**: Alternative storage location
- **backup**: For backup integration

### Access

- **Web Interface**: Available through Home Assistant Ingress or directly at port 8080
- **API**: RESTful API available at the same endpoint
- **File Downloads**: Direct HTTP access to downloaded files

## Usage

1. Open the Isoman web interface through Home Assistant
2. Add new ISO downloads using the web form
3. Monitor download progress in real-time
4. Access downloaded files through the web interface or direct HTTP links
5. Use the API for automation and integration

## Storage Structure

ISO files are automatically organized as:
```
/share/isoman/
├── ubuntu/
│   ├── 22.04/
│   │   ├── amd64/
│   │   │   └── ubuntu-22.04.3-live-server-amd64.iso
│   │   └── arm64/
│   └── 24.04/
├── debian/
│   └── 12/
└── fedora/
    └── 39/
```

## API Integration

The addon provides a full RESTful API for automation:
- List downloads: `GET /api/downloads`
- Add download: `POST /api/downloads`
- Get status: `GET /api/downloads/{id}`
- Delete download: `DELETE /api/downloads/{id}`

## Environment Variables

The addon supports the following environment variables:

### Core Configuration
- `DATA_DIR`: Directory for ISO storage (default: /share/isoman)
- `PORT`: Server port (default: 8080)
- `WORKER_COUNT`: Number of concurrent downloads (default: 3)

### Logging
- `LOG_LEVEL`: Log level (debug, info, warn, error)
- `LOG_FORMAT`: Log format (json, text)

### Database
- `DB_PATH`: Custom database path (optional)

### CORS
- `CORS_ORIGINS`: Allowed CORS origins

## Troubleshooting

### Common Issues

1. **Storage Permission Issues**: Ensure the selected storage path is writable
2. **Network Issues**: Check internet connectivity for ISO downloads
3. **Port Conflicts**: Make sure port 8080 is not in use
4. **Binary Not Found**: Check the addon logs for download errors

### Logs

Check the addon logs for troubleshooting:
- Isoman application logs: `/var/log/supervisor/isoman.out.log`
- Error logs: `/var/log/supervisor/isoman.err.log`
- Supervisor logs: `/var/log/supervisor/supervisord.log`

## Development

This addon follows Home Assistant addon conventions:

### File Structure
```
isoman/
├── config.yaml          # Addon configuration
├── Dockerfile           # Container build definition
├── build.yaml           # Build configuration
├── supervisord.conf     # Process management
├── isoman-entrypoint.sh # Startup script
└── README.md           # Documentation
```

### Build Process

1. Downloads official Isoman binary from GitHub releases
2. Installs dependencies (curl, supervisor, etc.)
3. Configures environment variables
4. Sets up process supervision

## Support

For issues related to:
- **Addon functionality**: Check this repository's issues
- **ISOMan features**: Check the [upstream project](https://github.com/aloks98/isoman)

## License

This addon follows the same license as the upstream ISOMan project.
