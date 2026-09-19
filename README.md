# Epson L395 — zerar o contador de almofada de limpeza no macOS (Apple Silicon)

Guia e scripts para zerar o contador de **tinta residual** ("Waste ink pad counter overflow" / "Ink overflow error") da **Epson L395** direto no Terminal do Mac, sem Windows, sem Docker e sem pagar por chave de reset.

> **Resultado testado:** Mac mini M4 (macOS, arm64, Python 3.13.7), Epson L395, firmware `RY13K3 13 Mar 2020`, conexão Wi-Fi.
> Antes: `main_waste = 100.02%`, erro `Ink overflow error`, `maintenance_box_1: full`.
> Depois do reset e de religar a impressora: `main_waste` baixou, `maintenance_box_1: not full`, `Idle (ready to print)`.

## O que isto faz (e o que não faz)

A L395 mantém, na EEPROM, um contador que estima quanto de tinta foi para as almofadas de resíduo. Quando chega a 100%, a impressora trava com erro. Este guia **zera esse contador** usando o projeto de terceiros [`Ircama/epson_print_conf`](https://github.com/Ircama/epson_print_conf), que fala com a impressora por **SNMP via rede (TCP/IP)**.

- **Não usa USB.** A impressora precisa estar na mesma rede (Wi-Fi ou cabo) do Mac.
- **Não limpa as almofadas físicas.** O README do upstream avisa que a manutenção física (trocar ou limpar as almofadas) continua necessária. Se elas estiverem saturadas, a tinta pode vazar dentro da impressora. **Você usa por sua conta e risco.**
- Este repositório **não contém código do upstream**. Os scripts só automatizam a instalação e chamam o upstream num commit fixo (`c93100c`).

## Por que essa ferramenta

Verificado no código-fonte do upstream (`epson_print_conf.py`):

```python
"ET-2600": {
    "alias": ["ET-2650", "L395"],
    "read_key": [16, 8],
    "main_waste": {"oids": [24, 25, 30], "divider": 62.06},
    "raw_waste_reset": {24: 0, 25: 0, 30: 0, 28: 0, 29: 0, 46: 94},
    ...
```

A L395 é um alias do ET-2600 e tem parâmetros próprios de leitura e reset. Ela **não** consta na lista de "Known incompatible models" do README (modelos cujo firmware bloqueou o acesso à EEPROM por SNMP, como L3250, L3260 e ET-2800). Só a leitura real da impressora confirma isso no seu firmware, e o passo 3 abaixo faz essa leitura sem alterar nada.

## Uso

Requisitos: macOS com `git` e `python3` (os do Xcode Command Line Tools servem).

```bash
git clone https://github.com/marceloandrad3/epson-l395-mac-reset
cd epson-l395-mac-reset

./scripts/setup.sh                 # 1. clona o upstream num commit fixo e instala as dependências num venv
./scripts/find-printer.sh          # 2. descobre o IP da impressora via Bonjour (somente leitura)
./scripts/status.sh <IP>           # 3. lê status e contador (somente leitura). Confirma se o seu firmware responde
./scripts/reset-waste-ink.sh <IP>  # 4. salva backup, pede confirmação e zera o contador (ESCREVE na EEPROM)
```

Se o passo 3 não devolver `main_waste`, **pare**: o seu firmware provavelmente bloqueou o SNMP e o passo 4 não vai funcionar.

O passo 4 salva a leitura atual dos endereços da EEPROM em `backups/<data-hora>/` e só escreve depois de você digitar `SIM`. Depois do reset, **desligue a impressora, espere ~10 s e ligue de novo**: o painel pode continuar mostrando o erro até reiniciar.

Para outro modelo: `MODEL=<nome> ./scripts/status.sh <IP>`. Só a L395 foi testada, e os endereços do reset (`ADDRS`) são os dela.

## Reverter

O backup traz os valores originais dos endereços 24, 25, 30, 28, 29 e 46. Para regravar um deles use o CLI do upstream (`-W endereço:valor`), conforme o README do upstream.

## Créditos e referências

- [Ircama/epson_print_conf](https://github.com/Ircama/epson_print_conf) (EUPL-1.2): a ferramenta que faz o trabalho de verdade.
- Scripts deste repositório: licença MIT (veja `LICENSE`).
- Projeto independente, sem vínculo com a Epson. "Epson" e "L395" são marcas de seus donos.

---

## English summary

Scripts and notes to reset the **waste ink pad counter** on an **Epson L395** from macOS (Apple Silicon), over the network via SNMP, using [`Ircama/epson_print_conf`](https://github.com/Ircama/epson_print_conf) pinned to commit `c93100c`. The L395 is defined there as an alias of the ET-2600. Tested on a Mac mini M4 with firmware `RY13K3`: waste counter went from 100.02% to normal, and the printer returned to "Idle (ready to print)" after a power cycle. Run `setup.sh`, `find-printer.sh`, `status.sh`, then `reset-waste-ink.sh`. This does **not** clean the physical pads: use at your own risk.
