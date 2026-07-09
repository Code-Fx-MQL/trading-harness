# Core Beliefs — Princípios Agent-First

> Crenças fundamentais que guiam decisões neste projeto. Agentes devem internalizar estes princípios.

## 1. Humans steer. Agents execute.

Humanos definem intenção, prioridades e critérios de aceite. Agentes implementam, testam, revisam e documentam.

## 2. O repositório é a fonte de verdade

Conhecimento em Slack, Google Docs ou cabeças humanas **não existe** para o agente. Se importa, versione em `docs/`.

## 3. Mapa, não manual

`AGENTS.md` aponta para onde olhar. Detalhes vivem em `docs/`. Nunca inflar o índice.

## 4. Falha = capacidade faltando

Quando o agente falha, a pergunta é: "que ferramenta, doc ou invariante está faltando?" — não "tente de novo com mais força".

## 5. Legibilidade para agentes > estética humana

Código e docs otimizados para raciocínio de LLM. Estilo humano é secundário se output é correto e maintainable.

## 6. Invariantes, não micromanagement

Enforce boundaries (camadas, parse-at-boundary, logging). Dentro dos boundaries, liberdade de implementação.

## 7. Throughput com correção barata

PRs curtos, merges rápidos, follow-ups para flakes. Em ambiente agent-first, esperar é mais caro que corrigir.

## 8. Garbage collection contínua

Dívida técnica paga em incrementos diários via golden principles, não em sprints de "limpeza de AI slop".

## 9. Progressive disclosure de contexto

Agente começa com pouco contexto estável e descobre mais conforme necessário. Contexto é recurso escasso.

## 10. Feedback loops são o produto

O harness (testes, review, observability, validação visual) é tão importante quanto o código de aplicação.