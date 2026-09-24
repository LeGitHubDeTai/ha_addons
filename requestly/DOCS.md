# Requestly Add-on Documentation

## Overview

This add-on provides a self-hosted **Requestly** web UI (open-source HTTP interceptor & API mocking tool from [requestly/interceptor](https://github.com/requestly/interceptor)), integrated with Home Assistant via Ingress.

Use it to intercept, modify and mock HTTP(S) traffic during frontend development, QA and debugging.

## Requirements

- Home Assistant Supervisor 2023.12 or later
- Internet access at build time (to fetch Requestly sources and npm dependencies)

## Add-on options

### `env_vars_list`

A list of additional environment variables to pass to the container. Each entry must be in the format `KEY: value`.

Example:

```yaml
options:
  env_vars_list:
    - "NODE_ENV: production"
```

Most users can leave this empty.

## How to use

1. Start the add-on and open it (sidebar via Ingress, or port `3000` if exposed).
2. Install the **Requestly** browser extension (Chrome / Edge / Firefox).
3. Create rules: Redirect URL, Modify Headers, Mock API responses, Inject Scripts, etc.
4. For system-wide capture (mobile apps, desktop apps), use the separate [Requestly Desktop App](https://github.com/requestly/http-interceptor-desktop-app) and point it at your mocks.

### Notes

- The web UI is served as static files via nginx (`try_files ... /index.html`, health endpoint at `/health`).
- The upstream app defaults to Requestly cloud services (Firebase) for sync; local rules work without an account. Check [docs](https://docs.requestly.com/general/http-interceptor/overview) for details.
- Mock Server backend (`@requestly/mock-server`) is a separate npm package and is **not** bundled in this first version — local mocks in the UI cover most use cases.

## Ingress

Requestly is accessible through Home Assistant's Ingress feature. The `ingress_port` is set to `3000`.

## Port mapping

If you need to expose Requestly directly, map port `3000/tcp`. However, Home Assistant Ingress is recommended for secure access.

## Backup exclusions

Static-asset add-on: no persistent data. Nothing specific to exclude.
