# Cria novo repositório de agente de estratégia a partir do Trading Harness
param(
    [Parameter(Mandatory = $true)]
    [string]$StrategyName,

    [Parameter(Mandatory = $true)]
    [string]$DisplayName,

    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
$HarnessRoot = Split-Path -Parent $PSScriptRoot
$TemplateDir = Join-Path $HarnessRoot "templates\strategy-agent"

$strategy = $StrategyName.ToLower() -replace '[^a-z0-9]', ''
if (-not $strategy) { throw "StrategyName inválido" }

$agentPkg = "${strategy}_agent"
$cliName = "${strategy}-agent"
$strategyUpper = $strategy.ToUpper()
$detectFn = "detect_${strategy}_setup"

if (-not $OutputPath) {
    $OutputPath = Join-Path (Split-Path -Parent $HarnessRoot) $cliName
}
$out = (New-Item -ItemType Directory -Force -Path $OutputPath).FullName

Write-Host "=== Scaffold: $DisplayName ===" -ForegroundColor Cyan
Write-Host "Output: $out" -ForegroundColor DarkGray

function Replace-Placeholders([string]$text) {
    $text = $text -replace '\{\{STRATEGY\}\}', $strategy
    $text = $text -replace '\{\{STRATEGY_UPPER\}\}', $strategyUpper
    $text = $text -replace '\{\{AGENT_PKG\}\}', $agentPkg
    $text = $text -replace '\{\{CLI_NAME\}\}', $cliName
    $text = $text -replace '\{\{DISPLAY_NAME\}\}', $DisplayName
    return $text
}

function Write-FromTemplate([string]$templateName, [string]$destName) {
    $src = Join-Path $TemplateDir $templateName
    $dest = Join-Path $out $destName
    $content = Replace-Placeholders (Get-Content $src -Raw -Encoding UTF8)
    [System.IO.File]::WriteAllText($dest, $content, [System.Text.UTF8Encoding]::new($false))
}

function Write-Utf8File([string]$relativePath, [string]$content) {
    $dest = Join-Path $out $relativePath
    $dir = Split-Path $dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($dest, $content, [System.Text.UTF8Encoding]::new($false))
}

# Templates
Write-FromTemplate "README.md.template" "README.md"
Write-FromTemplate "AGENTS.md.template" "AGENTS.md"
Write-FromTemplate "pyproject.toml.template" "pyproject.toml"
Write-FromTemplate ".env.example.template" ".env.example"

# Dirs
$dirs = @(
    "docs\design-docs", "docs\product-specs", "docs\exec-plans\active",
    "scripts", "tests", "data\memory", "data\audit",
    "src\$agentPkg\agent", "src\$agentPkg\analysis", "src\$agentPkg\audit",
    "src\$agentPkg\backtest", "src\$agentPkg\broker", "src\$agentPkg\config",
    "src\$agentPkg\guardrails", "src\$agentPkg\memory", "src\$agentPkg\pipeline",
    "src\$agentPkg\providers", "src\$agentPkg\tools", "src\$agentPkg\models"
)
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $out $d) | Out-Null }

Write-Utf8File "ARCHITECTURE.md" @"
# Arquitetura - $DisplayName

