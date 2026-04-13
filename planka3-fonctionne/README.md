# Planka Home Assistant Add-on

## Description

Planka is an open-source kanban board for project management and collaboration. This add-on provides an easy way to deploy Planka within Home Assistant.

## Features

- **Kanban Boards**: Create and manage kanban boards for projects
- **Real-time Collaboration**: Work together with your team in real-time
- **File Attachments**: Upload and manage files within cards
- **User Management**: Admin and user role management
- **Home Assistant Integration**: Seamless integration through Home Assistant Ingress

## Installation

1. Add this repository to your Home Assistant Supervisor
2. Install the Planka add-on
3. Configure the add-on settings
4. Start the add-on

## Configuration

### Database Configuration

The add-on requires a PostgreSQL database. You can either:

1. Use the official PostgreSQL add-on
2. Use an external PostgreSQL instance

### Required Settings

- **Database Host**: PostgreSQL server hostname
- **Database Port**: PostgreSQL server port (default: 5432)
- **Database User**: PostgreSQL username
- **Database Password**: PostgreSQL password
- **Database Name**: PostgreSQL database name

### Admin Account

- **Admin Email**: Administrator email address
- **Admin Password**: Administrator password
- **Admin Name**: Administrator display name

### Optional Settings

- **Base URL**: Base URL for the application (default: /)
- **Secret Key**: Secret key for session management (auto-generated if not provided)

## Usage

1. Access Planka through Home Assistant Ingress or directly on port 1337
2. Log in with the admin credentials configured in the add-on
3. Create your first project and kanban board
4. Invite team members and start collaborating

## Data Persistence

The following data is persisted:

- User avatars: `/data/user-avatars`
- Project background images: `/data/project-background-images`
- File attachments: `/data/attachments`

## Security Considerations

- Use strong passwords for the database and admin accounts
- Consider using Home Assistant Ingress instead of exposing the port directly
- Regularly update the add-on to receive security patches
- Back up your PostgreSQL database regularly

## Troubleshooting

### Common Issues

1. **Database Connection Failed**: Verify database credentials and network connectivity
2. **Application Won't Start**: Check the add-on logs for error messages
3. **Cannot Access Web UI**: Ensure the port is not blocked by firewall

### Logs

Access the add-on logs through Home Assistant Supervisor to troubleshoot issues.

## Support

For issues related to:
- **Add-on Installation**: Report issues in this repository
- **Planka Functionality**: Report issues at [plankanban/planka](https://github.com/plankanban/planka)

## Version

This add-on uses Planka version 2.1.0.

## License

This add-on is released under the MIT License. Planka itself is released under the AGPL-3.0 License.
