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

if (-not $OutputPath) {
    $OutputPath = Join-Path (Split-Path -Parent $HarnessRoot) $cliName
}
$out = New-Item -ItemType Directory -Force -Path $OutputPath

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
    Set-Content -Path $dest -Value $content -Encoding UTF8 -NoNewline
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

# ARCHITECTURE stub
@(
"# Arquitetura — $DisplayName",
"",
"Baseado em [Trading Harness](https://github.com/Code-Fx-MQL/trading-harness).",
"",
"Ver ``ARCHITECTURE.md`` do harness para camadas e fluxo de dados.",
"",
"Estratégia específica: ``config/${strategy}_rules.py``, ``tools/${strategy}.py``."
) | Set-Content (Join-Path $out "ARCHITECTURE.md") -Encoding UTF8

# Docs
@(
"# ${DisplayName} — Regras da estratégia",
"",
"> Preencher antes da Fase 3. Ver MAPEAMENTO-ESTRATEGIA no trading-harness.",
"",
"## Glossário",
"",
"## Algoritmo top-down",
"",
"## Parâmetros e defaults",
"",
"## Exemplos válidos / inválidos",
"",
"## KPIs alvo",
"",
"## Disclaimer"
) | Set-Content (Join-Path $out "docs\design-docs\${strategy}-strategy.md") -Encoding UTF8

@(
"# Fase 0 — Fundação",
"",
"Scaffold criado por trading-harness. Próximo: implementar settings e tools stub.",
"",
"Ver [FASES-0-8](https://github.com/Code-Fx-MQL/trading-harness/blob/main/docs/FASES-0-8.md)."
) | Set-Content (Join-Path $out "docs\exec-plans\active\fase-0-fundacao.md") -Encoding UTF8

@(
"# Spec — Agente $DisplayName",
"",
"## MVP",
"",
"- [ ] Pipeline determinístico stub",
"- [ ] detect_${strategy}_setup com testes",
"- [ ] Modo analysis default"
) | Set-Content (Join-Path $out "docs\product-specs\agente-${strategy}.md") -Encoding UTF8

# .gitignore
Copy-Item (Join-Path $HarnessRoot ".gitignore") (Join-Path $out ".gitignore")

# setup.ps1
@'
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
python -m venv "$root\.venv"
& "$root\.venv\Scripts\pip.exe" install -e "$root[dev]"
Write-Host "Setup OK" -ForegroundColor Green
'@ | Set-Content (Join-Path $out "scripts\setup.ps1") -Encoding UTF8

# validate.ps1 — delega ao harness
@'
param([string]$HarnessPath = "")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $HarnessPath) {
    $HarnessPath = Join-Path (Split-Path -Parent $root) "trading-harness"
}
& "$HarnessPath\scripts\validate-harness.ps1" -RepoPath $root
'@ | Set-Content (Join-Path $out "scripts\validate.ps1") -Encoding UTF8

# Python package __init__ files
$pkgRoot = Join-Path $out "src\$agentPkg"
"" | Set-Content (Join-Path $pkgRoot "__init__.py")
foreach ($sub in @("agent","analysis","audit","backtest","broker","config","guardrails","memory","pipeline","providers","tools","models")) {
    "" | Set-Content (Join-Path $pkgRoot $sub "__init__.py")
}

# settings.py
@(
'from enum import Enum',
'from pydantic_settings import BaseSettings, SettingsConfigDict',
'',
'class OperationMode(str, Enum):',
'    ANALYSIS = "analysis"',
'    PAPER = "paper"',
'    LIVE = "live"',
'',
'class Settings(BaseSettings):',
'    model_config = SettingsConfigDict(env_file=".env", env_prefix="' + $strategyUpper + '_", extra="ignore")',
'',
'    mode: OperationMode = OperationMode.ANALYSIS',
'    pairs: str = "XAUUSD,EURUSD"',
'    data_source: str = "stub"',
'    default_htf: str = "4h"',
'    default_mtf: str = "1h"',
'    default_ltf: str = "15m"',
'    max_risk_per_trade: float = 0.01',
'    max_daily_risk: float = 0.03',
'    max_weekly_risk: float = 0.06',
'    block_news: bool = True',
'    live_approved: bool = False',
'    live_approval_token: str = ""',
'    memory_dir: str = "data/memory"',
'    webhook_enabled: bool = False',
'',
'settings = Settings()'
) | Set-Content (Join-Path $pkgRoot "config\settings.py") -Encoding UTF8

