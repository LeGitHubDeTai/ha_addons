# Storybook Home Assistant Add-on

Storybook is a frontend workshop for building, documenting, and testing UI components in isolation.

## Features

- **Component-driven UI**: Build and test UI components in isolation
- **Interactive Docs**: Auto-generated documentation from stories
- **Addons ecosystem**: Rich plugin system for testing, actions, links, and more
- **Web-based**: Accessible through any modern browser via Home Assistant Ingress
- **React + Vite**: Pre-configured React project with Vite builder

## Installation

1. Add this repository to your Home Assistant Supervisor:
   ```
   https://github.com/LeGitHubDeTai/ha_addons
   ```

2. Install the "Storybook" addon from the Home Assistant Supervisor store

3. Start the addon

4. Access Storybook through the Home Assistant sidebar or directly via Ingress

## Configuration

This addon comes with a pre-built Storybook project based on React and Vite. You can add your own stories and components by accessing the addon's file system via SSH or the Home Assistant file editor.

### Default Project Location

The Storybook project is located at `/storybook-project` inside the container. After building, the static files are served from `/usr/share/nginx/html`.

### Port

- **6006**: The default Storybook port, served via Home Assistant Ingress.

## Data Persistence

The following directories are mapped for persistence:
- **share**: Network shares (SMB/NFS)
- **config**: Add-on configuration

## Troubleshooting

### Common Issues

1. **Addon won't start**: Check the addon logs in Home Assistant Supervisor
2. **Can't access via Ingress**: Ensure the addon is running and check Home Assistant network configuration
3. **Build errors**: Check container logs for npm/build errors

### Logs

Access the addon logs through:
- Home Assistant Supervisor > Addons > Storybook > Logs
- Or via the command line: `ha core logs`

## License

This addon follows the same license as the original Storybook project.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or create issues for bugs and feature requests.
