#!/usr/bin/env bash
# Instala tudo dentro de $DATA_DIR: uv, Python 3.13, upstream (sem git) e dependências.
# Não mexe no Python do sistema nem nos perfis do shell.
set -euo pipefail
source "$(dirname "$0")/common.sh"
mkdir -p "$DATA_DIR"
export UV_UNMANAGED_INSTALL="$UV_DIR/bin" UV_PYTHON_INSTALL_DIR="$UV_DIR/python" UV_CACHE_DIR="$UV_DIR/cache"
UV="$UV_DIR/bin/uv"
[ -x "$UV" ] || curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
[ -x "$UV" ] || { echo "Falha ao instalar o uv. Verifique a internet."; exit 1; }
if [ ! -f "$UPSTREAM_DIR/epson_print_conf.py" ]; then
  mkdir -p "$UPSTREAM_DIR"
  curl -fsSL "https://github.com/$UPSTREAM_REPO/archive/$UPSTREAM_COMMIT.tar.gz" | tar -xz --strip-components=1 -C "$UPSTREAM_DIR"
fi
"$UV" venv --quiet --python "$PYTHON_VERSION" "$UPSTREAM_DIR/.venv"
"$UV" pip install --quiet --python "$PY" -r "$UPSTREAM_DIR/requirements.txt"
"$PY" -c "import sys, pysnmp; print('Python', sys.version.split()[0], '| pysnmp OK')"
