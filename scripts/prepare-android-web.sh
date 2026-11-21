#!/usr/bin/env bash
set -euo pipefail

VERSION="2.119.2"
DEST="www/vendor/supabase-${VERSION}.js"
TMP_A="$(mktemp)"
TMP_B="$(mktemp)"
trap 'rm -f "$TMP_A" "$TMP_B"' EXIT

mkdir -p www/vendor
curl --fail --silent --show-error --location --retry 3 \
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@${VERSION}/dist/umd/supabase.js" \
  --output "$TMP_A"
curl --fail --silent --show-error --location --retry 3 \
  "https://unpkg.com/@supabase/supabase-js@${VERSION}/dist/umd/supabase.js" \
  --output "$TMP_B"

if ! cmp -s "$TMP_A" "$TMP_B"; then
  echo "Pinned Supabase UMD mirrors differ; refusing to package an unverified SDK bundle." >&2
  exit 1
fi

install -m 0644 "$TMP_A" "$DEST"
python3 - <<'PY'
from pathlib import Path
p = Path("www/index.html")
html = p.read_text()
old = 'https://gfoaubfilhttnwjykaox.supabase.co/functions/v1/app-assets?asset=supabase'
new = './vendor/supabase-2.119.2.js'
if html.count(old) != 1:
    raise SystemExit("Expected exactly one existing Supabase loader; refusing to rewrite unexpected HTML.")
p.write_text(html.replace(old, new, 1))
PY

sha256sum "$DEST"
echo "Android APK web bundle now uses pinned Supabase JS ${VERSION}; source index.html is unchanged."
