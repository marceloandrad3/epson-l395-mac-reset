#!/usr/bin/env bash
# Tudo em um comando: instala, acha a impressora, mostra o status e (com sua confirmação) zera o contador.
# Uso: ./reset.sh [IP]      (o IP é opcional; sem ele a impressora é procurada sozinha)
set -euo pipefail
cd "$(dirname "$0")"
source scripts/common.sh

echo "==> 1/3 Instalando (só na primeira vez; baixa o Python 3.13 e a ferramenta)"
if [ ! -x "$PY" ]; then ./scripts/setup.sh; else echo "Já instalado."; fi

echo "==> 2/3 Procurando a impressora"
if [ -n "${1:-}" ]; then
  PRINTER_IP="$1"; NAME="(IP informado)"
else
  r="$(discover_epson)" || { echo "Impressora não encontrada. Ligue-a no Wi-Fi e rode: ./reset.sh <IP>"; exit 1; }
  NAME="${r%%$'\t'*}"; PRINTER_IP="${r##*$'\t'}"
fi
echo "Impressora: $NAME  IP: $PRINTER_IP"
case "$NAME" in *L395*|"(IP informado)") ;; *) echo "AVISO: só a L395 foi testada; o reset abaixo usa os endereços dela." ;; esac

echo "==> 3/3 Lendo o contador (somente leitura)"
if ! run_conf | grep -q main_waste; then
  echo "A impressora não devolveu o contador. O firmware pode ter bloqueado o SNMP; NÃO adianta continuar."
  exit 1
fi
exec ./scripts/reset-waste-ink.sh "$PRINTER_IP"
