# Full browser client

This is **not** the earlier reduced BlockNote prototype.

The build wrapper checks out a pinned AppFlowy-Web revision from the same June 2026 compatibility window as the Flutter fork, applies only ZVS-26 branding patches, and builds the full web client.

## Build

```bash
ZVS26_CLOUD_URL=https://your-private-gateway.example \
  bash web-full/build.sh
```

Output:

```
web-full/dist
```

For Cloudflare Pages:

- build command: `bash web-full/build.sh`
- output directory: `web-full/dist`
- build variable: `ZVS26_CLOUD_URL`

The web client uses the same private AppFlowy Cloud gateway as Android and iOS.
