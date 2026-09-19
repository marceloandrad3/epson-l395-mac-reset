#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
command -v git >/dev/null || { echo "git não encontrado."; exit 1; }
command -v python3 >/dev/null || { echo "python3 não encontrado."; exit 1; }
if [ ! -d "$UPSTREAM_DIR" ]; then
  git clone --quiet "$UPSTREAM_URL" "$UPSTREAM_DIR"
fi
git -C "$UPSTREAM_DIR" checkout --quiet "$UPSTREAM_COMMIT"
python3 -m venv "$UPSTREAM_DIR/.venv"
"$PY" -m pip install --quiet -r "$UPSTREAM_DIR/requirements.txt"
"$PY" -c "import pysnmp; print('pysnmp OK')"
"$PY" -c "import tkinter; print('tkinter OK', tkinter.TkVersion)" || \
  echo "Tk ausente: só é necessário para a interface gráfica (ui.py); o modo linha de comando funciona sem ele."
echo "Pronto. Próximo passo: ./scripts/find-printer.sh"
