# Trading Harness

[![CI](https://github.com/Code-Fx-MQL/trading-harness/actions/workflows/ci.yml/badge.svg)](https://github.com/Code-Fx-MQL/trading-harness/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Harness Engineering para trading** — infraestrutura reutilizável para construir agentes de IA que implementam **qualquer estratégia** (CRT, SMC, ICT, ORB, mean reversion, etc.) com segurança, testes e operação em produção.

> **Humans steer. Agents execute.**

⚠️ Uso educacional e pesquisa. Trading envolve risco de perda de capital. Teste em demo/backtest antes de qualquer uso real.

## O que é isto?

```
Estratégia (domínio)  ≠  Harness (infraestrutura)
```

| Harness (este repo) | Implementação da estratégia (seu repo) |
|---------------------|----------------------------------------|
| Pipeline determinístico | `detect_{strategy}_setup` |
| Guardrails de risco | Regras de entrada/saída |
| Paper trading + live gate | Parâmetros e confluências |
| Audit log, CI, deploy | Docs da estratégia |

Este repositório **não é um bot de trading**. É o blueprint, templates e ferramentas para que qualquer pessoa (ou agente de IA) possa criar um sistema completo seguindo a mesma arquitetura.

## Início rápido

### 1. Ler a documentação

| Doc | Conteúdo |
|-----|----------|
| **[Guia completo](docs/GUIA-REPLICACAO-HARNESS.md)** | Passo a passo do zero à produção |
| **[Integração MT5](docs/INTEGRACAO-MT5-DATA-PROVIDER.md)** | Dados live MT5 + harness na nuvem |
| [Estrutura do repositório](docs/ESTRUTURA-REPOSITORIO.md) | Árvore de ficheiros e convenções |
| [Mapeamento de estratégia](docs/MAPEAMENTO-ESTRATEGIA.md) | Traduzir regras → módulos |
| [Fases 0–8](docs/FASES-0-8.md) | Roadmap com entregáveis |
| [Arquitetura](ARCHITECTURE.md) | Camadas e fluxo de dados |

### 2. Criar um novo agente de estratégia

```powershell
git clone https://github.com/Code-Fx-MQL/trading-harness.git
cd trading-harness
.\scripts\scaffold-strategy.ps1 -StrategyName smc -DisplayName "Smart Money Concepts"
cd ..\smc-agent
.\scripts\setup.ps1
.\scripts\validate.ps1
```

### 3. Validar um repositório existente

```powershell
.\scripts\validate-harness.ps1 -RepoPath C:\path\to\your-agent
```

## Implementação de referência

O **[Agente CRT](https://github.com/Code-Fx-MQL/crt-agent)** (Candle Range Theory) é a implementação viva que validou este harness nas Fases 0–8: pipeline, paper trading, live gate, Docker, webhooks e scan agendado.

Ver [examples/README.md](examples/README.md) para mais detalhes e como contribuir com novas implementações.

## Contribuir

Queremos melhorar o harness em conjunto. Veja [CONTRIBUTING.md](CONTRIBUTING.md) para:

- Propor melhorias na arquitetura ou documentação
- Partilhar implementações de estratégias (como exemplos)
- Reportar lacunas no blueprint ou nos templates
- Sugerir novos guardrails, testes ou padrões operacionais

## Princípios

Extraídos de [docs/design-docs/core-beliefs.md](docs/design-docs/core-beliefs.md):

1. **Humans steer, agents execute** — live gate e checklist go-live
2. **Repositório = fonte de verdade** — tudo versionado em `docs/`
3. **Pipeline determinístico primeiro** — funciona sem API de LLM
4. **Modo default `analysis`** — zero execução real por defeito
5. **Feedback loops = produto** — CI, audit, métricas, paper

## Licença

[MIT](LICENSE) — use, adapte e contribua livremente.