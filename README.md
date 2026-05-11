# notebooklm-research-skill

Skill plug-and-play para Claude Code, Codex e OpenClaw que delega pesquisa estruturada na internet ao Google NotebookLM. Decide automaticamente entre modo `fast` e `deep`, gera relatório markdown em PT-BR com citações, e limpa atrás de si.

> **Não é um wrapper do `notebooklm-py`** — usa ele como dependência. O valor desta skill está nos critérios de decisão, no workflow ephemeral, na verificação de veracidade obrigatória e no bootstrap multi-plataforma. Veja [Por que esta skill existe](#por-que-esta-skill-existe).

## Quick start

```powershell
# Windows
git clone https://github.com/diegocamara89/notebooklm-research-skill.git
cd notebooklm-research-skill
.\install.ps1
```

```bash
# Linux/Mac
git clone https://github.com/diegocamara89/notebooklm-research-skill.git
cd notebooklm-research-skill
./install.sh

# Servidor headless (sem GUI):
./install.sh --no-browser
# depois: scp do storage_state.json de uma máquina com browser
```

Pronto. Em ~3min você tem `notebooklm-py` instalado, Chromium baixado, login Google feito e a skill em `~/.claude/skills/web-research/SKILL.md`.

## Como usar

Em uma sessão nova do Claude Code:

```
> pesquise quais foram os 3 maiores lançamentos de modelos de IA em maio de 2026
> compare Tauri vs Electron, profundo
> qual a melhor lib Python para parsing de PDF?
```

A skill detecta a intenção, decide `fast` (5+ abas no browser) vs `deep` (pesquisa multi-dimensional), e retorna:

- Resumo executivo em 3-5 bullets
- Caminho completo do relatório markdown
- ⚠️ Itens que merecem fact-check

Veja exemplo real gerado pela própria skill: [`examples/best-ai-agents-2026.md`](examples/best-ai-agents-2026.md).

## Por que esta skill existe

O [`teng-lin/notebooklm-py`](https://github.com/teng-lin/notebooklm-py) (a dependência) é excelente — expõe toda a API do NotebookLM via CLI. Mas é uma ferramenta de baixo nível: você precisa decidir quando usar, qual modo, qual workflow, como apresentar o resultado.

Esta skill resolve a camada de **orquestração**:

| Problema sem a skill | Solução da skill |
|----------------------|------------------|
| Agente não sabe quando invocar `notebooklm` | `description` com triggers em PT-BR ("pesquise", "investigue", "compare X vs Y") |
| Agente não sabe escolher fast vs deep | Critério explícito: "5+ abas → deep" |
| Notebook acumula a cada query, enche conta | Workflow ephemeral com cleanup obrigatório |
| Deep research alucina ~5-15% (datas, benchmarks) | Passo de fact-check obrigatório no fim do output |
| Doc oficial não cobre headless | `install.sh --no-browser` + scp instructions |
| Idioma do relatório vem em inglês | `pt_BR` configurado globalmente no install |
| Rate limits derrubam relatórios grandes | `--retry 3` em `generate report` (descoberto rodando) |

## Comparação com alternativas

| Solução | Custo | Setup | Decisão fast/deep | Multi-plataforma |
|---------|-------|-------|-------------------|------------------|
| **Esta skill + NotebookLM** | Free | 3min | Automática | Win/Linux/Mac/headless |
| OpenAI Deep Research (ChatGPT Pro) | $200/mês | Zero | Manual | Browser only |
| Gemini Deep Research (Google AI Pro) | $20/mês | Zero | Manual | Browser only |
| Perplexity Pro | $20/mês | Zero | Manual | Browser only |
| `notebooklm-py` puro | Free | 1min | Você decide | Mesma cobertura |

## Arquitetura

```
┌─────────────────────────────────────┐
│  Claude Code / Codex / OpenClaw     │
│  Lê SKILL.md de ~/.claude/skills/   │
└─────────────────┬───────────────────┘
                  │ python -m notebooklm
                  ▼
┌─────────────────────────────────────┐
│  notebooklm-py (PyPI)               │
│  Reverse-engineered NotebookLM API  │
└─────────────────┬───────────────────┘
                  │ HTTPS + cookies
                  ▼
┌─────────────────────────────────────┐
│  Google NotebookLM (web)            │
│  Deep Research nativo + síntese     │
└─────────────────────────────────────┘
```

A skill **não** mantém estado próprio — toda persistência é no NotebookLM (notebooks efêmeros) ou em arquivos markdown locais.

## Limitações honestas

- **API reverse-engineered**: pode quebrar a qualquer momento (não oficial do Google). Manutenção depende do upstream `notebooklm-py`.
- **Cookies expiram em ~6 meses**: precisa relogin manual. Skill detecta auth check falho e avisa, não tenta reauth.
- **Taxa de alucinação ~5-15%** em deep research: skill já instrui fact-check, mas você precisa ler.
- **Codex CLI não auto-descobre skills**: precisa referenciar manualmente (instruções no [SKILL.md](SKILL.md)).
- **OpenClaw funciona** se a skill estiver em `~/.openclaw/plugin-skills/web-research/SKILL.md` (cópia manual após install).

## Manutenção

| Operação | Comando |
|----------|---------|
| Atualizar (após pull) | Re-rodar `install.ps1` ou `install.sh` (idempotente) |
| Renovar auth | `python -m notebooklm -p clowdbot-research login --fresh` |
| Trocar conta Google | `python -m notebooklm -p clowdbot-research login --fresh` |
| Validar saúde | `python -m notebooklm -p clowdbot-research auth check --test` |
| Desinstalar skill | `rm -rf ~/.claude/skills/web-research` |

## Estrutura do repo

```
notebooklm-research-skill/
├── SKILL.md          ← Skill canonical (instalada em ~/.claude/skills/web-research/)
├── install.ps1       ← Bootstrap Windows
├── install.sh        ← Bootstrap Linux/Mac (com --no-browser para headless)
├── examples/         ← Relatórios reais gerados pela skill
├── LICENSE           ← MIT
└── README.md
```

## Acknowledgments

- [`teng-lin/notebooklm-py`](https://github.com/teng-lin/notebooklm-py) — CLI Python que faz o trabalho pesado
- [Google NotebookLM](https://notebooklm.google.com) — engine de pesquisa subjacente
- [Anthropic Claude Code](https://claude.com/code) — ambiente onde a skill nasceu

## License

MIT — veja [LICENSE](LICENSE).
