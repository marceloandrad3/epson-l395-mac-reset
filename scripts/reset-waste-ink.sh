#!/usr/bin/env bash
# Zera o contador de tinta residual (ESCREVE na EEPROM), depois de salvar backup.
# Uso: ./scripts/reset-waste-ink.sh <IP>
set -euo pipefail
PRINTER_IP="${1:?uso: $0 <IP da impressora>}"
source "$(dirname "$0")/common.sh"

echo "== Status atual =="
run_conf | grep -E "errcode|maintenance_box_1|firmware_version|main_waste"

dir="$BACKUP_DIR/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$dir"
run_conf -R "$ADDRS" | tee "$dir/eeprom_before.txt"
run_conf > "$dir/status_before.txt" 2>&1
echo "Backup salvo em: $dir"

echo
echo "Isto vai ESCREVER na EEPROM da impressora. O reset não limpa as almofadas físicas."
if [ "${ASSUME_YES:-}" != "1" ]; then
  read -r -p "Digite SIM para continuar: " ans
  [ "$ans" = "SIM" ] || { echo "Cancelado."; exit 1; }
fi

run_conf --reset_waste_ink
sleep 3
echo "== Verificação =="
run_conf -R "$ADDRS"
run_conf | grep -E "main_waste"
echo "Se o painel ainda mostrar erro, desligue a impressora, espere 10 s e ligue de novo."
