#!/usr/bin/env bash
# Tudo em um comando: instala, acha a impressora, mostra o status e (com sua confirmação) zera o contador.
# Uso: ./reset.sh [IP]      (o IP é opcional; sem ele a impressora é procurada sozinha)
set -euo pipefail
cd "$(dirname "$0")"
source scripts/common.sh

echo "==> 1/4 Verificando ferramentas do macOS"
if ! xcode-select -p >/dev/null 2>&1 || ! command -v git >/dev/null || ! command -v python3 >/dev/null; then
  echo "Faltam git/python3. Rode: xcode-select --install"
  echo "Espere a instalação terminar e rode ./reset.sh de novo."
  exit 1
fi

echo "==> 2/4 Instalando (só na primeira vez)"
if [ ! -x "$PY" ]; then ./scripts/setup.sh; else echo "Já instalado."; fi

echo "==> 3/4 Procurando a impressora"
if [ -n "${1:-}" ]; then
  PRINTER_IP="$1"; NAME="(IP informado)"
else
  r="$(discover_epson)" || { echo "Impressora não encontrada. Ligue-a no Wi-Fi e rode: ./reset.sh <IP>"; exit 1; }
  NAME="${r%%$'\t'*}"; PRINTER_IP="${r##*$'\t'}"
fi
echo "Impressora: $NAME  IP: $PRINTER_IP"
case "$NAME" in *L395*|"(IP informado)") ;; *) echo "AVISO: só a L395 foi testada; o reset abaixo usa os endereços dela." ;; esac

echo "==> 4/4 Lendo o contador (somente leitura)"
if ! run_conf | grep -q main_waste; then
  echo "A impressora não devolveu o contador. O firmware pode ter bloqueado o SNMP; NÃO adianta continuar."
  exit 1
fi
exec ./scripts/reset-waste-ink.sh "$PRINTER_IP"
