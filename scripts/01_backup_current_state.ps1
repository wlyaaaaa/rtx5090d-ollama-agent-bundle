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
    @{ Name = 'ollama-version.txt'; Command = 'ollama --version' },
    @{ Name = 'ollama-list.txt'; Command = 'ollama list' },
    @{ Name = 'ollama-ps.txt'; Command = 'ollama ps' }
)

foreach ($item in $commands) {
    try {
        cmd.exe /c $item.Command 2>&1 | Out-File -FilePath (Join-Path $OutputRoot $item.Name) -Encoding utf8
    } catch {
        "ERROR: $($_.Exception.Message)" | Out-File -FilePath (Join-Path $OutputRoot $item.Name) -Encoding utf8
    }
}

Get-ChildItem Env: | Where-Object { $_.Name -like 'OLLAMA*' } |
    Sort-Object Name | Format-Table -AutoSize | Out-String |
    Out-File (Join-Path $OutputRoot 'ollama-environment.txt') -Encoding utf8

$configCandidates = @(
    "$HOME\.openclaw",
    "$HOME\.config\opencode",
    "$HOME\AppData\Roaming\opencode",
    "$HOME\AppData\Local\OpenClaw"
)

foreach ($path in $configCandidates) {
    if (Test-Path $path) {
        $safeName = ($path -replace '[:\\/]', '_').Trim('_')
        Copy-Item $path (Join-Path $OutputRoot $safeName) -Recurse -Force
    }
}

Write-Host "Backup completed: $OutputRoot"
