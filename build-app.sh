#!/usr/bin/env bash
# Monta dist/Zerar-Epson-L395.zip com o app "Zerar Epson L395.app".
set -euo pipefail
cd "$(dirname "$0")"
APP="dist/Zerar Epson L395.app"
rm -rf dist && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/scripts"
cp app/Info.plist "$APP/Contents/Info.plist"
cp app/launcher.sh "$APP/Contents/MacOS/launcher"
cp scripts/common.sh scripts/setup.sh scripts/reset-waste-ink.sh scripts/status.sh "$APP/Contents/Resources/scripts/"
chmod +x "$APP/Contents/MacOS/launcher" "$APP"/Contents/Resources/scripts/*.sh
codesign --force --deep -s - "$APP" 2>&1 | tail -1
ditto -c -k --sequesterRsrc --keepParent "$APP" dist/Zerar-Epson-L395.zip
echo "Gerado: dist/Zerar-Epson-L395.zip"