# strategy rules stub
@(
'"""Regras codificadas — ' + $DisplayName + '"""',
'',
'MIN_SETUP_CONFIDENCE = 0.5'
) | Set-Content (Join-Path $pkgRoot "config\${strategy}_rules.py") -Encoding UTF8

# Tool stubs - I'll write key files
$detectFn = "detect_${strategy}_setup"

@(
'from langchain_core.tools import tool',
'',
'@tool',
"def fetch_multi_tf_data(pair: str, timeframes: list[str], source: str = 'auto') -> dict:",
'    """OHLCV multi-timeframe (stub)."""',
'    return {"pair": pair.upper(), "source": "stub", "timeframes": {tf: [] for tf in timeframes}}',
) | Set-Content (Join-Path $pkgRoot "tools\data.py") -Encoding UTF8

@(
'from langchain_core.tools import tool',
'',
'@tool',
"def $detectFn(",
'    pair: str,',
'    htf_candles: list,',
'    mtf_candles: list,',
'    ltf_candles: list,',
'    htf_timeframe: str = "4h",',
'    mtf_timeframe: str = "1h",',
'    ltf_timeframe: str = "15m",',
') -> dict:',
'    """Detector de setup (stub — implementar na Fase 3)."""',
'    return {"found": False, "reason": "stub: não implementado", "setup": None}',
) | Set-Content (Join-Path $pkgRoot "tools\${strategy}.py") -Encoding UTF8

@(
'from langchain_core.tools import tool',
'',
'@tool',
'def calculate_trade_params(setup: dict) -> dict:',
'    return {"valid": False, "reason": "stub"}',
'',
'@tool',
'def identify_confluences(setup: dict) -> dict:',
'    return {"confluences": [], "strength": "weak"}',
) | Set-Content (Join-Path $pkgRoot "tools\trade.py") -Encoding UTF8

@(
'from langchain_core.tools import tool',
'',
'@tool',
'def check_risk_limits(pair: str, risk_percent: float, mode: str) -> dict:',
'    return {"approved": mode != "live", "reason": None}',
) | Set-Content (Join-Path $pkgRoot "tools\risk.py") -Encoding UTF8

@(
'from langchain_core.tools import tool',
'',
'@tool',
"def run_${strategy}_backtest(pair: str) -> dict:",
'    return {"pair": pair, "win_rate": 0.0, "profit_factor": 0.0}',
) | Set-Content (Join-Path $pkgRoot "tools\backtest.py") -Encoding UTF8

@(
'from langchain_core.tools import tool',
'',
'@tool',
'def explain_setup_detalhado(setup: dict, trade: dict) -> str:',
'    return "Explicação stub."',
'',
'@tool',
'def log_trade_outcome(setup_id: str, outcome: str) -> dict:',
'    return {"logged": True, "setup_id": setup_id}',
) | Set-Content (Join-Path $pkgRoot "tools\explain.py") -Encoding UTF8

@(
'from langchain_core.tools import tool',
"from ${agentPkg}.pipeline.analyze import run_pair_analysis",
'',
'@tool',
'def analyze_pair(pair: str) -> dict:',
'    return run_pair_analysis(pair)',
) | Set-Content (Join-Path $pkgRoot "tools\analyze.py") -Encoding UTF8

