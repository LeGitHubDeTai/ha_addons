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
- Upstream `app/index.html` contains a guard that redirects any non-allowlisted hostname to `https://app.requestly.io` (only `localhost`, bare IPs and `*.requestly.io` pass). The add-on build **disables this redirect** so it works behind Home Assistant (Ingress, `homeassistant.local`, DuckDNS, …) — and fails the build if upstream changes the pattern.
- The upstream app defaults to Requestly cloud services (Firebase) for sync; local rules work without an account. Check [docs](https://docs.requestly.com/general/http-interceptor/overview) for details.
- Mock Server backend (`@requestly/mock-server`) is a separate npm package and is **not** bundled in this first version — local mocks in the UI cover most use cases.

## Ingress

Requestly is accessible through Home Assistant's Ingress feature. The `ingress_port` is set to `3000`.

Home Assistant forwards the full URL including `/api/hassio_ingress/<token>/` to nginx (the prefix is **not** stripped). `nginx.conf` removes it before location/cache lookup (`rewrite ^/api/hassio_ingress/[^/]+(.*)$ $1 last`) and rewrites absolute asset URLs (`/assets/…`, `/favicon.png`, `/manifest.json`) in responses with the prefix from the `X-Ingress-Path` header; without that the browser requests `/assets/…` from Home Assistant itself (404, CSS refused as `text/plain`, app stuck on loading screen).

`patch-ingress.py` runs during the image build and makes react-router use the ingress prefix as `basename`, otherwise no route matches and the page stays blank.

Both adaptations are no-ops for direct access on port `3000` (the header is absent).

Known limitation: a handful of plain absolute links/CTAs inside the upstream UI (`<a href="/">` on the Selenium importer page, “Use now” on the pricing table, `/sessions/draft/mock/` links) are not router-managed and therefore leave the Ingress path. All in-app navigation uses the router and is unaffected.

## Port mapping

If you need to expose Requestly directly, map port `3000/tcp`. However, Home Assistant Ingress is recommended for secure access.

## Backup exclusions

Static-asset add-on: no persistent data. Nothing specific to exclude.
