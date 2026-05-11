#!/usr/bin/env bash
# Web Research Skill - Bootstrap Linux/Mac
# Instala notebooklm-py + skill em ~/.claude/skills/web-research/
# Uso: ./install.sh [--profile clowdbot-research] [--skip-login] [--no-browser]

set -euo pipefail

PROFILE="clowdbot-research"
SKIP_LOGIN=0
NO_BROWSER=0  # use --no-browser em servidor headless (skip Chromium)

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift 2 ;;
        --skip-login) SKIP_LOGIN=1; shift ;;
        --no-browser) NO_BROWSER=1; SKIP_LOGIN=1; shift ;;
        -h|--help)
            echo "Usage: $0 [--profile NAME] [--skip-login] [--no-browser]"
            echo "  --profile NAME    Nome do profile NotebookLM (default: clowdbot-research)"
            echo "  --skip-login      Não dispara login interativo"
            echo "  --no-browser      Pula instalação do Chromium (servidor headless) — implica --skip-login"
            exit 0 ;;
        *) echo "Arg desconhecido: $1"; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cyan() { printf "\033[36m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
red() { printf "\033[31m%s\033[0m\n" "$*"; }

cyan "=== Web Research Skill - Bootstrap (Linux/Mac) ==="
echo "Profile: $PROFILE"
echo

# 1. Verificar Python 3.10+
yellow "[1/5] Verificando Python..."
PY=$(command -v python3 || command -v python)
if [[ -z "$PY" ]]; then red "  ERRO: Python não encontrado"; exit 1; fi
PY_VER=$($PY -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MAJOR=${PY_VER%%.*}
PY_MINOR=${PY_VER##*.}
if (( PY_MAJOR < 3 || (PY_MAJOR == 3 && PY_MINOR < 10) )); then
    red "  ERRO: Python $PY_VER. Requer 3.10+."; exit 1
fi
green "  OK: Python $PY_VER ($PY)"

# 2. Instalar notebooklm-py
yellow "[2/5] Instalando notebooklm-py..."
EXTRAS="cookies"
[[ $NO_BROWSER -eq 0 ]] && EXTRAS="browser,cookies"
$PY -m pip install --user --upgrade "notebooklm-py[$EXTRAS]" 2>&1 | tail -3
green "  OK"

# 3. Chromium do Playwright (skip se headless)
if [[ $NO_BROWSER -eq 0 ]]; then
    yellow "[3/5] Baixando Chromium do Playwright (1-2min)..."
    $PY -m playwright install chromium 2>&1 | tail -3
    green "  OK"
else
    yellow "[3/5] Chromium pulado (--no-browser)"
fi

# 4. Instalar SKILL.md
yellow "[4/5] Instalando SKILL.md em ~/.claude/skills/web-research/..."
SKILL_DIR="$HOME/.claude/skills/web-research"
SKILL_SRC="$SCRIPT_DIR/SKILL.md"
if [[ ! -f "$SKILL_SRC" ]]; then
    red "  ERRO: SKILL.md não encontrado em $SKILL_SRC"; exit 1
fi
mkdir -p "$SKILL_DIR"
cp "$SKILL_SRC" "$SKILL_DIR/SKILL.md"
green "  OK: $SKILL_DIR/SKILL.md"

# 5. Login
if [[ $SKIP_LOGIN -eq 1 ]]; then
    yellow "[5/5] Login pulado. Rode manualmente:"
    if [[ $NO_BROWSER -eq 1 ]]; then
        cyan "  # Em servidor headless: faça login em outra máquina e copie o storage_state.json:"
        cyan "  scp ~/.notebooklm/profiles/$PROFILE/storage_state.json this-host:~/.notebooklm/profiles/$PROFILE/"
    else
        cyan "  $PY -m notebooklm -p $PROFILE login --fresh"
    fi
else
    yellow "[5/5] Login Google (vai abrir browser)..."
    echo "  Logue, acesse notebooklm.google.com uma vez, volte e aperte ENTER."
    echo
    $PY -m notebooklm -p "$PROFILE" login --fresh

    echo
    yellow "Configurando idioma pt_BR e validando..."
    $PY -m notebooklm -p "$PROFILE" language set pt_BR 2>&1 | head -2
    $PY -m notebooklm -p "$PROFILE" auth check --test 2>&1 | head -10
fi

echo
green "=== Instalação concluída ==="
echo
cyan "Próximos passos:"
echo "  1. Abra Claude Code e peça: 'pesquise X'"
echo "  2. A skill 'web-research' deve aparecer na lista de skills"
echo "  3. Para Codex: referencie manualmente '~/.claude/skills/web-research/SKILL.md'"
echo
echo "Storage de auth: $HOME/.notebooklm/profiles/$PROFILE/storage_state.json"
