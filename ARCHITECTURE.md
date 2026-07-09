# Arquitetura — Trading Harness

## Separação estratégia × harness

```
┌─────────────────────────────────────────────────────────────────────┐
│ CAMADA 1 — HARNESS (conhecimento + validação)                       │
│ AGENTS.md · docs/ · scripts/validate.ps1 · CI · exec-plans          │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│ CAMADA 2 — ORQUESTRAÇÃO                                             │
│ pipeline/analyze.py (determinístico, produção)                        │
│ agent/graph.py (LangGraph + tool-calling, opcional/exploratório)     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│ CAMADA 3 — TOOLS (contratos @tool)                                  │
│ data · {strategy} · trade · risk · backtest · explain · analyze     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│ CAMADA 4 — DOMÍNIO ESTRATÉGIA                                       │
│ {strategy}_rules · confluences · schemas Pydantic                   │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│ CAMADA 5 — INFRAESTRUTURA                                           │
│ CCXT · JSON stores · webhooks · Streamlit · Docker · LangSmith      │
└─────────────────────────────────────────────────────────────────────┘
```

## Fluxo de dados

```
CLI / UI / Scan agendado
       │
       ▼
run_pair_analysis(pair)
       │
       ├─► fetch_multi_tf_data
       ├─► detect_{strategy}_setup      ← único bloco específico
       ├─► analyze_confluences
       ├─► calculate_trade_params
       ├─► check_risk_limits
       ├─► run_{strategy}_backtest
       ├─► memory.log_setup
       ├─► paper | broker (conforme MODE)
       ├─► audit.log
       └─► explain + webhooks
```

## Módulos reutilizáveis (não mudam por estratégia)

| Módulo | Responsabilidade |
|--------|------------------|
| `guardrails/` | Risco 1%/3%/6%, calendário, live gate |
| `paper/` | Posições simuladas + alertas SL/TP |
| `audit/` | JSONL append-only |
| `ops/golive.py` | Checklist semáforo |
| `alerts/` | Webhooks n8n, Telegram |
| `providers/` | CCXT multi-exchange |
| `ui/` | Dashboard Streamlit |

## Módulos específicos da estratégia

| Módulo | Responsabilidade |
|--------|------------------|
| `config/{strategy}_rules.py` | Enums, thresholds, constantes |
| `tools/{strategy}.py` | `detect_{strategy}_setup` |
| `analysis/confluences.py` | Filtros de qualidade (opcional) |
| `docs/design-docs/{strategy}-strategy.md` | Regras formais |

## Modos de operação

| Modo | Comportamento | Default |
|------|---------------|---------|
| `analysis` | Detecta + explica, sem posição | ✅ |
| `paper` | Posição simulada em JSON | validação |
| `live` | Broker real, gate duplo | ❌ bloqueado |

## Stack recomendada

Python 3.11+ · LangGraph · Pydantic · pandas · CCXT · structlog · Streamlit · pytest · ruff

## Maturidade (L0–L5)

| Nível | Critério |
|-------|----------|
| L0 | Prompts soltos |
| L1 | AGENTS.md + docs + git |
| L2 | Testes + CI |
| L3 | Observability + dados reais |
| L4 | Feature E2E produção |
| L5 | Self-healing + doc garden + eval |

Ver [docs/FASES-0-8.md](docs/FASES-0-8.md) para entregáveis por fase.