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

O CRT também mantém uma cópia local do blueprint em `docs/harness-blueprint/` (sincronizada com este repo).

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