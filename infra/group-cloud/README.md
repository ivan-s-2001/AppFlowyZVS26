# Private group cloud

This directory is for the **single private ЗВС-26 workspace**.

It is not a university-wide service.

## Why this is separate from the client

The Flutter application is local-first, but five people need one collaboration endpoint. The client accepts that endpoint at build time:

```bash
flutter build apk --dart-define=ZVS26_CLOUD_URL=https://...
```

Without the value the fork deliberately starts in local mode and never falls back to public AppFlowy Cloud.

## Lean layout

The small compute instance runs only the pinned AppFlowy Cloud core.

External free services provide:

- PostgreSQL + GoTrue-compatible auth + S3-compatible storage;
- Redis;
- Cloudflare Worker gateway and TLS;
- Cloudflare Pages for the eventual full browser client.

AI, semantic search and other heavyweight services are intentionally disabled.

## Version pin

The current Flutter fork comes from AppFlowy 0.11.4 and its upstream mobile CI is paired with AppFlowy Cloud `0.6.54-amd64`. The Dockerfile therefore pins that cloud image instead of using `latest`.

Do not upgrade the server independently of Android/iOS/web compatibility tests.

## Secrets

No database password, JWT secret, Redis credential or S3 key belongs in Git.

`render.yaml` uses `sync: false` for every secret. The example env file contains placeholders only.
