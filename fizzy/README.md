# Fizzy Home Assistant Addon

Kanban tracking tool for issues and ideas by 37signals (Fizzy)

## About

Fizzy is a Kanban tracking tool developed by 37signals (the company behind Basecamp and HEY). It provides a simple, elegant way to track issues, ideas, and tasks using a Kanban board interface.

## Features

- Clean, minimal Kanban board interface
- Real-time updates
- Email notifications
- Web push notifications
- Multi-user support
- Self-hosted with Docker

## Installation

1. Add this repository to Home Assistant
2. Navigate to Settings → Add-ons → Add-on Store
3. Search for "Fizzy"
4. Click on "Install"

## Configuration

### Required Options

- `SECRET_KEY_BASE`: Secret key for cryptography (auto-generated if empty)

### Optional Options

- `TLS_DOMAIN`: Domain for SSL (e.g., `fizzy.example.com`)
- `BASE_URL`: Full URL where Fizzy is accessible
- `MAILER_FROM_ADDRESS`: Email address for sending emails
- `SMTP_ADDRESS`: SMTP server address
- `SMTP_PORT`: SMTP server port (default: 587)
- `SMTP_USERNAME`: SMTP username
- `SMTP_PASSWORD`: SMTP password
- `SMTP_TLS`: Enable TLS for SMTP (default: false)
- `VAPID_PRIVATE_KEY`: VAPID private key for web push
- `VAPID_PUBLIC_KEY`: VAPID public key for web push

## Usage

1. Start the addon
2. Access Fizzy via the WebUI link
3. Create your account on first access
4. Start creating boards and cards

## Documentation

For more information, see:
- [Fizzy Official Documentation](https://github.com/basecamp/fizzy)
- [Docker Deployment Guide](https://github.com/basecamp/fizzy/blob/main/docs/docker-deployment.md)

## Support

If you encounter issues, please report them on [GitHub Issues](https://github.com/LeGitHubDeTai/ha_addons/issues)