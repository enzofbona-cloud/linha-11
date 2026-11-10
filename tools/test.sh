#!/usr/bin/env bash
# Roda todos os testes do projeto (Godot/GUT + Node).
# Uso: GODOT=/caminho/do/godot tools/test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

: "${GODOT:=godot}"

"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

if compgen -G "tools/*.test.mjs" >/dev/null || compgen -G "web/landing/*.test.mjs" >/dev/null; then
	node --test tools/ web/landing/
fi
