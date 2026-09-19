#!/usr/bin/env bash
# Variáveis compartilhadas pelos scripts.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_DIR="$ROOT/epson_print_conf"
UPSTREAM_URL="https://github.com/Ircama/epson_print_conf"
# Commit do upstream em que o fluxo foi testado (L395, firmware RY13K3).
UPSTREAM_COMMIT="c93100c"
MODEL="${MODEL:-L395}"
# Endereços da EEPROM alterados pelo reset da L395 (raw_waste_reset do upstream).
ADDRS="${ADDRS:-24,25,30,28,29,46}"
PY="$UPSTREAM_DIR/.venv/bin/python"
run_conf() { "$PY" "$UPSTREAM_DIR/epson_print_conf.py" -m "$MODEL" -a "$PRINTER_IP" "$@"; }
