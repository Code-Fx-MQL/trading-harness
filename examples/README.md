# Exemplos de implementação

Repositórios que aplicam o [Trading Harness](../README.md) em estratégias concretas.

## Implementação de referência

### Agente CRT (Candle Range Theory)

| Campo | Valor |
|-------|-------|
| Repositório | [Code-Fx-MQL/crt-agent](https://github.com/Code-Fx-MQL/crt-agent) |
| Estratégia | CRT — top-down 4H → 1H → 15m |
| Maturidade | Fases 0–8 completas (L3+) |
| Destaques | Paper trading, live gate, Docker, webhooks, scan agendado |

**Mapeamento blueprint → código:**

| Blueprint | CRT |
|-----------|-----|
| `detect_{strategy}_setup` | `src/crt_agent/tools/crt.py` |
| `{strategy}_rules` | `src/crt_agent/config/crt_rules.py` |
| `pipeline/analyze.py` | `src/crt_agent/pipeline/analyze.py` |
| `ops/golive.py` | `src/crt_agent/ops/golive.py` |
| Dados live MT5 | `src/crt_agent/providers/mt5_provider.py` |

O CRT também mantém uma cópia local do blueprint em `docs/harness-blueprint/` (sincronizada com este repo).

### Dados live — MT5 Data Provider (produção)

O CRT em produção usa candles **live** do MetaTrader 5 via serviço independente:

| Componente | URL / repo |
|------------|------------|
| Provider (Windows) | [mt5-data-provider](https://github.com/Code-Fx-MQL/mt5-data-provider) em `C:\MT5\mt5-data-provider` |
| API pública | `https://mt5.fullscopetrade.com` |
| Harness na nuvem | `https://crt.fullscopetrade.com` (EasyPanel) |

Env essencial no harness:

```env
CRT_DATA_SOURCE=mt5
MT5_PROVIDER_URL=https://mt5.fullscopetrade.com
MT5_PROVIDER_API_KEY=<secret harness-crt>
```

Documentação completa: [docs/INTEGRACAO-MT5-DATA-PROVIDER.md](../docs/INTEGRACAO-MT5-DATA-PROVIDER.md).

## Exemplo: Agente ORB (Opening Range Breakout)

| Campo | Valor |
|-------|-------|
| Repositório | [Code-Fx-MQL/orb-agent](https://github.com/Code-Fx-MQL/orb-agent) |
| Estratégia | ORB — top-down 1D → 1H → 15m |
| Maturidade | **Fases 0–9** (blueprint + hardening operacional) |
| Destaques | ORB completo: Docker, Telegram, cache OHLCV, scan paralelo, 70+ testes |

Gerar um clone local com o scaffold:

```powershell
.\scripts\scaffold-strategy.ps1 -StrategyName orb -DisplayName "Opening Range Breakout"
```

## Adicionar o seu exemplo

Se criou um agente com este harness e quer listá-lo aqui:

1. Publique o repositório no GitHub
2. Abra um PR neste repo adicionando uma secção neste ficheiro com:
   - Nome e link do repo
   - Estratégia implementada
   - Fase atual (0–8)
   - Breve descrição do que está funcional

Critérios mínimos para listagem:

- Segue [ESTRUTURA-REPOSITORIO.md](../docs/ESTRUTURA-REPOSITORIO.md)
- `validate-harness.ps1` passa (ou equivalente documentado)
- Sem secrets no repositório
- Disclaimer de risco no README