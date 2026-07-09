# Estrutura de repositório — Template Harness

> Substitua `{agent}` pelo nome do pacote (ex.: `crt_agent`, `smc_agent`, `orb_agent`).

```
{project-root}/
├── AGENTS.md                    # Mapa para agentes IA (< 150 linhas)
├── ARCHITECTURE.md              # Diagrama de camadas + stack
├── README.md                    # Início rápido humano
├── pyproject.toml               # Deps, scripts CLI, pytest, ruff
├── Dockerfile                   # Imagem produção (UI ou API)
├── docker-compose.yml           # Dev local
├── .env.example                 # Todas as variáveis documentadas
├── .github/workflows/
│   ├── ci.yml                   # lint + test + validate
│   └── deploy.yml               # deploy produção (opcional)
│
├── docs/                        # System of record
│   ├── PLANO.md                 # Plano mestre + status fases
│   ├── SECURITY.md
│   ├── RELIABILITY.md
│   ├── QUALITY_SCORE.md
│   ├── harness-blueprint/       # Link para trading-harness (opcional)
│   ├── design-docs/
│   │   ├── core-beliefs.md
│   │   ├── harness-model.md
│   │   ├── {strategy}-strategy.md   # Regras da estratégia
│   │   └── go-live-checklist.md
│   ├── product-specs/
│   │   └── agente-{strategy}.md
│   └── exec-plans/
│       ├── active/              # Máx. 1 plano ativo
│       ├── completed/
│       └── tech-debt-tracker.md
│
├── scripts/
│   ├── setup.ps1                # Bootstrap venv + deps
│   ├── validate.ps1             # Valida estrutura harness
│   ├── scheduled-scan.ps1       # Scan agendado produção
│   ├── register-scheduled-task.ps1
│   ├── deploy-easypanel.ps1     # Empacota deploy
│   └── sync-github-secrets.ps1
│
├── data/                        # Runtime (gitignore parcial)
│   ├── memory/                  # JSON stores
│   ├── audit/                   # JSONL audit log
│   └── cache/                   # OHLCV, calendário
│
├── tests/
│   ├── conftest.py              # Isolamento singletons
│   ├── test_smoke.py
│   ├── test_{strategy}_rules.py
│   ├── test_pipeline.py
│   ├── test_guardrails.py
│   └── test_*                   # Por domínio
│
└── src/{agent}/
    ├── main.py                  # CLI entrypoint
    ├── agent/
    │   ├── graph.py             # LangGraph (opcional LLM)
    │   └── state.py
    ├── analysis/                # Lógica auxiliar estratégia
    ├── alerts/
    │   ├── dispatcher.py
    │   ├── payloads.py
    │   └── webhooks.py
    ├── audit/
    │   └── logger.py            # JSONL append-only
    ├── backtest/
    │   └── engine.py
    ├── broker/
    │   └── executor.py          # stub | ccxt
    ├── config/
    │   ├── settings.py          # pydantic-settings
    │   ├── {strategy}_rules.py  # Regras codificadas
    │   └── pairs_registry.py    # Ativos dinâmicos
    ├── guardrails/
    │   ├── limits.py            # RiskTracker
    │   ├── calendar.py          # Bloqueio notícias
    │   ├── live_gate.py         # Dupla aprovação live
    │   └── token_rotation.py
    ├── memory/
    │   └── store.py
    ├── metrics/
    │   └── collector.py
    ├── observability/
    │   └── langsmith.py
    ├── ops/
    │   └── golive.py            # Checklist semáforo
    ├── paper/
    │   ├── store.py
    │   └── alerts.py
    ├── pipeline/
    │   └── analyze.py           # Orquestração determinística
    ├── providers/
    │   ├── ccxt_provider.py
    │   └── symbols.py
    ├── tools/                   # Contratos @tool LangChain
    │   ├── registry.py
    │   ├── data.py
    │   ├── {strategy}.py        # Detecção setup
    │   ├── trade.py
    │   ├── risk.py
    │   ├── backtest.py
    │   ├── explain.py
    │   └── analyze.py
    ├── models/
    │   └── schemas.py           # Pydantic fronteira
    └── ui/                      # Streamlit (opcional Fase 5+)
        ├── app.py
        ├── production.py
        ├── live_ops_panel.py
        └── auth.py
```

## Convenções de naming

| Padrão | Exemplo CRT | Exemplo SMC |
|--------|-------------|-------------|
| Pacote Python | `crt_agent` | `smc_agent` |
| CLI | `crt-agent` | `smc-agent` |
| Regras | `crt_rules.py` | `smc_rules.py` |
| Tool detecção | `detect_crt_setup` | `detect_smc_setup` |
| Env prefix | `CRT_` | `SMC_` |
| Audit events | `setup_detected` | genérico, reutilizar |

## Ficheiros obrigatórios (validate.ps1)

- `AGENTS.md` ≤ 150 linhas
- `docs/design-docs/`, `docs/product-specs/`, `docs/exec-plans/active/`
- `pyproject.toml` + `src/{agent}/main.py`
- Mínimo 8 tools em `tools/`
- `tests/` com smoke tests

## Dependências base (pyproject.toml)

```toml
dependencies = [
  "langgraph>=0.2",
  "langchain-core>=0.3",
  "pydantic>=2",
  "pydantic-settings>=2",
  "pandas>=2",
  "ccxt>=4",
  "structlog>=24",
  "httpx>=0.27",
]
optional-dependencies.ui = ["streamlit>=1.40", "plotly>=5"]
optional-dependencies.dev = ["pytest>=8", "ruff>=0.8"]
```