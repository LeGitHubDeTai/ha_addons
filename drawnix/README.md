# Drawnix Home Assistant Addon

Drawnix is an open source whiteboard tool (SaaS) with integrated whiteboard functionality, including mind maps, flowcharts, and free drawing capabilities.

## Features

- **Integrated Whiteboard**: Complete whiteboard solution for visual collaboration
- **Mind Maps**: Create and edit mind mapping diagrams
- **Flowcharts**: Build professional flowcharts and diagrams
- **Free Drawing**: Express ideas with freehand drawing tools
- **Web-based**: Accessible through any modern web browser
- **Home Assistant Integration**: Seamlessly integrated with Home Assistant via Ingress

## Installation

1. Add this repository to your Home Assistant Supervisor:
   ```
   https://github.com/LeGitHubDeTai/ha_addons
   ```

2. Install the "Drawnix" addon from the Home Assistant Supervisor store

3. Configure the addon:
   - Set your preferred timezone
   - Add any custom environment variables if needed

4. Start the addon

5. Access Drawnix through the Home Assistant sidebar or directly via the Ingress URL

## Configuration

### Basic Configuration

- **Timezone**: Set to your local timezone (default: Europe/Berlin)
- **Environment Variables**: Add custom environment variables if required by Drawnix

### Advanced Configuration

The addon supports the following advanced options:

- **Port**: 3000 (internal, accessible via Home Assistant Ingress)
- **Architecture**: Supports armhf, armv7, aarch64, amd64, i386
- **Storage**: Persistent configuration and data storage

## Usage

Once installed and started:

1. Access Drawnix through the Home Assistant sidebar
2. Create new whiteboards or import existing ones
3. Use the integrated tools for mind mapping, flowcharts, and free drawing
4. Save your work automatically

## Data Persistence

Your Drawnix data is automatically persisted in the addon's data directory:
- Whiteboards and drawings
- Configuration settings
- User preferences

## Troubleshooting

### Common Issues

1. **Addon won't start**: Check the addon logs in Home Assistant Supervisor
2. **Can't access via Ingress**: Ensure the addon is running and check Home Assistant network configuration
3. **Data not saving**: Verify that the addon has proper permissions for the data directory

### Logs

Access the addon logs through:
- Home Assistant Supervisor > Addons > Drawnix > Logs
- Or via the command line: `ha core logs`

## Development

This addon is based on the official Drawnix Docker image:
- Docker Hub: [pubuzhixing/drawnix](https://hub.docker.com/r/pubuzhixing/drawnix)
- Version: v0.3.0

## Support

For issues related to:
- **Addon installation/configuration**: Create an issue in this repository
- **Drawnix functionality**: Check the [official Drawnix documentation](https://hub.docker.com/r/pubuzhixing/drawnix)

## License

This addon follows the same license as the original Drawnix project.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or create issues for bugs and feature requests.
