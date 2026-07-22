param(
    [switch]$Apply,
    [string]$OutputRoot = "$PSScriptRoot\..\results\backups\backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
)

$ErrorActionPreference = 'Stop'

Write-Host "Backup target: $OutputRoot"
if (-not $Apply) {
    Write-Host "DRY RUN. Re-run with -Apply to write backup files."
    exit 0
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$commands = @(
    @{ Name = 'nvidia-smi.txt'; Command = 'nvidia-smi' },
    @{ Name = 'ollama-version.txt'; Command = 'ollama --version' }
)

foreach ($item in $commands) {
    try {
        cmd.exe /c $item.Command 2>&1 | Out-File -FilePath (Join-Path $OutputRoot $item.Name) -Encoding utf8
    } catch {
        "ERROR: $($_.Exception.Message)" | Out-File -FilePath (Join-Path $OutputRoot $item.Name) -Encoding utf8
    }
}

$ollamaHost = if ($env:OLLAMA_HOST) { $env:OLLAMA_HOST } else { '127.0.0.1:32100' }
$ollamaUriBase = if ($ollamaHost -match '^https?://') { $ollamaHost.TrimEnd('/') } else { "http://$($ollamaHost.TrimEnd('/'))" }
$ollamaPortOpen = $false
try {
    $uri = [Uri]$ollamaUriBase
    $hostName = if ($uri.Host -eq 'localhost') { '127.0.0.1' } else { $uri.Host }
    $ollamaPortOpen = [bool](Get-NetTCPConnection -RemoteAddress $hostName -RemotePort $uri.Port -State Established -ErrorAction SilentlyContinue) -or
        [bool](Get-NetTCPConnection -LocalAddress $hostName -LocalPort $uri.Port -State Listen -ErrorAction SilentlyContinue)
} catch {
    $ollamaPortOpen = $false
}

if ($ollamaPortOpen) {
    try {
        Invoke-RestMethod -Uri "$ollamaUriBase/api/tags" -TimeoutSec 10 |
            ConvertTo-Json -Depth 20 |
            Out-File -FilePath (Join-Path $OutputRoot 'ollama-list.json') -Encoding utf8
    } catch {
        "ERROR: $($_.Exception.Message)" | Out-File -FilePath (Join-Path $OutputRoot 'ollama-list.json') -Encoding utf8
    }

    try {
        Invoke-RestMethod -Uri "$ollamaUriBase/api/ps" -TimeoutSec 10 |
            ConvertTo-Json -Depth 20 |
            Out-File -FilePath (Join-Path $OutputRoot 'ollama-ps.json') -Encoding utf8
    } catch {
        "ERROR: $($_.Exception.Message)" | Out-File -FilePath (Join-Path $OutputRoot 'ollama-ps.json') -Encoding utf8
    }
} else {
    "SKIPPED: No Ollama listener at $ollamaUriBase. This backup does not start Ollama." |
        Out-File -FilePath (Join-Path $OutputRoot 'ollama-list.json') -Encoding utf8
    "SKIPPED: No Ollama listener at $ollamaUriBase. This backup does not start Ollama." |
        Out-File -FilePath (Join-Path $OutputRoot 'ollama-ps.json') -Encoding utf8
}

Get-ChildItem Env: | Where-Object { $_.Name -like 'OLLAMA*' } |
    Sort-Object Name | Format-Table -AutoSize | Out-String |
    Out-File (Join-Path $OutputRoot 'ollama-environment.txt') -Encoding utf8

function Copy-ConfigLeaf {
    param(
        [string]$Path,
        [string]$DestinationRoot
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $safeName = ($Path -replace '[:\\/]', '_').Trim('_')
    Copy-Item -LiteralPath $Path -Destination (Join-Path $DestinationRoot $safeName) -Force
}

function Copy-TopLevelConfigFiles {
    param(
        [string]$Path,
        [string]$DestinationRoot
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return
    }

    $safeName = ($Path -replace '[:\\/]', '_').Trim('_')
    $target = Join-Path $DestinationRoot $safeName
    New-Item -ItemType Directory -Path $target -Force | Out-Null

    Get-ChildItem -LiteralPath $Path -Force -File |
        Where-Object {
            $_.Extension -in @('.json', '.jsonc', '.toml', '.yaml', '.yml', '.conf', '.ini') -or
            $_.Name -like '*.bak*'
        } |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $target $_.Name) -Force
        }
}

$configFileCandidates = @(
    "$HOME\.openclaw\openclaw.json",
    "$HOME\.config\opencode\opencode.jsonc",
    "$HOME\AppData\Roaming\opencode\opencode.jsonc"
)

foreach ($path in $configFileCandidates) {
    Copy-ConfigLeaf -Path $path -DestinationRoot $OutputRoot
}

$configDirCandidates = @(
    "$HOME\.openclaw",
    "$HOME\.config\opencode",
    "$HOME\AppData\Roaming\opencode",
    "$HOME\AppData\Local\OpenClaw"
)

foreach ($path in $configDirCandidates) {
    Copy-TopLevelConfigFiles -Path $path -DestinationRoot $OutputRoot
    }

Write-Host "Backup completed: $OutputRoot"
