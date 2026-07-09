# AGENTS.md — Mapa do Repositório

> Índice para agentes de IA. Detalhes em `docs/`.

## Missão

**Trading Harness** — blueprint público para replicar Harness Engineering em qualquer estratégia de trading.

## Onde começar

| Tarefa | Arquivo |
|--------|---------|
| Visão geral humana | `README.md` |
| **Guia de replicação** | `docs/GUIA-REPLICACAO-HARNESS.md` |
| Estrutura de repo | `docs/ESTRUTURA-REPOSITORIO.md` |
| Mapear estratégia | `docs/MAPEAMENTO-ESTRATEGIA.md` |
| Roadmap fases | `docs/FASES-0-8.md` |
| Arquitetura | `ARCHITECTURE.md` |
| Contribuir | `CONTRIBUTING.md` |
| Implementação CRT | `examples/README.md` |

## Comandos

```powershell
# Scaffold novo agente
.\scripts\scaffold-strategy.ps1 -StrategyName orb -DisplayName "Opening Range Breakout"

# Validar repo de estratégia
.\scripts\validate-harness.ps1 -RepoPath ..\orb-agent

# Validar docs deste repo
python scripts/doc_garden.py
```

## Estrutura

```
trading-harness/
├── docs/           # Blueprint (system of record)
├── templates/      # Scaffold para novos agentes
├── scripts/        # scaffold + validate + doc_garden
├── examples/       # Implementações de referência
└── .github/        # CI
```

## Regras inegociáveis

- Harness ≠ estratégia — só `config/{strategy}_rules.py`, `tools/{strategy}.py` e `analysis/` mudam
- Modo default `analysis`; live bloqueado sem gate duplo
- AGENTS.md ≤ 150 linhas (mapa, não manual)
- Falha = capacidade faltando (tool/doc/test), não retry cego

## Contribuições esperadas

- Melhorar docs, templates ou `validate-harness.ps1`
- Adicionar exemplos de mapeamento (SMC, ORB, etc.) em `docs/MAPEAMENTO-ESTRATEGIA.md`
- Issues com lacunas encontradas ao replicar para nova estratégia