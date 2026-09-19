#!/bin/bash
# Zerar Epson L395: app com janelas nativas do macOS (osascript). Usa os mesmos scripts do reset.sh.
set -Eeuo pipefail
APP_RES="$(cd "$(dirname "$0")/../Resources" && pwd)"
export DATA_DIR="$HOME/Library/Application Support/EpsonL395Reset"
mkdir -p "$DATA_DIR"
LOG="$DATA_DIR/app.log"
exec 3>&1
exec >>"$LOG" 2>&1
echo "=== $(date) ==="
source "$APP_RES/scripts/common.sh"
TEST="${EPSON_APP_TEST:-}"   # modo de teste: sem janelas e sem escrever na impressora
BUSY_PID=""

# ask "mensagem" "Botão cancelar" "Botão OK" ícone(1=nota 2=atenção 0=erro); sai com erro se cancelar.
ask() {
  if [ -n "$TEST" ]; then echo "[JANELA] $1  -> [$3]" >&3; return 0; fi
  osascript - "$1" "$2" "$3" "${4:-1}" >/dev/null <<'AS'
on run argv
  display dialog (item 1 of argv) with title "Zerar Epson L395" buttons {item 2 of argv, item 3 of argv} default button (item 3 of argv) cancel button (item 2 of argv) with icon (item 4 of argv as integer)
end run
AS
}
say() {  # janela informativa com um botão OK
  if [ -n "$TEST" ]; then echo "[AVISO] $1" >&3; return 0; fi
  osascript - "$1" "${2:-1}" >/dev/null <<'AS'
on run argv
  display dialog (item 1 of argv) with title "Zerar Epson L395" buttons {"OK"} default button "OK" with icon (item 2 of argv as integer)
end run
AS
}
ask_text() {  # ask_text "mensagem"  -> imprime o texto digitado
  if [ -n "$TEST" ]; then echo "[PERGUNTA] $1" >&3; echo "${EPSON_APP_TEST_IP:-}"; return 0; fi
  osascript - "$1" <<'AS'
on run argv
  set r to display dialog (item 1 of argv) with title "Zerar Epson L395" default answer "" buttons {"Cancelar", "OK"} default button "OK" cancel button "Cancelar" with icon 1
  return text returned of r
end run
AS
}
busy() {  # janela de "aguarde" que fica aberta até unbusy
  if [ -n "$TEST" ]; then echo "[AGUARDE] $1" >&3; return 0; fi
  osascript - "$1" >/dev/null 2>&1 <<'AS' &
on run argv
  display dialog (item 1 of argv) with title "Zerar Epson L395" buttons {"Aguarde..."} default button 1 giving up after 1200 with icon 1
end run
AS
  BUSY_PID=$!
}
unbusy() {
  if [ -n "$BUSY_PID" ]; then kill "$BUSY_PID" 2>/dev/null || true; wait "$BUSY_PID" 2>/dev/null || true; BUSY_PID=""; fi
  return 0
}
fail() {
  unbusy
  say "Algo deu errado: $1"$'\n\n'"Se precisar de ajuda, o registro está em:"$'\n'"$LOG" 0
  exit 1
}
trap 'fail "erro inesperado."' ERR

ask $'Este app zera o contador da almofada de limpeza da sua Epson L395 (o erro "Ink overflow").\n\nAntes de começar:\n• Ligue a impressora\n• Ela precisa estar no mesmo Wi-Fi deste Mac' "Cancelar" "Começar" 1 || exit 0

if [ ! -x "$PY" ]; then
  busy $'Preparando o app pela primeira vez...\n\nIsso leva de 1 a 3 minutos e precisa de internet.\nNão feche esta janela.'
  "$APP_RES/scripts/setup.sh" || fail "não consegui instalar. Verifique a internet e abra o app de novo."
  unbusy
fi

busy "Procurando sua impressora na rede..."
r="$(discover_epson || true)"
unbusy
if [ -n "$r" ]; then
  NAME="${r%%$'\t'*}"; PRINTER_IP="${r##*$'\t'}"
else
  PRINTER_IP="$(ask_text $'Não achei a impressora sozinho.\n\nDigite o IP dela (aparece no painel do seu roteador, por exemplo 192.168.0.25):')" || exit 0
  NAME="impressora"
  [[ "$PRINTER_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || fail "IP inválido."
fi
case "$NAME" in
  *L395*|impressora) ;;
  *) ask "Achei: $NAME"$'\n\nEste app só foi testado na Epson L395. Continuar mesmo assim?' "Cancelar" "Continuar" 2 || exit 0 ;;
esac

busy "Lendo o contador da impressora..."
out="$(run_conf 2>&1 || true)"
unbusy
pct="$(printf '%s' "$out" | sed -n "s/.*'main_waste': \([0-9.]*\).*/\1/p" | head -1)"
if [ -z "$pct" ]; then
  say $'A impressora não respondeu ao pedido do contador.\n\nO firmware dela pode ter bloqueado esse acesso. Nesse caso este app não consegue ajudar, e nada foi alterado.' 2
  exit 1
fi

ask "Achei: $NAME"$'\n\n'"A almofada de limpeza está em ${pct}%."$'\n\nO app vai salvar uma cópia de segurança e depois zerar o contador.\n\nATENÇÃO: isso NÃO limpa a almofada de verdade. Se ela estiver encharcada, troque ou limpe depois, para a tinta não vazar.' "Cancelar" "Zerar agora" 2 || exit 0

if [ -n "$TEST" ]; then
  echo "[TESTE] reset NÃO executado (modo de teste)" >&3
  exit 0
fi
busy "Zerando o contador... Não desligue a impressora."
ASSUME_YES=1 "$APP_RES/scripts/reset-waste-ink.sh" "$PRINTER_IP" || fail "o reset não terminou. Nada foi confirmado; tente de novo."
unbusy
sleep 2
out="$(run_conf 2>&1 || true)"
after="$(printf '%s' "$out" | sed -n "s/.*'main_waste': \([0-9.]*\).*/\1/p" | head -1)"
if [ -n "$after" ] && awk "BEGIN{exit !($after < 20)}"; then
  say "Pronto! O contador agora está em ${after}%."$'\n\nAgora:\n1. Desligue a impressora pelo botão\n2. Espere 10 segundos\n3. Ligue de novo\n\nA cópia de segurança ficou em:\n'"$BACKUP_DIR" 1
else
  say $'O reset foi enviado, mas não consegui confirmar o novo valor.\n\nDesligue a impressora, espere 10 segundos, ligue de novo e abra este app para conferir.' 2
fi
