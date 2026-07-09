# Verifica vazamento de secrets antes de push (repo publico)
param(
    [string]$Root = ""
)

$ErrorActionPreference = "Stop"
if (-not $Root) { $Root = Split-Path -Parent $PSScriptRoot }

Write-Host "=== Secret scan: $Root ===" -ForegroundColor Cyan

$patterns = @(
    'gho_[A-Za-z0-9]{20,}',
    'ghp_[A-Za-z0-9]{20,}',
    'github_pat_[A-Za-z0-9_]{20,}',
    'sk-[A-Za-z0-9]{20,}',
    'xox[baprs]-[A-Za-z0-9-]{10,}',
    'AKIA[0-9A-Z]{16}',
    'password\s*=\s*[^\s]{8,}',
    'OPENAI_API_KEY\s*=\s*\S+',
    'ANTHROPIC_API_KEY\s*=\s*\S+',
    'TELEGRAM_BOT_TOKEN\s*=\s*\d+:',
    'EASYPANEL_TOKEN\s*=\s*\S+'
)

$skipDirs = @('.git', '.venv', 'venv', 'node_modules', '__pycache__')
$hits = @()

Get-ChildItem $Root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $rel = $_.FullName.Substring($Root.Length).TrimStart('\')
    foreach ($part in $skipDirs) {
        if ($rel -match "(^|[\\/])$([regex]::Escape($part))([\\/]|$)") { return }
    }
    if ($_.Name -match '^\.env(\.|$)' -and $_.Name -notin @('.env.example', '.env.example.template')) {
        $hits += "ARQUIVO SENSIVEL: $rel"
        return
    }
    try {
        $text = Get-Content $_.FullName -Raw -ErrorAction Stop
    } catch {
        return
    }
    foreach ($pat in $patterns) {
        if ($text -match $pat) {
            $hits += "PADRAO '$pat' em $rel"
        }
    }
}

if ($hits.Count -gt 0) {
    $hits | ForEach-Object { Write-Host "[FAIL] $_" -ForegroundColor Red }
    throw "Secrets ou ficheiros sensiveis detectados ($($hits.Count))"
}

Write-Host "[OK] Nenhum secret detectado" -ForegroundColor Green