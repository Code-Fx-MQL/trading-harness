# Mapeamento — De qualquer estratégia para o Harness

> Use este formulário **antes de escrever código**. Preenche a lacuna entre a estratégia do trader e os módulos do harness.

## 1. Identidade da estratégia

| Campo | CRT (exemplo) | Sua estratégia |
|-------|---------------|----------------|
| Nome | Candle Range Theory | _________________ |
| Sigla env | `CRT_` | `_____` |
| Mercados | Forex + índices | _________________ |
| Timeframes | 4H → 1H → 15m | _________________ |
| Direções | bullish / bearish | _________________ |

## 2. Vocabulário da estratégia → código

Traduza cada conceito da estratégia para um artefato no harness:

| Conceito estratégia | Onde vive no harness | CRT exemplo |
|---------------------|----------------------|-------------|
| Definição formal das regras | `docs/design-docs/{strategy}-strategy.md` | `crt-strategy.md` |
| Parâmetros tunáveis | `config/{strategy}_rules.py` | sweep_mode, replication_mode |
| Condição de setup válido | `tools/{strategy}.py` → `detect_*` | 3 velas + sweep + replicação MTF |
| Filtros qualidade | `analysis/confluences.py` + filter em pipeline | FVG, OB, killzone |
| Entry / SL / TP | `tools/trade.py` | abaixo sweep, extremo range |
| Position sizing | `tools/trade.py` + `guardrails/limits.py` | % risco fixo |
| O que invalida setup | `detect_*` reason string | replicação 1H falhou |
| Explicação humana | `tools/explain.py` | markdown PT |
| KPIs backtest | `backtest/engine.py` + `data/backtest_golive.json` | WR, PF, DD |

## 3. Pipeline universal (independente da estratégia)

Toda estratégia segue o mesmo `pipeline/analyze.py`:

```
1. fetch_multi_tf_data(pair, timeframes)
2. detect_{strategy}_setup(htf, mtf, ltf)     ← ÚNICO bloco específico
3. identify_confluences / analyze_confluences  ← opcional, reutilizável
4. passes_confluence_filter()                  ← opcional
5. calculate_trade_params(setup)
6. check_risk_limits(trade, mode, pair)
7. run_{strategy}_backtest(pair)               ← opcional
8. memory.log_setup()
9. paper.open_position() | broker.place_order()  ← conforme mode
10. audit.log(event)
11. explain_setup_detalhado()
12. notify_setup_found()                       ← webhooks
```

**Regra:** passos 1, 5–12 são **genéricos**. Só o passo 2 (e parcialmente 3–4) mudam por estratégia.

## 4. Contrato `detect_{strategy}_setup`

Input (dict via tool):

```python
{
  "pair": str,
  "htf_candles": list[dict],  # OHLCV normalizado
  "mtf_candles": list[dict],
  "ltf_candles": list[dict],
  "htf_timeframe": str,
  "mtf_timeframe": str,
  "ltf_timeframe": str,
  # parâmetros da estratégia
  "sweep_mode": str,
  "replication_mode": str,
}
```

Output obrigatório:

```python
{
  "found": bool,
  "reason": str | None,       # human-readable se found=False
  "setup": dict | None,       # alinhado com models/schemas Setup
}
```

### Checklist do detector

- [ ] Funciona com `source=stub` (testes sem rede)
- [ ] Funciona com `source=ccxt` (produção)
- [ ] Não depende de API LLM
- [ ] `reason` explica por que não há setup (debug, audit)
- [ ] `confidence` 0.0–1.0 quando `found=True`

## 5. Contrato `calculate_trade_params`

Input: `setup` dict validado  
Output:

```python
{
  "valid": bool,
  "reason": str | None,
  "direction": str,
  "entry": float,
  "stop_loss": float,
  "take_profit": float,
  "risk_reward": float,
  "position_size_lots": float,
  "risk_percent": float,
}
```

## 6. Modos de operação (iguais para todas)

| Modo | Comportamento | Default |
|------|---------------|---------|
| `analysis` | Detecta + explica, não abre posição | ✅ dev |
| `paper` | Abre posição simulada JSON | ✅ validação |
| `live` | Broker real, gate duplo | ❌ bloqueado |

## 7. Exemplos de mapeamento por família de estratégia

### SMC / ICT

| CRT | SMC equivalente |
|-----|-----------------|
| Range 4H | Dealing range / PD array HTF |
| Sweep | Liquidity sweep |
| Replicação 1H | MSS / CHoCH em MTF |
| Entrada 15m | FVG / OB tap LTF |
| Confluências | OTE, killzone, imbalance |

### ORB (Opening Range Breakout)

| CRT | ORB equivalente |
|-----|-----------------|
| Range 4H | Range da primeira hora sessão |
| Sweep | False breakout do range |
| MTF | Confirmação tendência diária |
| LTF | Reteste do boundary ORB |
| Killzone | Só London open / NY open |

### Mean reversion

| CRT | Mean reversion |
|-----|----------------|
| Range | Banda Bollinger / VWAP σ |
| Sweep | Extensão além de N σ |
| Confirmação | Candle reversão LTF |
| TP | Mean / VWAP |

## 8. Documentação mínima da estratégia

Antes da Fase 3, produzir `docs/design-docs/{strategy}-strategy.md` com:

1. Definições (glossário)
2. Algoritmo top-down (diagrama)
3. Parâmetros e defaults
4. Exemplos válidos / inválidos (com screenshots ou OHLCV)
5. KPIs alvo (WR, PF, R:R mínimo)
6. Disclaimer legal

## 9. Testes mínimos da estratégia

| Teste | Ficheiro | O que valida |
|-------|----------|--------------|
| Regras unitárias | `test_{strategy}_rules.py` | Funções puras |
| Detector stub | `test_{strategy}.py` | Candles sintéticos → found True/False |
| Pipeline isolado | `test_pipeline.py` | stub + analysis mode |
| Confluências | `test_confluences.py` | Filtros |
| Guardrails | `test_guardrails.py` | Limites risco |

## 10. Perguntas de validação com o trader

- [ ] As regras no código correspondem ao que você opera manualmente?
- [ ] Os timeframes estão corretos?
- [ ] O SL/TP segue a mesma lógica que você usa?
- [ ] Quais pares são prioritários para go-live?
- [ ] Qual sessão/killzone é obrigatória?
- [ ] Qual WR/PF mínimo no backtest para confiar?