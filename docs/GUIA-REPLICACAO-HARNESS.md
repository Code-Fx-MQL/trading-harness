# Guia completo — Replicar o Harness Engineering para qualquer estratégia

> **Versão:** 1.0 · **Data:** 2026-07-09  
> **Referência:** [Agente CRT](https://github.com/Code-Fx-MQL/crt-agent) — implementação de referência Fases 0–8

---

## Sumário

1. [O que é o Harness](#1-o-que-é-o-harness)
2. [Arquitetura em camadas](#2-arquitetura-em-camadas)
3. [Princípios inegociáveis](#3-princípios-inegociáveis)
4. [Passo a passo — do zero ao produção](#4-passo-a-passo--do-zero-ao-produção)
5. [Implementar a estratégia (domínio)](#5-implementar-a-estratégia-domínio)
6. [Pipeline determinístico](#6-pipeline-determinístico)
7. [Tools — contratos e registry](#7-tools--contratos-e-registry)
8. [Guardrails e modos de operação](#8-guardrails-e-modos-de-operação)
9. [Memória, backtest e feedback](#9-memória-backtest-e-feedback)
10. [Paper trading e live gate](#10-paper-trading-e-live-gate)
11. [Observabilidade e audit](#11-observabilidade-e-audit)
12. [UI, ops e alertas](#12-ui-ops-e-alertas)
13. [CI/CD e deploy](#13-cicd-e-deploy)
14. [Sistema de documentação](#14-sistema-de-documentação)
15. [Testes e qualidade](#15-testes-e-qualidade)
16. [Checklist final de replicação](#16-checklist-final-de-replicação)

Documentos complementares nesta pasta:

- [ESTRUTURA-REPOSITORIO.md](./ESTRUTURA-REPOSITORIO.md)
- [MAPEAMENTO-ESTRATEGIA.md](./MAPEAMENTO-ESTRATEGIA.md)
- [FASES-0-8.md](./FASES-0-8.md)

---

## 1. O que é o Harness

### Definição

Um **harness** é a infraestrutura que envolve o agente (LLM + código determinístico) para torná-lo:

- **Confiável** — testes, contratos tipados, pipeline reproduzível
- **Seguro** — guardrails de risco, live gate, audit log
- **Operável** — dashboard, alertas, deploy, scan agendado
- **Evolutivo** — docs versionadas, planos de execução, tech debt tracker

### O que NÃO é o harness

| É harness | Não é harness (domínio) |
|-----------|-------------------------|
| Risk limits 1%/3%/6% | Regra "sweep abaixo do range 4H" |
| Audit log JSONL | Detecção de 3 velas CRT |
| Paper trading store | Cálculo de entry no FVG |
| Live gate duplo | Killzone London 08–11 UTC |
| Webhook n8n | Confluência order block |

### Separação estratégia × harness

Ao replicar para outra estratégia, **copie o harness inteiro** e substitua apenas:

```
config/{strategy}_rules.py
tools/{strategy}.py
analysis/*          (se necessário)
docs/design-docs/{strategy}-strategy.md
tests/test_{strategy}*
```

Todo o resto (`guardrails/`, `paper/`, `audit/`, `ops/`, `ui/production.py`, `alerts/`) permanece igual ou com renomeação mínima de prefixos env.

---

## 2. Arquitetura em camadas

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

### Fluxo de dados (request → response)

```
CLI/UI/Scan agendado
       │
       ▼
run_pair_analysis(pair)
       │
       ├─► fetch_multi_tf_data ──► providers/ccxt
       ├─► detect_{strategy}_setup ──► {strategy}_rules
       ├─► analyze_confluences ──► analysis/
       ├─► calculate_trade_params ──► models/schemas
       ├─► check_risk_limits ──► guardrails/
       ├─► run_backtest ──► backtest/engine
       ├─► memory.log_setup ──► data/memory/
       ├─► paper|broker ──► conforme MODE
       ├─► audit.log ──► data/audit/
       └─► explain + webhooks ──► alerts/
```

---

## 3. Princípios inegociáveis

Extraídos de `docs/design-docs/core-beliefs.md` — aplicam-se a **qualquer** estratégia:

| # | Princípio | Implementação |
|---|-----------|---------------|
| 1 | Humans steer, agents execute | Live gate, checklist go-live |
| 2 | Repositório = fonte de verdade | Tudo em `docs/`, nunca só no chat |
| 3 | AGENTS.md é mapa, não manual | ≤ 150 linhas, links para docs |
| 4 | Falha = capacidade faltando | Adicionar tool/doc/test, não "retry" |
| 5 | Parse na fronteira | Pydantic em `models/schemas.py` |
| 6 | Pipeline determinístico primeiro | Funciona sem LLM API key |
| 7 | Modo default `analysis` | Zero execução real por defeito |
| 8 | Feedback loops = produto | CI + audit + métricas + paper |
| 9 | Progressive disclosure | Agente lê AGENTS.md → plano ativo → código |
| 10 | GC contínua | tech-debt-tracker.md atualizado |

---

## 4. Passo a passo — do zero ao produção

### Etapa A — Criar o repositório (Dia 1–2)

```powershell
# 1. Estrutura base
mkdir my-strategy-agent
cd my-strategy-agent
git init

# 2. Copiar scaffold do blueprint
#    Ver ESTRUTURA-REPOSITORIO.md — copiar pastas docs/, scripts/, tests/

# 3. pyproject.toml — alterar name, scripts, packages
#    name = "smc-agent"
#    packages = ["src/smc_agent"]

# 4. Bootstrap Python
.\scripts\setup.ps1
```

**Checklist Etapa A:**
- [ ] `AGENTS.md` criado com mapa
- [ ] `validate.ps1` passa estrutura mínima
- [ ] `pytest` smoke verde

### Etapa B — Documentar a estratégia (Semana 1)

1. Entrevista com trader: regras, TF, pares, SL/TP, sessões
2. Escrever `docs/design-docs/{strategy}-strategy.md`
3. Preencher [MAPEAMENTO-ESTRATEGIA.md](./MAPEAMENTO-ESTRATEGIA.md)
4. Criar `docs/product-specs/agente-{strategy}.md` com critérios aceite MVP
5. Definir `config/{strategy}_rules.py` (enums, thresholds)

**Gate:** Revisor humano valida regras antes de Fase 3.

### Etapa C — Dados OHLCV (Semana 2)

1. Implementar `providers/ccxt_provider.py`
2. Mapear pares em `providers/symbols.py`
3. Tool `fetch_multi_tf_data` com modos stub/ccxt/auto
4. Testes integration marcados `@pytest.mark.integration`

```python
# tools/data.py — padrão
@tool
def fetch_multi_tf_data(pair: str, timeframes: list[str], source: str = "auto") -> dict:
    """Retorna { pair, source, exchange, timeframes: { tf: [candles] } }"""
```

### Etapa D — Detector de setup (Semanas 3–5)

1. Funções puras em `{strategy}_rules.py` (testáveis)
2. `detect_{strategy}_setup` em `tools/{strategy}.py`
3. Testes com candles sintéticos (bullish + bearish + no setup)
4. Integrar em `pipeline/analyze.py`

### Etapa E — Trade params + risco (Semana 5–6)

1. `calculate_trade_params` — entry, SL, TP, sizing
2. `check_risk_limits` — integra RiskTracker
3. Guardrail notícias se `BLOCK_NEWS=true`

### Etapa F — Backtest + memória (Semanas 7–9)

1. Engine walk-forward em `backtest/engine.py`
2. `memory/store.py` — log setups e outcomes
3. Gerar `data/backtest_golive.json` para checklist

### Etapa G — UI + paper (Semanas 10–12)

1. Streamlit com abas: Análise, Gráfico, Métricas, Paper, Live Ops
2. Modo `paper` abre posições em JSON
3. Alertas SL/TP em `paper/alerts.py`

### Etapa H — Produção (Semanas 13+)

1. Docker + deploy VPS/EasyPanel
2. Webhooks n8n/Telegram
3. Scan agendado (cron / Task Scheduler)
4. GitHub Actions deploy

Ver [FASES-0-8.md](./FASES-0-8.md) para entregáveis detalhados por fase.

---

## 5. Implementar a estratégia (domínio)

### 5.1 Codificar regras (`config/{strategy}_rules.py`)

Padrão CRT:

```python
from enum import Enum

class SweepMode(str, Enum):
    CONSERVATIVE = "conservative"
    WYCKOFF = "wyckoff"

class ReplicationMode(str, Enum):
    STRICT = "strict"
    CALIBRATED = "calibrated"

# Constantes numéricas com nomes explícitos
MIN_CONFLUENCE_COUNT = 8
HTF_LOOKBACK = 48
```

**Para sua estratégia:** extraia todos os thresholds para este ficheiro. Zero magic numbers em `tools/`.

### 5.2 Top-down multi-timeframe

Padrão universal (adaptar TF):

| Papel | CRT | Genérico |
|-------|-----|----------|
| HTF | 4H — bias + range | Contexto macro |
| MTF | 1H — replica estrutura HTF | Confirmação estrutural |
| LTF | 15m — entrada | Timing + trigger |

```python
# settings.py
default_htf: str = "4h"
default_mtf: str = "1h"
default_ltf: str = "15m"
```

### 5.3 Detector (`tools/{strategy}.py`)

Estrutura recomendada:

```python
@tool
def detect_{strategy}_setup(
    pair: str,
    htf_candles: list,
    mtf_candles: list,
    ltf_candles: list,
    htf_timeframe: str,
    mtf_timeframe: str,
    ltf_timeframe: str,
    **strategy_params,
) -> dict:
    # 1. Validar candles suficientes
    # 2. HTF: estrutura principal (range, trend, zone)
    # 3. MTF: confirmação / replicação
    # 4. LTF: trigger de entrada
    # 5. Montar setup dict + confidence
    return {"found": bool, "reason": str|None, "setup": dict|None}
```

### 5.4 Confluências (`analysis/confluences.py`)

Opcional mas recomendado para filtrar qualidade:

```python
def analyze_all_confluences(setup, htf, mtf, ltf, **signals) -> dict:
    return {
        "confluences": list[str],
        "strength": "weak"|"moderate"|"strong",
        "confidence_boost": float,
        "details": dict,
    }

def passes_confluence_filter(conf, settings) -> tuple[bool, str]:
    ...
```

Filtros configuráveis via `.env`:

```
{STRATEGY}_CONFLUENCE_FILTER=true
{STRATEGY}_MIN_CONFLUENCE_STRENGTH=strong
{STRATEGY}_REQUIRE_KILLZONE=true
```

### 5.5 Explicação (`tools/explain.py`)

Gera markdown em português (ou idioma do utilizador) com:

- Resumo do setup
- Parâmetros de trade
- Confluências
- Resultado backtest recente
- Avisos de risco

**Importante:** explicação é output do harness, não substitui validação humana.

---

## 6. Pipeline determinístico

Ficheiro central: `pipeline/analyze.py`

### Por que determinístico primeiro?

- Testes reproduzíveis sem mock de LLM
- Scan agendado confiável em produção
- Latência previsível (~1 min / 12 pares)
- LLM opcional via `agent/graph.py` para exploração

### Pseudocódigo completo

```python
def run_pair_analysis(pair: str) -> dict:
    configure_tracing()
    pair = pair.upper()
    tfs = [settings.default_htf, settings.default_mtf, settings.default_ltf]

    data = fetch_multi_tf_data.invoke({"pair": pair, "timeframes": tfs})
    detection = detect_{strategy}_setup.invoke({...candles...})

    result = base_result(pair, data)

    if not detection["found"]:
        result["paper_alerts"] = check_paper_alerts(pair)
        audit.log("analysis_no_setup", {...})
        return result

    conf = analyze_all_confluences(...)
    if not passes_confluence_filter(conf):
        audit.log("setup_filtered", {...})
        return filtered_result(...)

    trade = calculate_trade_params.invoke({"setup": setup})
    if not trade.get("valid", True):
        return rejected_trade_result(...)

    risk = check_risk_limits.invoke({...})

    backtest = run_{strategy}_backtest.invoke({"pair": pair})
    setup_id = memory.log_setup(...)

    if mode == PAPER:
        paper.open_position(...)
    elif mode == LIVE and risk.approved:
        broker.place_order(...)

    audit.log("setup_detected", {...})
    result["explanation"] = explain_setup_detalhado.invoke({...})

    if settings.webhook_enabled:
        notify_setup_found(pair, result)

    result["paper_alerts"] = check_paper_alerts(pair)
    return result
```

### Decorator tracing

```python
from observability.langsmith import traced

@traced(name="{strategy}_pair_analysis", run_type="chain")
def run_pair_analysis(pair: str) -> dict:
    ...
```

---

## 7. Tools — contratos e registry

### Lista mínima de 8 tools

| Tool | Responsabilidade | Estratégia-específica? |
|------|------------------|------------------------|
| `fetch_multi_tf_data` | OHLCV | Não |
| `detect_{strategy}_setup` | Sinal | **Sim** |
| `identify_confluences` | Lista confluências | Parcial |
| `calculate_trade_params` | Entry/SL/TP/size | Parcial |
| `run_{strategy}_backtest` | Histórico | Parcial |
| `explain_setup_detalhado` | Narrativa | Parcial |
| `check_risk_limits` | Guardrails | Não |
| `log_trade_outcome` | Memória | Não |

Tools adicionais produção: `analyze_pair`, `analyze_all_primary_pairs`, `execute_crt_order`, `check_paper_trading_alerts`.

### Registry (evitar import circular)

```python
# tools/registry.py
def get_all_tools() -> list:
    from crt_agent.tools.data import fetch_multi_tf_data
    # imports lazy...
    return [fetch_multi_tf_data, detect_crt_setup, ...]
```

### Schemas Pydantic (`models/schemas.py`)

Defina no mínimo:

- `{Strategy}Setup` — campos do setup detectado
- `TradeParams` — entry, sl, tp, rr, size
- `RiskCheckResult` — approved, reason
- `BacktestResult` — wr, pf, drawdown

**Parse-at-boundary:** tools retornam dict; schemas validam na fronteira quando necessário.

---

## 8. Guardrails e modos de operação

### settings.py (pydantic-settings)

```python
class OperationMode(str, Enum):
    ANALYSIS = "analysis"
    PAPER = "paper"
    LIVE = "live"

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    {strategy}_mode: OperationMode = OperationMode.ANALYSIS
    {strategy}_max_risk_per_trade: float = 0.01
    {strategy}_max_daily_risk: float = 0.03
    {strategy}_max_weekly_risk: float = 0.06
    {strategy}_block_news: bool = True
```

### RiskTracker (`guardrails/limits.py`)

- Acumula risco diário/semanal
- `can_take_trade(risk_percent)` → bool
- Persistência opcional em JSON

### Calendário econômico (`guardrails/calendar.py`)

- Cache `data/cache/economic_calendar.json`
- Bloqueia trades X minutos antes/depois de eventos high-impact

### Live gate (`guardrails/live_gate.py`)

Dupla aprovação:

1. `{STRATEGY}_LIVE_APPROVED=true` no `.env` (humano edita)
2. `{STRATEGY}_LIVE_APPROVAL_TOKEN` + token de sessão CLI/UI

```python
def live_gate_status() -> dict:
    return {
        "mode": settings.mode,
        "approved_env": settings.live_approved,
        "token_configured": bool(settings.live_approval_token),
        "allowed": ...,
        "reason": "...",
    }
```

---

## 9. Memória, backtest e feedback

### Memória (`memory/store.py`)

JSON `data/memory/trade_memory.json`:

```json
{
  "entries": [
    {
      "id": "abc123",
      "pair": "XAUUSD",
      "direction": "bullish",
      "confidence": 0.82,
      "trade_params": {...},
      "outcome": "win",
      "logged_at": "..."
    }
  ]
}
```

API mínima: `log_setup()`, `log_outcome()`, `summary()`, `search_local()`.

### Backtest (`backtest/engine.py`)

Walk-forward sobre OHLCV histórico:

1. Iterar candles LTF
2. Em cada janela, correr detector (sem lookahead)
3. Simular SL/TP
4. Agregar WR, PF, max DD

Output go-live: `data/backtest_golive.json` com KPIs por par.

### Métricas (`metrics/collector.py`)

Consolida:

- Memory WR por par
- Paper WR + drawdown
- Audit event counts
- KPIs para dashboard e checklist

---

## 10. Paper trading e live gate

### Paper store (`paper/store.py`)

```python
def open_position(pair, trade_params, setup_id) -> dict
def check_exits(pair, current_price) -> list  # SL/TP hits
def summary() -> dict
```

Posições em `data/memory/paper_trades.json`.  
**Defensivo:** ignorar posições sem SL/TP/entry em `check_exits`.

### Paper alerts (`paper/alerts.py`)

No fim de cada `run_pair_analysis`:

```python
check_paper_alerts(pair)  # fetch preço LTF → check_exits → webhook
```

### Transição paper → live

| Requisito | Meta CRT |
|-----------|----------|
| Paper sem erros | ≥ 14 dias |
| Backtest WR | ≥ 55% |
| Backtest PF | ≥ 1.0 |
| Trades amostra | ≥ 20 |
| Testes CI | 100% unitários |
| Assinaturas humanas | Trader + revisor |

Checklist automatizado: `ops/golive.py` → `get_golive_checklist()`.

---

## 11. Observabilidade e audit

### Audit log (`audit/logger.py`)

Append-only JSONL `data/audit/trade_audit.jsonl`:

```json
{"ts":"...","event":"setup_detected","pair":"XAUUSD","direction":"bullish","mode":"paper"}
{"ts":"...","event":"risk_check","approved":true,"risk_percent":0.01}
{"ts":"...","event":"live_blocked","reason":"token ausente"}
```

Eventos padrão: `analysis_no_setup`, `setup_filtered`, `setup_detected`, `paper_open`, `live_order_stub`, `live_blocked`.

### LangSmith (opcional)

```python
# observability/langsmith.py
def configure_tracing():
    if settings.langsmith_tracing and settings.langsmith_api_key:
        os.environ["LANGCHAIN_TRACING_V2"] = "true"
```

### structlog

Logging estruturado em providers e pipeline:

```python
logger.info("fetch_ohlcv", exchange="kraken", pair=pair, timeframe=tf)
```

---

## 12. UI, ops e alertas

### Abas Streamlit recomendadas

| Aba | Função |
|-----|--------|
| Live Ops | Checklist, gate, scan manual, testes webhook |
| Análise | 1 par manual |
| Gráfico | OHLCV + overlay setup |
| Todos | Scan lote |
| Backtest | UI backtest por par |
| Pares | Registry dinâmico |
| Métricas | KPIs |
| Memória | Histórico setups |
| Paper | Posições + alertas |

### Auto-refresh (`ui/production.py`)

- Fragment Streamlit `run_every=5min`
- Atualiza métricas + paper alerts
- **Não** dispara análise CRT automaticamente (scan é separado)

### Alertas (`alerts/`)

| Canal | Ficheiro | Eventos |
|-------|----------|---------|
| n8n webhook | `webhooks.py` | setup_found, scan_complete, paper_alert |
| Telegram | `telegram_messages.py` | paralelo ao n8n |
| Payloads | `payloads.py` | schema uniforme com `app_id` |

```python
# payloads.py — identificar origem no n8n
{"app_id": "crt-agent", "event": "setup_found", "pair": "...", "data": {...}}
```

### Scan agendado

Fora do dashboard:

```powershell
.\scripts\scheduled-scan.ps1          # Python: analyze_all + webhooks + paper alerts
.\scripts\register-scheduled-task.ps1 # Windows Task Scheduler
```

---

## 13. CI/CD e deploy

### CI (`.github/workflows/ci.yml`)

Jobs:

1. **lint** — `ruff check`
2. **test** — `pytest -m "not integration"` com `DATA_SOURCE=stub`
3. **validate** — estrutura harness + `doc_garden.py`
4. **integration** — CCXT real (continue-on-error)

### Deploy (`.github/workflows/deploy.yml`)

1. Testes
2. `generate_env_production.py` — secrets → `.env.production`
3. `build_easypanel_zip.py`
4. `upload-easypanel-api.py`

Secrets GitHub: ver `docs/deploy-easypanel-github.md`.

### Docker

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY pyproject.toml README.md ./
COPY src/ src/
RUN pip install -e ".[ui]"
COPY docker-entrypoint.sh /
EXPOSE 8501
HEALTHCHECK CMD curl -f http://localhost:8501/_stcore/health
ENTRYPOINT ["/docker-entrypoint.sh"]
```

Volume obrigatório: `/app/data` para paper, memória, audit.

---

## 14. Sistema de documentação

### Hierarquia

```
AGENTS.md              → mapa (agente IA começa aqui)
docs/PLANO.md          → status fases
docs/exec-plans/active/→ plano corrente (máx. 1)
docs/design-docs/      → regras, crenças, checklists
docs/product-specs/    → spec funcional
docs/ESTADO_ATUAL.md   → snapshot operacional
trading-harness/docs/ → este guia replicável
```

### Exec plans

- `active/` — 0 ou 1 plano em curso
- `completed/` — histórico por fase
- `tech-debt-tracker.md` — dívidas com severidade

### Doc gardening (CI)

`scripts/doc_garden.py` valida links e estrutura mínima.

### AGENTS.md — template

```markdown
# AGENTS.md — Mapa do Repositório

## Missão
Agente {STRATEGY} com Harness Engineering.

## Onde começar
| Tarefa | Arquivo |
| Plano ativo | docs/exec-plans/active/... |
| Regras | docs/design-docs/{strategy}-strategy.md |
| Harness blueprint | trading-harness/docs/ |

## Comandos
{strategy}-agent --pair XAUUSD
pytest
.\scripts\validate.ps1

## Regras inegociáveis
- Modo default analysis
- Live bloqueado sem gate
- Top-down: {HTF} → {MTF} → {LTF}
```

---

## 15. Testes e qualidade

### Pirâmide de testes

```
        ┌─────────────┐
        │ Integration │  CCXT rede (opcional CI)
        ├─────────────┤
        │  Pipeline   │  run_pair_analysis stub
        ├─────────────┤
        │  Domínio    │  rules, detector, confluences
        ├─────────────┤
        │   Smoke     │  settings, imports, tools
        └─────────────┘
```

### conftest.py — isolamento

```python
@pytest.fixture(autouse=True)
def reset_store_singletons():
    paper_mod._paper = None
    memory_mod._memory = None
    yield
    paper_mod._paper = None
    memory_mod._memory = None
```

### Teste pipeline padrão

```python
def test_analyze_pair_stub(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "data_source", "stub")
    monkeypatch.setattr(settings, "mode", OperationMode.ANALYSIS)
    monkeypatch.setattr(settings, "memory_dir", str(tmp_path / "mem"))
    monkeypatch.setattr(settings, "webhook_enabled", False)
    result = analyze_pair.invoke({"pair": "XAUUSD"})
    assert result["pair"] == "XAUUSD"
```

### QUALITY_SCORE.md

Manter grades por domínio: harness, tools, guardrails, tests, ui, ops.

---

## 16. Checklist final de replicação

### Documentação
- [ ] `docs/design-docs/{strategy}-strategy.md` completo
- [ ] `MAPEAMENTO-ESTRATEGIA.md` preenchido
- [ ] `AGENTS.md` ≤ 150 linhas
- [ ] Plano ativo em `exec-plans/active/`
- [ ] Tech debt tracker inicializado

### Código core
- [ ] `detect_{strategy}_setup` com testes stub
- [ ] `pipeline/analyze.py` determinístico
- [ ] 8+ tools no registry
- [ ] Schemas Pydantic definidos
- [ ] `settings.py` com modos e guardrails

### Segurança
- [ ] Modo default `analysis`
- [ ] Live gate duplo implementado
- [ ] Audit log ativo
- [ ] Sem secrets no git

### Operação
- [ ] CLI `{strategy}-agent` funcional
- [ ] Dashboard Streamlit (opcional Fase 5)
- [ ] Paper trading validado
- [ ] Webhooks configurados
- [ ] Scan agendado documentado

### Qualidade
- [ ] `pytest -m "not integration"` verde
- [ ] CI GitHub Actions verde
- [ ] `validate.ps1` verde
- [ ] Backtest go-live com KPIs

### Produção
- [ ] Docker build OK
- [ ] Health check `/_stcore/health`
- [ ] Deploy documentado
- [ ] Checklist go-live com semáforo

---

## Apêndice A — Renomear CRT → nova estratégia

| De (CRT) | Para (ex. SMC) |
|----------|----------------|
| `crt_agent` | `smc_agent` |
| `CRT_` env prefix | `SMC_` |
| `crt_rules.py` | `smc_rules.py` |
| `detect_crt_setup` | `detect_smc_setup` |
| `run_crt_backtest` | `run_smc_backtest` |
| `crt-agent` CLI | `smc-agent` |
| `app_id` webhook | `smc-agent` |

Script sugerido: buscar/substituir com revisão manual em `docs/` e `tests/`.

## Apêndice B — Referência CRT

| Componente | Path |
|------------|------|
| Pipeline | `src/crt_agent/pipeline/analyze.py` |
| Detector | `src/crt_agent/tools/crt.py` |
| Regras | `src/crt_agent/config/crt_rules.py` |
| Confluências | `src/crt_agent/analysis/confluences.py` |
| Go-live | `src/crt_agent/ops/golive.py` |
| UI | `src/crt_agent/ui/app.py` |
| Validate | `scripts/validate.ps1` |

## Apêndice C — Maturidade harness (L0–L5)

| Nível | Critério |
|-------|----------|
| L0 | Prompts soltos |
| L1 | AGENTS.md + docs + git |
| L2 | Testes + CI |
| L3 | Observability + dados reais |
| L4 | Feature E2E produção |
| L5 | Self-healing + doc garden + eval |

**Agente CRT atual:** L3+ (MVP completo, iterando para L4/L5).

---

*Este documento é o system of record para replicação do harness. Ao criar um novo agente, use `.\scripts\scaffold-strategy.ps1` ou copie os templates de [trading-harness](https://github.com/Code-Fx-MQL/trading-harness).*