# Fases 0–8 — Roadmap de implementação Harness

> Copie este ficheiro como plano ativo em `docs/exec-plans/active/` ao iniciar um novo agente.

## Fase 0 — Fundação (1 semana)

**Objetivo:** Repositório bootável com harness mínimo.

| # | Entregável | Critério done |
|---|------------|---------------|
| 0.1 | Scaffold `docs/`, `scripts/`, `tests/` | `validate.ps1` passa |
| 0.2 | `pyproject.toml` + `src/{agent}/main.py` | `pip install -e .` OK |
| 0.3 | `AGENTS.md` + `ARCHITECTURE.md` | AGENTS ≤ 150 linhas |
| 0.4 | `settings.py` + `.env.example` | Modo default `analysis` |
| 0.5 | 8 tools stub | Registry lista 8+ tools |
| 0.6 | `agent/graph.py` bootstrap | Graph compila sem API key |
| 0.7 | Smoke tests | `pytest` ≥ 4 testes verdes |

**Comandos:**
```powershell
.\scripts\setup.ps1
.\scripts\validate.ps1
pytest -q
```

---

## Fase 1 — Definição da estratégia (1 semana)

**Objetivo:** Regras formalizadas e validáveis.

| # | Entregável |
|---|------------|
| 1.1 | `docs/design-docs/{strategy}-strategy.md` |
| 1.2 | `docs/product-specs/agente-{strategy}.md` |
| 1.3 | `docs/design-docs/{strategy}-validation-checklist.md` |
| 1.4 | Pares prioritários + KPIs definidos |
| 1.5 | `config/{strategy}_rules.py` (enums, constantes) |
| 1.6 | `tests/test_{strategy}_rules.py` |

**Gate:** Trader/revisor assina checklist de regras (TD estratégia).

---

## Fase 2 — Dados e ambiente (1–2 semanas)

**Objetivo:** OHLCV real multi-timeframe.

| # | Entregável |
|---|------------|
| 2.1 | `providers/ccxt_provider.py` |
| 2.2 | `providers/symbols.py` (mapeamento par → exchange) |
| 2.3 | `tools/data.py` → `fetch_multi_tf_data` |
| 2.4 | Modos `stub` / `ccxt` / `auto` |
| 2.5 | `config/pairs_registry.py` |
| 2.6 | `tests/test_ccxt_data.py` (integration marker) |
| 2.7 | CI com `CRT_DATA_SOURCE=stub` |
| 2.8 | (Opcional) `providers/mt5_provider.py` + doc [INTEGRACAO-MT5-DATA-PROVIDER.md](./INTEGRACAO-MT5-DATA-PROVIDER.md) |

---

## Fase 3 — Core da estratégia (3–5 semanas)

**Objetivo:** Detecção + pipeline + CLI.

| # | Entregável |
|---|------------|
| 3.1 | `tools/{strategy}.py` → `detect_{strategy}_setup` |
| 3.2 | `analysis/confluences.py` (se aplicável) |
| 3.3 | `tools/trade.py` → `calculate_trade_params` |
| 3.4 | `tools/explain.py` |
| 3.5 | `pipeline/analyze.py` → `run_pair_analysis` |
| 3.6 | `tools/analyze.py` → CLI `--pair`, `--all` |
| 3.7 | `tests/test_pipeline.py`, `test_confluences.py` |

**Invariante:** Pipeline determinístico funciona **sem** LLM API key.

---

## Fase 4 — Backtest, guardrails, memória (2–4 semanas)

**Objetivo:** Feedback quantitativo + segurança.

| # | Entregável |
|---|------------|
| 4.1 | `backtest/engine.py` walk-forward |
| 4.2 | `tools/backtest.py` |
| 4.3 | `guardrails/limits.py` (1%/3%/6%) |
| 4.4 | `guardrails/calendar.py` (notícias) |
| 4.5 | `tools/risk.py` |
| 4.6 | `memory/store.py` JSON |
| 4.7 | `data/backtest_golive.json` pipeline |
| 4.8 | `tests/test_guardrails.py`, `test_backtest.py` |

---

## Fase 5 — UI e paper trading (contínuo)

**Objetivo:** Dashboard operacional + simulação.

| # | Entregável |
|---|------------|
| 5.1 | Streamlit `ui/app.py` (abas) |
| 5.2 | `paper/store.py` + `paper/alerts.py` |
| 5.3 | `ui/charts.py` multi-TF |
| 5.4 | Modo `paper` no pipeline |
| 5.5 | `ui/auth.py` produção |
| 5.6 | Mem0 opcional |
| 5.7 | CI GitHub Actions completo |

---

## Fase 6 — Observabilidade (contínuo)

**Objetivo:** Tracing, métricas, alertas.

| # | Entregável |
|---|------------|
| 6.1 | `observability/langsmith.py` |
| 6.2 | `audit/logger.py` JSONL |
| 6.3 | `metrics/collector.py` |
| 6.4 | `alerts/dispatcher.py` + payloads |
| 6.5 | Auto-refresh UI (`ui/production.py`) |
| 6.6 | `scripts/doc_garden.py` CI |

---

## Fase 7 — Live gate (contínuo)

**Objetivo:** Live trading só com aprovação humana.

| # | Entregável |
|---|------------|
| 7.1 | `guardrails/live_gate.py` (duplo: .env + token) |
| 7.2 | `broker/executor.py` stub + ccxt |
| 7.3 | `ops/golive.py` checklist semáforo |
| 7.4 | `docs/design-docs/go-live-checklist.md` |
| 7.5 | `ui/live_ops_panel.py` |
| 7.6 | `guardrails/token_rotation.py` |

**Regra inegociável:** `live` bloqueado sem checklist + assinaturas.

---

## Fase 8 — Produção (contínuo)

**Objetivo:** Deploy, scan agendado, webhooks.

| # | Entregável |
|---|------------|
| 8.1 | `Dockerfile` + `docker-compose.yml` |
| 8.2 | Deploy EasyPanel / VPS |
| 8.3 | `alerts/webhooks.py` n8n + Telegram |
| 8.4 | `scripts/scheduled-scan.ps1` |
| 8.5 | `scripts/register-scheduled-task.ps1` |
| 8.6 | `.github/workflows/deploy.yml` |
| 8.7 | `docs/deploy-easypanel-github.md` |

---

## Matriz de dependências

```
Fase 0 ──► Fase 1 ──► Fase 2 ──► Fase 3 ──► Fase 4
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
                 Fase 5            Fase 6            Fase 7 ──► Fase 8
```

Fases 5–7 podem avançar em paralelo após Fase 4 estável.