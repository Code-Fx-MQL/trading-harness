# Contribuir ao Trading Harness

Obrigado por ajudar a melhorar o harness para a comunidade de trading algorítmico e agentes de IA.

## O que contribuir

| Área | Exemplos |
|------|----------|
| **Documentação** | Clarificar guias, corrigir links, traduções |
| **Templates** | Melhorar `templates/strategy-agent/` |
| **Scripts** | `validate-harness.ps1`, `scaffold-strategy.ps1`, `doc_garden.py` |
| **Mapeamentos** | Novos exemplos em `MAPEAMENTO-ESTRATEGIA.md` (SMC, ORB, etc.) |
| **Issues** | Lacunas encontradas ao replicar para nova estratégia |

## O que NÃO vai neste repo

- Código de estratégias específicas em produção → crie um repo próprio com o scaffold
- Secrets, `.env` com credenciais, ou dados de trading reais
- Promessas de retorno ou conteúdo de "sinal de compra/venda"

Implementações completas podem ser listadas em `examples/README.md` com link para o repo externo.

## Fluxo de contribuição

1. Fork do repositório
2. Branch descritiva: `docs/smc-mapping`, `fix/validate-agents-limit`
3. Alterações focadas — um tema por PR
4. Validar localmente:

```powershell
python scripts/doc_garden.py
.\scripts\validate-harness.ps1 -RepoPath . -BlueprintOnly
```

5. Abrir Pull Request com descrição do problema e da solução

## Padrões

- Português ou inglês — seja consistente dentro do mesmo ficheiro
- `AGENTS.md` em repos de estratégia: máximo 150 linhas
- Links relativos em markdown (não URLs absolutas para ficheiros internos)
- Disclaimer de risco em docs que mencionem trading real

## Código de conduta

Seja respeitoso. Foco em engenharia, segurança e educação — não em hype de trading.

## Licença

Ao contribuir, aceita que as contribuições são licenciadas sob [MIT](LICENSE).