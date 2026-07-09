# Valida estrutura Harness Engineering (repo de estratégia ou blueprint)
param(
    [string]$RepoPath = "",
    [switch]$BlueprintOnly
)

$ErrorActionPreference = "Stop"

if ($BlueprintOnly -or -not $RepoPath) {
    $root = Split-Path -Parent $PSScriptRoot
    $mode = "blueprint"
} else {
    $root = Resolve-Path $RepoPath
    $mode = "strategy"
}

Write-Host "=== Trading Harness Validation ($mode) ===" -ForegroundColor Cyan
Write-Host "Root: $root" -ForegroundColor DarkGray

# 1. AGENTS.md
$agentsPath = Join-Path $root "AGENTS.md"
if (-not (Test-Path $agentsPath)) { throw "AGENTS.md não encontrado" }
$agentsLines = (Get-Content $agentsPath).Count
if ($agentsLines -gt 150) { throw "AGENTS.md tem $agentsLines linhas (max 150)" }
Write-Host "[OK] AGENTS.md: $agentsLines linhas" -ForegroundColor Green

if ($mode -eq "blueprint") {
    $requiredDocs = @(
        "docs\GUIA-REPLICACAO-HARNESS.md",
        "docs\ESTRUTURA-REPOSITORIO.md",
        "docs\MAPEAMENTO-ESTRATEGIA.md",
        "docs\FASES-0-8.md",
        "ARCHITECTURE.md",
        "CONTRIBUTING.md"
    )
    foreach ($f in $requiredDocs) {
        if (-not (Test-Path (Join-Path $root $f))) {
            throw "Doc obrigatório ausente: $f"
        }
    }
    Write-Host "[OK] Documentação blueprint" -ForegroundColor Green

    $templates = Join-Path $root "templates\strategy-agent"
    if (-not (Test-Path $templates)) { throw "templates/strategy-agent ausente" }
    Write-Host "[OK] Templates" -ForegroundColor Green

    $docGarden = Join-Path $root "scripts\doc_garden.py"
    if (Test-Path $docGarden) {
        python $docGarden
        if ($LASTEXITCODE -ne 0) { throw "doc_garden.py falhou" }
    }
} else {
    # Estrutura docs mínima (repo de estratégia)
    $requiredDirs = @(
        "docs\design-docs",
        "docs\exec-plans\active",
        "docs\product-specs"
    )
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path (Join-Path $root $dir))) {
            throw "Diretório obrigatório ausente: $dir"
        }
    }
    Write-Host "[OK] Estrutura docs/" -ForegroundColor Green

    # Plano ativo (máx 1)
    $activePlans = Get-ChildItem (Join-Path $root "docs\exec-plans\active") -Filter "*.md" -ErrorAction SilentlyContinue
    if ($activePlans.Count -gt 1) { throw "Mais de 1 plano ativo em exec-plans/active/" }
    if ($activePlans.Count -eq 1) {
        Write-Host "[OK] Plano ativo: $($activePlans[0].Name)" -ForegroundColor Green
    } else {
        Write-Host "[OK] Sem plano ativo" -ForegroundColor Green
    }

    # Python bootstrap
    $pyproject = Join-Path $root "pyproject.toml"
    if (-not (Test-Path $pyproject)) { throw "pyproject.toml ausente" }

    $srcDirs = Get-ChildItem (Join-Path $root "src") -Directory -ErrorAction SilentlyContinue
    if (-not $srcDirs -or $srcDirs.Count -ne 1) {
        throw "Esperado exatamente 1 pacote em src/"
    }
    $agentPkg = $srcDirs[0].Name
    $mainPy = Join-Path $root "src\$agentPkg\main.py"
    if (-not (Test-Path $mainPy)) { throw "src/$agentPkg/main.py ausente" }
    Write-Host "[OK] Bootstrap Python ($agentPkg)" -ForegroundColor Green

    # Tools mínimas
    $toolsDir = Join-Path $root "src\$agentPkg\tools"
    $toolFiles = @("data.py", "trade.py", "risk.py", "backtest.py", "explain.py", "analyze.py", "registry.py")
    foreach ($f in $toolFiles) {
        if (-not (Test-Path (Join-Path $toolsDir $f))) {
            throw "Tool ausente: src/$agentPkg/tools/$f"
        }
    }
    $strategyTools = Get-ChildItem $toolsDir -Filter "*.py" | Where-Object { $_.Name -notin ($toolFiles + @("__init__.py")) }
    if ($strategyTools.Count -lt 1) {
        throw "Falta tool de estratégia (ex: crt.py, smc.py) em tools/"
    }
    Write-Host "[OK] Tools ($($toolFiles.Count) genéricas + $($strategyTools.Count) estratégia)" -ForegroundColor Green

    # Pipeline + guardrails
    $pipeline = Join-Path $root "src\$agentPkg\pipeline\analyze.py"
    if (-not (Test-Path $pipeline)) { throw "pipeline/analyze.py ausente" }
    $guardrails = Join-Path $root "src\$agentPkg\guardrails\limits.py"
    if (-not (Test-Path $guardrails)) { throw "guardrails/limits.py ausente" }
    Write-Host "[OK] Pipeline + guardrails" -ForegroundColor Green

    # Testes
    $pytest = Join-Path $root ".venv\Scripts\pytest.exe"
    if (Test-Path $pytest) {
        Push-Location $root
        & $pytest -q --tb=no -m "not integration" 2>&1 | Out-Null
        Pop-Location
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] pytest passou" -ForegroundColor Green
        } else {
            Write-Host "[!] pytest falhou (rodar setup.ps1)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[~] pytest skip (rodar setup.ps1 primeiro)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Validação concluída ===" -ForegroundColor Cyan