---
name: web-research
description: Pesquisa estruturada na internet com síntese em relatório markdown. Use sempre que o usuário pedir "pesquisar", "buscar", "investigar", "research", "procurar online", "find online", "look up", "comparar X vs Y", "qual o melhor X" ou similar. Decide automaticamente entre modo fast (consultas pontuais) e deep (relatórios profundos), executa via NotebookLM e retorna markdown com citações.
---

# Web Research via NotebookLM

Pesquisa autônoma na internet com importação de fontes, síntese cruzada e geração de relatório em PT-BR. Usa o CLI `notebooklm-py` (reverse-engineering das APIs do Google NotebookLM). Profile dedicado: `clowdbot-research`.

## Quando Ativar

Ative SEMPRE que a intenção do usuário envolver buscar/sintetizar informação atual da internet. Triggers:

- "pesquise", "pesquisa sobre", "busque", "busca sobre", "investigue"
- "research X", "look up", "find online", "search the web"
- "qual o melhor X", "comparar X vs Y", "panorama de X em 2026"
- "me dá um relatório sobre X", "preciso entender o cenário de X"

Não use para: questões respondíveis pelo seu próprio conhecimento, fatos triviais, ou perguntas sobre o código deste repositório (use Grep/Read).

## Critério: fast vs deep

Decida AUTONOMAMENTE antes de disparar:

| Modo | Quando usar | Tempo | Custo cognitivo |
|------|-------------|-------|-----------------|
| `fast` | Consulta pontual, pergunta com resposta clara, tópico estável, validação rápida | ~30-60s | baixo |
| `deep` | Comparativo amplo, panorama, decisão estratégica, tópico volátil (>= 3 dimensões), usuário pediu "profunda/completa/extensa" | 5-15min | alto |

**Regra prática**: se você precisaria abrir 5+ abas do browser pra responder, é `deep`. Se 1-2 sites resolvem, é `fast`.

Ao escolher `deep`, AVISE o usuário antes ("Vou disparar deep research, leva ~10min, te aviso quando terminar") e rode o `research wait` com `run_in_background: true`.

## Invocação por Plataforma

Detecte o sistema antes de rodar. Use `python -m notebooklm` (forma portável que não depende do PATH ter o script):

| OS | Shell | Como rodar |
|----|-------|-----------|
| Windows | PowerShell | `python -m notebooklm -p clowdbot-research <args>` |
| Linux/Mac | Bash | `python3 -m notebooklm -p clowdbot-research <args>` (ou ative o venv onde foi instalado) |

Storage local:
- Windows: `%USERPROFILE%\.notebooklm\profiles\clowdbot-research\storage_state.json`
- Linux/Mac: `$HOME/.notebooklm/profiles/clowdbot-research/storage_state.json`

## Workflow

### Pré-flight (sempre)

```
python -m notebooklm -p clowdbot-research auth check --test
```

Espere ver "Authentication is valid". Se falhar com SID/cookie ausente → AVISE o usuário ("Auth do NotebookLM expirou — rode `python -m notebooklm -p clowdbot-research login --fresh`"). Não tente reauth automaticamente.

### 1. Criar notebook efêmero

```
python -m notebooklm -p clowdbot-research create "research-<timestamp>-<slug>"
```

Captura o UUID retornado. SEMPRE passe via `-n <uuid>` nos comandos seguintes.

### 2. Disparar pesquisa

**fast:**
```
python -m notebooklm -p clowdbot-research source add-research --mode fast --import-all -n <uuid> "<query>"
```

**deep (background + wait):**
```
python -m notebooklm -p clowdbot-research source add-research --mode deep --no-wait -n <uuid> "<query>"
python -m notebooklm -p clowdbot-research research wait -n <uuid> --timeout 1200 --import-all
```

### 3. (Opcional) Adicionar fontes premium curadas

```
python -m notebooklm -p clowdbot-research source add -n <uuid> "https://..."
```

### 4. Gerar relatório

```
python -m notebooklm -p clowdbot-research generate report --format briefing-doc -n <uuid> --wait --retry 3 --append "Estruture em seções com tabelas markdown. Cite fontes com [n]. Foque em: <aspectos>"
```

### 5. Baixar e apresentar

```
python -m notebooklm -p clowdbot-research artifact list -n <uuid>
# pega o UUID do artifact Report

python -m notebooklm -p clowdbot-research download report <output-path>.md -n <uuid> --artifact <artifact-uuid>
```

Sugestão de output path:
- Windows: `$env:TEMP\notebooklm-research\<title>.md`
- Linux/Mac: `/tmp/notebooklm-research/<title>.md`

Depois leia o arquivo e apresente:
- Resumo executivo em 3-5 bullets (não cole o markdown inteiro inline)
- Caminho completo do arquivo
- ⚠️ Fact-check de claims duvidosas

### 6. Cleanup

```
python -m notebooklm -p clowdbot-research delete <uuid> --yes
```

Mantenha o notebook só se o usuário sinalizou follow-up.

## Verificação de Veracidade

Deep research do NotebookLM tem taxa de erro factual ~5-15% (datas erradas, claims exageradas, citações distorcidas). Sempre faça sanity check pós-relatório:

- Datas absurdas (e.g. "lançamento em 2021" para produto de 2026) → flag
- Claims de benchmarks → cruzar com fonte primária se for decisão importante
- Numerais (preços, percentuais) → conferir se existem na fonte citada

Adicione no fim da resposta: "⚠️ Fact-check recomendado: <itens específicos>".

## Quando NÃO usar esta skill

- Pergunta respondível pelo seu próprio conhecimento sem precisar de fontes atuais
- Busca dentro do código do repositório → use `Grep` / `Read`
- Documentação de biblioteca específica → use `context7` MCP (mais rápido e preciso)
- Validação de fato singular conhecido → use `WebSearch` direto (sem overhead de notebook)

## Troubleshooting

| Sintoma | Causa | Fix |
|---------|-------|-----|
| `auth check` falha com SID ausente | Cookies expiraram (~6 meses) | Refazer `python -m notebooklm -p clowdbot-research login --fresh` |
| `IMPORT_RESEARCH timed out` durante deep | Normal para queries amplas | Skill já passa `--retry 3` — só esperar |
| `generate report` retorna texto vazio | Notebook sem sources prontas | Verifique `source list -n <uuid>` antes de gerar |
| Erro "Unknown language code: pt-BR" | Use underscore: `pt_BR` | `python -m notebooklm -p clowdbot-research language set pt_BR` |
| `notebooklm` não encontrado no PATH | Script não está no PATH | A skill já usa `python -m notebooklm` (que sempre funciona se o pacote está instalado) |
