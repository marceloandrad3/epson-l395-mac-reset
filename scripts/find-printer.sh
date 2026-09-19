#!/usr/bin/env bash
# Descobre nome e IP da impressora Epson na rede (somente leitura).
set -euo pipefail
source "$(dirname "$0")/common.sh"
r="$(discover_epson)" || { echo "Nenhuma Epson encontrada via Bonjour. Veja o IP no painel do roteador."; exit 1; }
echo "Impressora: ${r%%$'\t'*}"
echo "IP:         ${r##*$'\t'}"
