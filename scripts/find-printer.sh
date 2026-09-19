#!/usr/bin/env bash
# Descobre o IP da impressora via Bonjour (somente leitura).
# Uso: ./scripts/find-printer.sh ["EPSON L395 Series"]
set -euo pipefail
NAME="${1:-EPSON L395 Series}"
out="$(mktemp)"
dns-sd -L "$NAME" _pdl-datastream._tcp local >"$out" 2>&1 &
pid=$!; sleep 4; kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
host="$(sed -n 's/.*can be reached at \([^:]*\):.*/\1/p' "$out" | head -1)"
rm -f "$out"
[ -n "$host" ] || { echo "Impressora '$NAME' não encontrada via Bonjour. Veja o IP no painel do roteador."; exit 1; }
ip="$(dscacheutil -q host -a name "${host%.}" | sed -n 's/^ip_address: //p' | head -1)"
echo "host: ${host%.}"
echo "IP:   ${ip:-não resolvido}"
