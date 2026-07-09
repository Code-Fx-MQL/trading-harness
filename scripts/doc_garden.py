#!/usr/bin/env python3
"""Doc gardening — valida consistência do repositório trading-harness."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

REQUIRED_DOCS = [
    "docs/README.md",
    "docs/GUIA-REPLICACAO-HARNESS.md",
    "docs/ESTRUTURA-REPOSITORIO.md",
    "docs/MAPEAMENTO-ESTRATEGIA.md",
    "docs/FASES-0-8.md",
    "docs/design-docs/core-beliefs.md",
    "ARCHITECTURE.md",
    "CONTRIBUTING.md",
    "examples/README.md",
]

REQUIRED_TEMPLATES = [
    "templates/strategy-agent/AGENTS.md.template",
    "templates/strategy-agent/pyproject.toml.template",
    "templates/strategy-agent/.env.example.template",
]


def _fail(msg: str) -> None:
    print(f"[FAIL] {msg}")
    sys.exit(1)


def main() -> None:
    print("=== Doc Gardening (trading-harness) ===")

    agents = ROOT / "AGENTS.md"
    readme = ROOT / "README.md"
    if not agents.exists():
        _fail("AGENTS.md ausente")
    if not readme.exists():
        _fail("README.md ausente")

    agents_lines = len(agents.read_text(encoding="utf-8").splitlines())
    if agents_lines > 150:
        _fail(f"AGENTS.md tem {agents_lines} linhas (máx 150)")

    for rel in REQUIRED_DOCS:
        if not (ROOT / rel).exists():
            _fail(f"Doc obrigatório ausente: {rel}")

    for rel in REQUIRED_TEMPLATES:
        if not (ROOT / rel).exists():
            _fail(f"Template obrigatório ausente: {rel}")

    readme_text = readme.read_text(encoding="utf-8")
    if "GUIA-REPLICACAO-HARNESS" not in readme_text:
        _fail("README.md não referencia o guia principal")

    if "trading-harness" not in readme_text.lower() and "Trading Harness" not in readme_text:
        _fail("README.md não identifica o projeto")

    print("[OK] Documentação blueprint consistente")


if __name__ == "__main__":
    main()