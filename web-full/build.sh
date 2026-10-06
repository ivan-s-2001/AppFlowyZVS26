#!/usr/bin/env bash
set -euo pipefail

: "${ZVS26_CLOUD_URL:?Set ZVS26_CLOUD_URL to the private group gateway URL}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_DIR="$ROOT_DIR/.upstream"
OUTPUT_DIR="$ROOT_DIR/dist"
APPFLOWY_WEB_COMMIT="b615fa5a9fb195e972bbe0df2126d30a853180f7"

rm -rf "$UPSTREAM_DIR" "$OUTPUT_DIR"

git clone --filter=blob:none --no-checkout https://github.com/AppFlowy-IO/AppFlowy-Web.git "$UPSTREAM_DIR"
git -C "$UPSTREAM_DIR" checkout "$APPFLOWY_WEB_COMMIT"

node "$ROOT_DIR/patch.mjs" "$UPSTREAM_DIR"

export APPFLOWY_BASE_URL="$ZVS26_CLOUD_URL"
export APPFLOWY_GOTRUE_BASE_URL="$ZVS26_CLOUD_URL/gotrue"
export APPFLOWY_WS_BASE_URL="$(node -e '
  const u = new URL(process.argv[1]);
  u.protocol = u.protocol === "https:" ? "wss:" : "ws:";
  u.pathname = "/ws/v2";
  u.search = "";
  u.hash = "";
  process.stdout.write(u.toString());
' "$ZVS26_CLOUD_URL")"

cd "$UPSTREAM_DIR"
corepack enable
corepack prepare pnpm@10.9.0 --activate
pnpm install --frozen-lockfile
pnpm build

mkdir -p "$OUTPUT_DIR"
cp -R dist/. "$OUTPUT_DIR/"
cp "$ROOT_DIR/_redirects" "$OUTPUT_DIR/_redirects"
cp "$ROOT_DIR/manifest.webmanifest" "$OUTPUT_DIR/manifest.webmanifest"
cp "$ROOT_DIR/service-worker.js" "$OUTPUT_DIR/service-worker.js"
cp "$ROOT_DIR/zvs26-icon.svg" "$OUTPUT_DIR/zvs26-icon.svg"

echo "Full ZVS-26 web client built in $OUTPUT_DIR"
