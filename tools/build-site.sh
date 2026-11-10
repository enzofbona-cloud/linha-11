#!/usr/bin/env bash
# Compila o canal indicado e monta o site completo em build/site/ para teste local.
# Uso: GODOT=/caminho/do/godot tools/build-site.sh [dev|stable]
set -euo pipefail
cd "$(dirname "$0")/.."

: "${GODOT:=godot}"
CHANNEL="${1:-dev}"
COMMIT="$(git rev-parse HEAD)"

rm -rf build/web build/site
mkdir -p build/web

node tools/write-build-info.mjs --channel "$CHANNEL" --commit "$COMMIT" \
	--out build_info.json --out build/web/version.json
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
rm -f build_info.json
node tools/verify-web-build.mjs build/web

mkdir -p "build/site/$CHANNEL"
cp -r web/landing/index.html web/landing/style.css web/landing/app.js build/site/
cp -r build/web/. "build/site/$CHANNEL/"
echo "Site montado em build/site/"
