# Documentação — Trading Harness

> **Repositório:** [Code-Fx-MQL/trading-harness](https://github.com/Code-Fx-MQL/trading-harness)  
> **Implementação de referência:** [Agente CRT](https://github.com/Code-Fx-MQL/crt-agent) (Fases 0–8)

Este conjunto de documentos descreve como construir um **sistema Harness Engineering** completo para trading — de forma que **qualquer estratégia** (CRT, SMC, ICT, ORB, mean reversion, etc.) possa ser implementada na mesma arquitetura.

## Documentos

| Documento | Conteúdo |
|-----------|----------|
| **[GUIA-REPLICACAO-HARNESS.md](./GUIA-REPLICACAO-HARNESS.md)** | **Guia principal** — passo a passo, camadas, pipeline, checklist |
| [ESTRUTURA-REPOSITORIO.md](./ESTRUTURA-REPOSITORIO.md) | Árvore de ficheiros, convenções, módulos obrigatórios |
| [MAPEAMENTO-ESTRATEGIA.md](./MAPEAMENTO-ESTRATEGIA.md) | Traduzir regras de uma estratégia para o harness |
| [FASES-0-8.md](./FASES-0-8.md) | Entregáveis por fase (roadmap) |
| [core-beliefs.md](./design-docs/core-beliefs.md) | Princípios inegociáveis |

## Para quem é

- Desenvolvedores que querem criar um agente para outra estratégia
- Agentes de IA que implementam features em repos derivados
- Revisores que validam se um novo agente segue o harness

## Princípio central

```
Estratégia (domínio)  ≠  Harness (infraestrutura)
```

A estratégia vive em `config/{strategy}_rules.py`, `tools/{strategy}.py`, `analysis/`.  
O harness (risco, audit, paper, deploy, CI, docs) é **reutilizável sem alteração**.

## Início rápido

1. Ler [GUIA-REPLICACAO-HARNESS.md](./GUIA-REPLICACAO-HARNESS.md) — secções 1–4
2. Executar `.\scripts\scaffold-strategy.ps1` ou copiar [ESTRUTURA-REPOSITORIO.md](./ESTRUTURA-REPOSITORIO.md)
3. Preencher [MAPEAMENTO-ESTRATEGIA.md](./MAPEAMENTO-ESTRATEGIA.md) para a sua estratégia
4. Seguir [FASES-0-8.md](./FASES-0-8.md) como plano de execução

## Implementação de referência (CRT)

| Conceito blueprint | Implementação CRT |
|--------------------|-------------------|
| `{strategy}_rules` | `config/crt_rules.py` |
| `detect_{strategy}_setup` | `tools/crt.py` |
| `run_pair_analysis` | `pipeline/analyze.py` |
| Live gate | `guardrails/live_gate.py` |
| Go-live checklist | `ops/golive.py` |
| Dashboard | `ui/app.py` |

Repo: [github.com/Code-Fx-MQL/crt-agent](https://github.com/Code-Fx-MQL/crt-agent)