# ZVS-26 Cloudflare gateway

The client needs one AppFlowy base URL. This Worker keeps that contract while allowing the tiny private deployment to use external managed services.

Routes:

- `/gotrue/*` → hosted GoTrue-compatible auth;
- everything else, including `/api/*` and WebSocket upgrades, → the private AppFlowy Cloud origin;
- `/gateway-health` → Worker health.

The Supabase anon key is injected only on the GoTrue route. User bearer tokens are preserved.

## Configuration

Set runtime values in Cloudflare, not Git:

- `CLOUD_ORIGIN`
- `GOTRUE_ORIGIN`
- `SUPABASE_ANON_KEY`

Then build mobile clients with the resulting Worker URL as `ZVS26_CLOUD_URL`.
