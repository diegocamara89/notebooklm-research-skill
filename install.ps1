# Web Research Skill - Bootstrap Windows
# Instala notebooklm-py + skill em ~/.claude/skills/web-research/
# Uso: .\install.ps1 [-Profile clowdbot-research] [-SkipLogin]

param(
    [string]$NotebookProfile = "clowdbot-research",
    [switch]$SkipLogin
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Web Research Skill - Bootstrap (Windows) ===" -ForegroundColor Cyan
Write-Host "Profile: $NotebookProfile"
Write-Host ""

# 1. Verificar Python 3.10+
Write-Host "[1/5] Verificando Python..." -ForegroundColor Yellow
try {
    $pyVersion = (python --version 2>&1) -replace 'Python ', ''
    $major, $minor = $pyVersion.Split('.')[0..1]
    if ([int]$major -lt 3 -or ([int]$major -eq 3 -and [int]$minor -lt 10)) {
        throw "Python $pyVersion é antigo. Requer 3.10+."
    }
    Write-Host "  OK: Python $pyVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERRO: $_" -ForegroundColor Red
    Write-Host "  Instale Python 3.10+ de https://python.org" -ForegroundColor Red
    exit 1
}

# 2. Instalar notebooklm-py + extras
Write-Host "[2/5] Instalando notebooklm-py..." -ForegroundColor Yellow
pip install --user --upgrade "notebooklm-py[browser,cookies]" 2>&1 | Select-Object -Last 3
if ($LASTEXITCODE -ne 0) { Write-Host "  ERRO no pip install" -ForegroundColor Red; exit 1 }
Write-Host "  OK" -ForegroundColor Green

# 3. Baixar Chromium do Playwright (necessário para login fresh)
Write-Host "[3/5] Baixando Chromium do Playwright (pode levar 1-2min)..." -ForegroundColor Yellow
python -m playwright install chromium 2>&1 | Select-Object -Last 3
Write-Host "  OK" -ForegroundColor Green

# 4. Instalar SKILL.md em ~/.claude/skills/web-research/
Write-Host "[4/5] Instalando SKILL.md em ~/.claude/skills/web-research/..." -ForegroundColor Yellow
$skillDir = "$env:USERPROFILE\.claude\skills\web-research"
$skillSrc = Join-Path $ScriptDir "SKILL.md"
if (-not (Test-Path $skillSrc)) {
    Write-Host "  ERRO: SKILL.md não encontrado em $skillSrc" -ForegroundColor Red
    exit 1
}
New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
Copy-Item $skillSrc "$skillDir\SKILL.md" -Force
Write-Host "  OK: $skillDir\SKILL.md" -ForegroundColor Green

# 5. Login Google (interativo, abre browser)
if ($SkipLogin) {
    Write-Host "[5/5] Login pulado (--SkipLogin). Rode manualmente:" -ForegroundColor Yellow
    Write-Host "  python -m notebooklm -p $NotebookProfile login --fresh" -ForegroundColor Cyan
} else {
    Write-Host "[5/5] Login Google (vai abrir browser)..." -ForegroundColor Yellow
    Write-Host "  Logue na conta Google que terá acesso ao NotebookLM," -ForegroundColor Gray
    Write-Host "  acesse notebooklm.google.com uma vez para validar," -ForegroundColor Gray
    Write-Host "  então volte aqui e aperte ENTER." -ForegroundColor Gray
    Write-Host ""
    python -m notebooklm -p $NotebookProfile login --fresh

    Write-Host ""
    Write-Host "Configurando idioma pt_BR e validando auth..." -ForegroundColor Yellow
    python -m notebooklm -p $NotebookProfile language set pt_BR 2>&1 | Select-Object -First 2
    python -m notebooklm -p $NotebookProfile auth check --test 2>&1 | Select-Object -First 10
}

Write-Host ""
Write-Host "=== Instalação concluída ===" -ForegroundColor Green
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "  1. Abra Claude Code e peça: 'pesquise X'"
Write-Host "  2. A skill 'web-research' deve aparecer na lista de skills disponíveis"
Write-Host "  3. Para Codex: referencie manualmente '~/.claude/skills/web-research/SKILL.md'"
Write-Host ""
Write-Host "Storage de auth: $env:USERPROFILE\.notebooklm\profiles\$NotebookProfile\storage_state.json" -ForegroundColor Gray