Baseado em [Trading Harness](https://github.com/Code-Fx-MQL/trading-harness).

Ver ARCHITECTURE.md do harness para camadas e fluxo de dados.

Estrategia especifica: ``config/${strategy}_rules.py``, ``tools/${strategy}.py``.
"@

Write-Utf8File "docs\design-docs\${strategy}-strategy.md" @"
# $DisplayName - Regras da estrategia

> Preencher antes da Fase 3. Ver MAPEAMENTO-ESTRATEGIA no trading-harness.

## Glossario

## Algoritmo top-down

## Parametros e defaults

## Exemplos validos / invalidos

## KPIs alvo

## Disclaimer
"@

Write-Utf8File "docs\exec-plans\active\fase-0-fundacao.md" @"
# Fase 0 - Fundacao

Scaffold criado por trading-harness. Proximo: implementar settings e tools stub.

Ver [FASES-0-8](https://github.com/Code-Fx-MQL/trading-harness/blob/main/docs/FASES-0-8.md).
"@

Write-Utf8File "docs\product-specs\agente-${strategy}.md" @"
# Spec - Agente $DisplayName

## MVP

- [ ] Pipeline deterministico stub
- [ ] $detectFn com testes
- [ ] Modo analysis default
"@

Copy-Item (Join-Path $HarnessRoot ".gitignore") (Join-Path $out ".gitignore")

Write-Utf8File "scripts\setup.ps1" @'
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
python -m venv "$root\.venv"
Push-Location $root
& "$root\.venv\Scripts\pip.exe" install -e ".[dev]"
Pop-Location
Write-Host "Setup OK" -ForegroundColor Green
'@

Write-Utf8File "scripts\validate.ps1" @'
param([string]$HarnessPath = "")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $HarnessPath) {
    $HarnessPath = Join-Path (Split-Path -Parent $root) "trading-harness"
}
& "$HarnessPath\scripts\validate-harness.ps1" -RepoPath $root
'@

$pkgRoot = "src\$agentPkg"
foreach ($rel in @("$pkgRoot\__init__.py", "$pkgRoot\agent\__init__.py", "$pkgRoot\analysis\__init__.py",
    "$pkgRoot\audit\__init__.py", "$pkgRoot\backtest\__init__.py", "$pkgRoot\broker\__init__.py",
    "$pkgRoot\config\__init__.py", "$pkgRoot\guardrails\__init__.py", "$pkgRoot\memory\__init__.py",
    "$pkgRoot\pipeline\__init__.py", "$pkgRoot\providers\__init__.py", "$pkgRoot\tools\__init__.py",
    "$pkgRoot\models\__init__.py", "tests\conftest.py")) {
    Write-Utf8File $rel ""
}

Write-Utf8File "$pkgRoot\config\settings.py" @"
from enum import Enum
from pydantic_settings import BaseSettings, SettingsConfigDict

class OperationMode(str, Enum):
    ANALYSIS = "analysis"
    PAPER = "paper"
    LIVE = "live"

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="${strategyUpper}_", extra="ignore")

    mode: OperationMode = OperationMode.ANALYSIS
    pairs: str = "XAUUSD,EURUSD"
    data_source: str = "stub"
    default_htf: str = "4h"
    default_mtf: str = "1h"
    default_ltf: str = "15m"
    max_risk_per_trade: float = 0.01
    max_daily_risk: float = 0.03
    max_weekly_risk: float = 0.06
    block_news: bool = True
    live_approved: bool = False
    live_approval_token: str = ""
    memory_dir: str = "data/memory"
    webhook_enabled: bool = False

settings = Settings()
"@

Write-Utf8File "$pkgRoot\config\${strategy}_rules.py" @"
"""Regras codificadas - $DisplayName"""

MIN_SETUP_CONFIDENCE = 0.5
ORB_SESSION_MINUTES = 60
"@

Write-Utf8File "$pkgRoot\tools\data.py" @'
from langchain_core.tools import tool

@tool
def fetch_multi_tf_data(pair: str, timeframes: list[str], source: str = "auto") -> dict:
    """OHLCV multi-timeframe (stub)."""
    return {
        "pair": pair.upper(),
        "source": "stub",
        "timeframes": {tf: [] for tf in timeframes},
    }
'@

Write-Utf8File "$pkgRoot\tools\${strategy}.py" @"
from langchain_core.tools import tool

@tool
def $detectFn(
    pair: str,
    htf_candles: list,
    mtf_candles: list,
    ltf_candles: list,
    htf_timeframe: str = "4h",
    mtf_timeframe: str = "1h",
    ltf_timeframe: str = "15m",
) -> dict:
    """Detector de setup (stub - implementar na Fase 3)."""
    return {"found": False, "reason": "stub: nao implementado", "setup": None}
"@

Write-Utf8File "$pkgRoot\tools\trade.py" @'
from langchain_core.tools import tool

@tool
def calculate_trade_params(setup: dict) -> dict:
    """Calcula entry, SL, TP e sizing a partir do setup."""
    return {"valid": False, "reason": "stub"}

@tool
def identify_confluences(setup: dict) -> dict:
    """Lista confluencias do setup detectado."""
    return {"confluences": [], "strength": "weak"}
'@

Write-Utf8File "$pkgRoot\tools\risk.py" @'
from langchain_core.tools import tool

@tool
def check_risk_limits(pair: str, risk_percent: float, mode: str) -> dict:
    """Valida limites de risco diario/semanal antes de abrir posicao."""
    return {"approved": mode != "live", "reason": None}
'@

Write-Utf8File "$pkgRoot\tools\backtest.py" @"
from langchain_core.tools import tool

@tool
def run_${strategy}_backtest(pair: str) -> dict:
    """Executa backtest walk-forward para o par."""
    return {"pair": pair, "win_rate": 0.0, "profit_factor": 0.0}
"@

