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
- `SMTP_ADDRESS`: SMTP server address (empty = built-in local Mailpit)
- `SMTP_PORT`: SMTP server port (default: 1025 local, 587 if a server is set)
- `SMTP_USERNAME`: SMTP username
- `SMTP_PASSWORD`: SMTP password
- `SMTP_TLS`: Enable TLS for SMTP (default: false)
- `VAPID_PRIVATE_KEY`: VAPID private key for web push
- `VAPID_PUBLIC_KEY`: VAPID public key for web push

## Usage

1. Start the addon
2. Access Fizzy via the WebUI link, or directly inside Home Assistant
   (sidebar/panel) thanks to Ingress — no port to open
3. Create your account on first access
4. Start creating boards and cards

> Note: Ingress is best-effort (same convention as the other addons in this
> repo). If something looks off inside the HA panel (assets, redirects), use
> the direct port access (`8095` by default) for the full experience.

## Email without configuration (Mailpit)

No SMTP setup needed to get started: the addon runs a built-in local mail
server (Mailpit). Account verification codes land in the local mailbox,
available on port **8097**.

As soon as you fill in `SMTP_ADDRESS` (real provider), it takes over and the
local mailbox is bypassed (Mailpit keeps running but receives nothing).

## Documentation

For more information, see:
- [Fizzy Official Documentation](https://github.com/basecamp/fizzy)
- [Docker Deployment Guide](https://github.com/basecamp/fizzy/blob/main/docs/docker-deployment.md)

## Support

If you encounter issues, please report them on [GitHub Issues](https://github.com/LeGitHubDeTai/ha_addons/issues)