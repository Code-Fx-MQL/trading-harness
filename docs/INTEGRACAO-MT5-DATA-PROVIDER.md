# Integração MT5 Data Provider — Harness na nuvem + dados live no Windows

> **Versão:** 1.0 · **Data:** 2026-07-11  
> **Produção validada:** CRT Agent + `mt5.fullscopetrade.com`

Este documento descreve como um **harness na nuvem** (Docker / EasyPanel) consome candles **live** de um PC Windows com MetaTrader 5, via o serviço independente [MT5 Data Provider](https://github.com/Code-Fx-MQL/mt5-data-provider).

A estratégia (CRT, ORB, SMC, …) **não muda** — só a fonte de dados em `fetch_multi_tf_data`.

---

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────┐
│  PC Windows (MT5 + provider)                                             │
│  ┌──────────────┐    ┌─────────────────────┐    ┌──────────────────┐   │
│  │ terminal64   │───►│ mt5-data-provider   │───►│ cloudflared      │   │
│  │ (minimizado) │    │ http://127.0.0.1:8000│    │ tunel HTTPS      │   │
│  └──────────────┘    └─────────────────────┘    └────────┬─────────┘   │
│         ▲                      ▲                          │             │
│         │ watchdog-mt5.ps1     │ watchdog (2 min)          │             │
└─────────┼──────────────────────┼──────────────────────────┼─────────────┘
          │                      │                          │
          │                      │         Internet         │
          │                      │                          ▼
┌─────────┴──────────────────────┴─────────────────────────────────────────┐
│  Nuvem (EasyPanel / Docker)                                              │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Harness (ex. crt-agent)                                           │  │
│  │  CRT_DATA_SOURCE=mt5                                               │  │
│  │  MT5_PROVIDER_URL=https://mt5.fullscopetrade.com                   │  │
│  │  MT5_PROVIDER_API_KEY=<secret harness-crt>                         │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

**Repositórios:**

| Repo | Papel |
|------|-------|
| [mt5-data-provider](https://github.com/Code-Fx-MQL/mt5-data-provider) | API HTTP, MT5 live, túnel Cloudflare, watchdogs Windows |
| [crt-agent](https://github.com/Code-Fx-MQL/crt-agent) | Harness CRT em produção (referência) |
| [trading-harness](https://github.com/Code-Fx-MQL/trading-harness) | Blueprint genérico (este doc) |

---

## Variáveis no harness (nuvem)

No EasyPanel / `.env.production` do agente (exemplo CRT):

```env
CRT_DATA_SOURCE=mt5
MT5_PROVIDER_URL=https://mt5.fullscopetrade.com
MT5_PROVIDER_API_KEY=SUA_SECRET
MT5_PROVIDER_TIMEOUT_MS=60000
CRT_PAIRS=GBPUSD,USDCAD,EURUSD,...
```

| Variável | Obrigatório | Notas |
|----------|-------------|-------|
| `{STRATEGY}_DATA_SOURCE` | Sim | `mt5` em produção live; `stub` em CI |
| `MT5_PROVIDER_URL` | Sim (modo mt5) | URL **pública** HTTPS — nunca `localhost` na nuvem |
| `MT5_PROVIDER_API_KEY` | Sim | Secret do par `harness-id:secret` no provider |
| `MT5_PROVIDER_TIMEOUT_MS` | Recomendado | `60000` para backtests / histórico longo |
| `{STRATEGY}_PAIRS` | Sim | Pares que o harness analisa — devem existir no MT5 |

**Multi-harness:** no PC Windows (`mt5-data-provider/.env`):

```env
MT5_API_KEYS=harness-crt:SECRET_CRT,harness-orb:SECRET_ORB
```

Cada harness usa a sua secret no header `X-API-Key`.

---

## Variáveis no PC Windows (provider)

Ver documentação completa em [mt5-data-provider/docs/MIGRACAO-WINDOWS.md](https://github.com/Code-Fx-MQL/mt5-data-provider/blob/main/docs/MIGRACAO-WINDOWS.md).

Resumo:

```env
MT5_PROVIDER_MODE=live
MT5_PATH=C:\MT5\Instances\...\terminal64.exe
MT5_API_KEYS=harness-crt:SUA_SECRET
MT5_SYMBOLS=XAUUSD:GOLD,GBPUSD:GBPUSD,US30:US30Cash,...
MT5_START_MINIMIZED=true
```

| Script | Função |
|--------|--------|
| `bootstrap-windows.ps1` | Setup completo na máquina nova |
| `watchdog-mt5.ps1` | Mantém terminal MT5 + API `:8000` |
| `watchdog-cloudflare.ps1` | Mantém túnel HTTPS (sem janelas visíveis) |
| `fix-cloudflared-config.ps1` | Corrige paths de credenciais após migração |
| `show-mt5-window.ps1` | Restaura janela MT5 se estiver minimizada |
| `install-all-tasks.ps1` | Tarefas agendadas (watchdog 2 min) |

---

## Checklist de produção (validado 2026-07-11)

### MT5 Data Provider (Windows)

- [ ] `https://mt5.fullscopetrade.com/health` → HTTP 200, `"mode":"live"`
- [ ] `curl -H "X-API-Key: SECRET" https://mt5.fullscopetrade.com/v1/ticker/GBPUSD` → `"source":"mt5"`
- [ ] `watchdog-cloudflare.ps1 -StatusOnly` → `cloudflared: 1, provider:OK, publico: OK`
- [ ] `watchdog-mt5.ps1` → `Provider API: OK (live)`, `Dados MT5: OK`
- [ ] Após migração: `fix-cloudflared-config.ps1` (paths `credentials-file` no `config.yml`)

### Harness CRT (EasyPanel)

- [ ] `CRT_DATA_SOURCE=mt5`
- [ ] `MT5_PROVIDER_URL=https://mt5.fullscopetrade.com`
- [ ] `MT5_PROVIDER_API_KEY` = secret de `harness-crt` no provider
- [ ] Reiniciar serviço após alterar env (`update-easypanel-env.py` ou painel)
- [ ] App online: `https://crt.fullscopetrade.com` → HTTP 200

### Integração harness ↔ provider

- [ ] `python scripts/test-mt5-live.py` (no repo crt-agent) — pares activos com `source=mt5`
- [ ] Pipeline: `run_pair_analysis("GBPUSD")` → `data_source=mt5`
- [ ] UI: aba Gráfico carrega candles live

---

## Mapeamento de símbolos (crítico)

Brokers MT5 usam nomes diferentes (`GOLD` vs `XAUUSD`, `US30Cash` vs `US30`). O harness pede sempre o **código lógico** (ex. `XAUUSD`); o provider traduz via `MT5_SYMBOLS`:

```env
MT5_SYMBOLS=XAUUSD:GOLD,US30:US30Cash,US100:US100Cash,NAS100:US100Cash,GER40:GER40Cash
```

**Sintoma:** harness recebe HTTP 404 `SymbolNotFoundError` — o par está em `CRT_PAIRS` mas não existe no Market Watch / broker.

**Correcção:**

1. Abrir MT5 → Market Watch → anotar nome exacto do símbolo
2. Actualizar `MT5_SYMBOLS` no `.env` do provider
3. `.\scripts\watchdog-mt5.ps1`
4. Validar: `curl -H "X-API-Key: SECRET" https://mt5.fullscopetrade.com/v1/ticker/XAUUSD`

---

## Sincronizar API key (provider + nuvem)

No repo **crt-agent**:

```powershell
python scripts\sync-mt5-api-key.py
```

Alinha `MT5_API_KEYS` (Windows), `.env` local e EasyPanel. Depois reiniciar o serviço na nuvem.

Alternativa manual:

```powershell
python scripts\update-easypanel-env.py
```

---

## Testes rápidos

```powershell
# Provider público
curl https://mt5.fullscopetrade.com/health

# Auth + dados
curl -H "X-API-Key: SECRET" https://mt5.fullscopetrade.com/v1/ticker/GBPUSD
curl -H "X-API-Key: SECRET" "https://mt5.fullscopetrade.com/v1/ohlcv/GBPUSD/multi?timeframes=4h,1h,15m&limit=5"

# Harness (crt-agent)
python scripts\test-mt5-live.py
```

---

## Implementar MT5 noutro harness (não-CRT)

1. Copiar padrão do CRT: `src/{agent}/providers/mt5_provider.py`
2. Em `tools/data.py`, modo `mt5` antes do fallback CCXT:

```python
if mode == "mt5":
    return _fetch_mt5(pair, timeframes)
```

3. Settings: `mt5_provider_url`, `mt5_provider_api_key`, `{strategy}_data_source`
4. Testes: `tests/test_mt5_provider.py` com mocks; integration opcional
5. CI: manter `{STRATEGY}_DATA_SOURCE=stub` — não depender de MT5 no GitHub Actions

---

## Troubleshooting

| Problema | Causa | Solução |
|----------|-------|---------|
| `publico: FALHA` no watchdog | Credenciais Cloudflare com path da máquina antiga | `fix-cloudflared-config.ps1` |
| Health 502 público | Provider `:8000` offline | `watchdog-mt5.ps1` |
| `cloudflared: 0` processos | Credenciais em falta / path errado | Ver `logs/cloudflared.err.log` |
| Janelas PowerShell a piscar | Tarefas sem `-WindowStyle Hidden` | `git pull` + `install-all-tasks.ps1` |
| MT5 “invisível” | Arranque minimizado | `show-mt5-window.ps1` ou `MT5_START_MINIMIZED=false` |
| Harness 401 | API key diferente | `sync-mt5-api-key.py` |
| Harness 404 SymbolNotFound | Símbolo não no broker | Ajustar `MT5_SYMBOLS` |
| Nuvem não alcança MT5 | `MT5_PROVIDER_URL=localhost` | Usar URL pública HTTPS |

---

## Referências

- [mt5-data-provider — API](https://github.com/Code-Fx-MQL/mt5-data-provider/blob/main/docs/API.md)
- [mt5-data-provider — Migração Windows](https://github.com/Code-Fx-MQL/mt5-data-provider/blob/main/docs/MIGRACAO-WINDOWS.md)
- [crt-agent — Deploy EasyPanel](https://github.com/Code-Fx-MQL/crt-agent/blob/master/docs/deploy-easypanel-github.md)
- [crt-agent — ENV-VARIABLES](https://github.com/Code-Fx-MQL/crt-agent/blob/master/deploy/easypanel/ENV-VARIABLES.md)