# Storybook Add-on Documentation

## Overview

This add-on provides a self-hosted Storybook instance for building and documenting UI components in isolation, fully integrated with Home Assistant via Ingress.

## Requirements

- Home Assistant Supervisor 2023.12 or later
- Internet access during initial build (to download Storybook dependencies)

## Add-on options

### `env_vars_list`

A list of additional environment variables to pass to the container. Each entry must be in the format `KEY: value`.

Example:
```yaml
options:
  env_vars_list:
    - "NODE_ENV: production"
```

## How to use

### Adding your own stories

1. Access the add-on's file system via SSH or the Home Assistant file editor
2. Navigate to the project directory
3. Add your `.stories.*` files under the `stories/` directory
4. Rebuild the addon to apply changes

### Accessing Storybook

Once started, access Storybook from the Home Assistant sidebar or at the configured ingress URL. The default port is **6006**.

### Supported frameworks

The add-on is pre-configured with **React + Vite**. To use a different framework, modify the project configuration files.

## Ingress

Storybook is accessible through Home Assistant's Ingress feature. The `ingress_port` is set to `6006`.

## Port mapping

If you need to expose Storybook directly, map port `6006/tcp`. However, Home Assistant Ingress is recommended for secure access.

## Backup exclusions

The following paths are excluded from backups:
- `storybook/.cache`
- `storybook/.logs`
- `supervisord.log*`
