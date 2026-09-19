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

# Descobre "nome<TAB>ip" da primeira Epson na rede via Bonjour (somente leitura).
discover_epson() {
  local out name host ip pid
  out="$(mktemp)"
  dns-sd -B _pdl-datastream._tcp local >"$out" 2>&1 & pid=$!
  sleep 4; kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
  name="$(sed -n 's/.*_pdl-datastream\._tcp\. *//p' "$out" | grep -i epson | head -1 | sed 's/[[:space:]]*$//')"
  [ -n "$name" ] || { rm -f "$out"; return 1; }
  dns-sd -L "$name" _pdl-datastream._tcp local >"$out" 2>&1 & pid=$!
  sleep 4; kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
  host="$(sed -n 's/.*can be reached at \([^:]*\):.*/\1/p' "$out" | head -1)"
  rm -f "$out"
  [ -n "$host" ] || return 1
  ip="$(dscacheutil -q host -a name "${host%.}" | sed -n 's/^ip_address: //p' | head -1)"
  [ -n "$ip" ] || return 1
  printf '%s\t%s\n' "$name" "$ip"
}