@(
"from ${agentPkg}.tools.data import fetch_multi_tf_data",
"from ${agentPkg}.tools.${strategy} import $detectFn",
'from ' + $agentPkg + '.tools.trade import calculate_trade_params, identify_confluences',
'from ' + $agentPkg + '.tools.risk import check_risk_limits',
"from ${agentPkg}.tools.backtest import run_${strategy}_backtest",
'from ' + $agentPkg + '.tools.explain import explain_setup_detalhado, log_trade_outcome',
'',
'def get_all_tools():',
'    return [',
'        fetch_multi_tf_data,',
"        $detectFn,",
'        identify_confluences,',
'        calculate_trade_params,',
"        run_${strategy}_backtest,",
'        explain_setup_detalhado,',
'        check_risk_limits,',
'        log_trade_outcome,',
'    ]',
) | Set-Content (Join-Path $pkgRoot "tools\registry.py") -Encoding UTF8

@(
"from ${agentPkg}.config.settings import settings",
"from ${agentPkg}.tools.data import fetch_multi_tf_data",
"from ${agentPkg}.tools.${strategy} import $detectFn",
'',
'def run_pair_analysis(pair: str) -> dict:',
'    pair = pair.upper()',
'    tfs = [settings.default_htf, settings.default_mtf, settings.default_ltf]',
'    data = fetch_multi_tf_data.invoke({"pair": pair, "timeframes": tfs, "source": settings.data_source})',
'    detection = $detectFn.invoke({',
'        "pair": pair,',
'        "htf_candles": [],',
'        "mtf_candles": [],',
'        "ltf_candles": [],',
'        "htf_timeframe": settings.default_htf,',
'        "mtf_timeframe": settings.default_mtf,',
'        "ltf_timeframe": settings.default_ltf,',
'    })',
'    return {"pair": pair, "mode": settings.mode.value, "data_source": data.get("source"), "detection": detection}',
) | Set-Content (Join-Path $pkgRoot "pipeline\analyze.py") -Encoding UTF8

@(
'class RiskTracker:',
'    def can_take_trade(self, risk_percent: float) -> bool:',
'        return risk_percent <= 0.01',
) | Set-Content (Join-Path $pkgRoot "guardrails\limits.py") -Encoding UTF8

@(
'import argparse',
"from ${agentPkg}.pipeline.analyze import run_pair_analysis",
'',
'def main():',
'    p = argparse.ArgumentParser(description="' + $DisplayName + ' agent")',
'    p.add_argument("--pair", default="XAUUSD")',
'    args = p.parse_args()',
'    result = run_pair_analysis(args.pair)',
'    print(result)',
'',
"if __name__ == '__main__':",
'    main()',
) | Set-Content (Join-Path $pkgRoot "main.py") -Encoding UTF8

# tests
@(
"from ${agentPkg}.config.settings import settings, OperationMode",
"from ${agentPkg}.tools.registry import get_all_tools",
"from ${agentPkg}.pipeline.analyze import run_pair_analysis",
'',
'def test_settings_default_analysis():',
'    assert settings.mode == OperationMode.ANALYSIS',
'',
'def test_registry_has_eight_tools():',
'    assert len(get_all_tools()) >= 8',
'',
'def test_run_pair_analysis_stub():',
'    result = run_pair_analysis("XAUUSD")',
'    assert result["pair"] == "XAUUSD"',
'    assert "detection" in result',
) | Set-Content (Join-Path $out "tests\test_smoke.py") -Encoding UTF8

"" | Set-Content (Join-Path $out "tests\conftest.py")

# git init
Push-Location $out
if (-not (Test-Path ".git")) {
    git init | Out-Null
    git add -A | Out-Null
    git commit -m "chore: scaffold $cliName from trading-harness" | Out-Null
}
Pop-Location

Write-Host "`n[OK] Repositório criado: $out" -ForegroundColor Green
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "  cd `"$out`"" -ForegroundColor White
Write-Host "  .\scripts\setup.ps1" -ForegroundColor White
Write-Host "  pytest" -ForegroundColor White
Write-Host "  .\scripts\validate.ps1" -ForegroundColor White