Write-Utf8File "$pkgRoot\tools\explain.py" @'
from langchain_core.tools import tool

@tool
def explain_setup_detalhado(setup: dict, trade: dict) -> str:
    """Gera explicacao legivel do setup e parametros de trade."""
    return "Explicacao stub."

@tool
def log_trade_outcome(setup_id: str, outcome: str) -> dict:
    """Regista resultado do trade na memoria."""
    return {"logged": True, "setup_id": setup_id}
'@

Write-Utf8File "$pkgRoot\tools\analyze.py" @"
from langchain_core.tools import tool
from ${agentPkg}.pipeline.analyze import run_pair_analysis

@tool
def analyze_pair(pair: str) -> dict:
    """Executa analise completa para um par."""
    return run_pair_analysis(pair)
"@

Write-Utf8File "$pkgRoot\tools\registry.py" @"
from ${agentPkg}.tools.data import fetch_multi_tf_data
from ${agentPkg}.tools.${strategy} import $detectFn
from ${agentPkg}.tools.trade import calculate_trade_params, identify_confluences
from ${agentPkg}.tools.risk import check_risk_limits
from ${agentPkg}.tools.backtest import run_${strategy}_backtest
from ${agentPkg}.tools.explain import explain_setup_detalhado, log_trade_outcome

def get_all_tools():
    return [
        fetch_multi_tf_data,
        $detectFn,
        identify_confluences,
        calculate_trade_params,
        run_${strategy}_backtest,
        explain_setup_detalhado,
        check_risk_limits,
        log_trade_outcome,
    ]
"@

Write-Utf8File "$pkgRoot\pipeline\analyze.py" @"
from ${agentPkg}.config.settings import settings
from ${agentPkg}.tools.data import fetch_multi_tf_data
from ${agentPkg}.tools.${strategy} import $detectFn

def run_pair_analysis(pair: str) -> dict:
    pair = pair.upper()
    tfs = [settings.default_htf, settings.default_mtf, settings.default_ltf]
    data = fetch_multi_tf_data.invoke({
        "pair": pair,
        "timeframes": tfs,
        "source": settings.data_source,
    })
    detection = $detectFn.invoke({
        "pair": pair,
        "htf_candles": [],
        "mtf_candles": [],
        "ltf_candles": [],
        "htf_timeframe": settings.default_htf,
        "mtf_timeframe": settings.default_mtf,
        "ltf_timeframe": settings.default_ltf,
    })
    return {
        "pair": pair,
        "mode": settings.mode.value,
        "data_source": data.get("source"),
        "detection": detection,
    }
"@

Write-Utf8File "$pkgRoot\guardrails\limits.py" @'
class RiskTracker:
    def can_take_trade(self, risk_percent: float) -> bool:
        return risk_percent <= 0.01
'@

Write-Utf8File "$pkgRoot\main.py" @"
import argparse
from ${agentPkg}.pipeline.analyze import run_pair_analysis

def main():
    p = argparse.ArgumentParser(description="$DisplayName agent")
    p.add_argument("--pair", default="XAUUSD")
    args = p.parse_args()
    result = run_pair_analysis(args.pair)
    print(result)

if __name__ == "__main__":
    main()
"@

Write-Utf8File "tests\test_smoke.py" @"
from ${agentPkg}.config.settings import settings, OperationMode
from ${agentPkg}.tools.registry import get_all_tools
from ${agentPkg}.pipeline.analyze import run_pair_analysis

def test_settings_default_analysis():
    assert settings.mode == OperationMode.ANALYSIS

def test_registry_has_eight_tools():
    assert len(get_all_tools()) >= 8

def test_run_pair_analysis_stub():
    result = run_pair_analysis("XAUUSD")
    assert result["pair"] == "XAUUSD"
    assert "detection" in result
"@

Push-Location $out
if (-not (Test-Path ".git")) {
    git init | Out-Null
    git config user.name "Rsantos"
    git config user.email "rsantos@local.dev"
    git add -A | Out-Null
    git commit -m "chore: scaffold $cliName from trading-harness" | Out-Null
}
Pop-Location

Write-Host ""
Write-Host "[OK] Repositorio criado: $out" -ForegroundColor Green
Write-Host "Proximos passos:" -ForegroundColor Cyan
Write-Host "  cd `"$out`"" -ForegroundColor White
Write-Host "  .\scripts\setup.ps1" -ForegroundColor White
Write-Host "  pytest" -ForegroundColor White
Write-Host "  .\scripts\validate.ps1" -ForegroundColor White