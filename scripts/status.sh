#!/usr/bin/env bash
# Lê o status e o contador de resíduo (somente leitura).
# Uso: ./scripts/status.sh <IP>
set -euo pipefail
PRINTER_IP="${1:?uso: $0 <IP da impressora>}"
source "$(dirname "$0")/common.sh"
run_conf | grep -E "errcode|maintenance_box|firmware_version|main_waste|'ready'|'status'"
