param(
    [switch]$Apply,
    [string]$OllamaHost = '127.0.0.1:32100',
    [string]$ModelDir = 'G:\ollama',
    [string]$OllamaExe = 'ollama',
    [string]$LogDir = "$PSScriptRoot\..\results\logs\ollama-service"
)

$ErrorActionPreference = 'Stop'

function Get-OllamaEndpoint {
    param([string]$HostValue)

    $parts = $HostValue.Split(':')
    if ($parts.Count -lt 2) {
        throw "OllamaHost must include host and port, for example 127.0.0.1:32100"
    }

    [pscustomobject]@{
        Address = ($parts[0..($parts.Count - 2)] -join ':')
        Port    = [int]$parts[-1]
    }
}

function Get-ListenerProcess {
    param([int]$Port)

    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $listener) {
        return $null
    }

    $process = Get-Process -Id $listener.OwningProcess -ErrorAction Stop
    [pscustomobject]@{
        Connection = $listener
        Process    = $process
    }
}

$endpoint = Get-OllamaEndpoint -HostValue $OllamaHost
$existing = Get-ListenerProcess -Port $endpoint.Port

if ($existing) {
    $proc = $existing.Process
    Write-Host "Port $($endpoint.Port) is already listening by PID $($proc.Id) ($($proc.ProcessName))."
    if ($proc.ProcessName -ieq 'ollama') {
        Write-Host "Ollama already appears to be running. No new process will be started."
        exit 0
    }

    throw "Port $($endpoint.Port) is not owned by ollama. Refusing to start another service."
}

$resolved = Get-Command $OllamaExe -ErrorAction Stop

Write-Host "Ollama executable: $($resolved.Source)"
Write-Host "Ollama host:       $OllamaHost"
Write-Host "Model directory:   $ModelDir"
Write-Host "Log directory:     $LogDir"

if (-not (Test-Path -LiteralPath $ModelDir)) {
    Write-Warning "Model directory does not exist: $ModelDir"
}

if (-not $Apply) {
    Write-Host 'DRY RUN. Re-run with -Apply to start ollama serve.'
    exit 0
}

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

$env:OLLAMA_HOST = $OllamaHost
$env:OLLAMA_MODELS = $ModelDir
$env:OLLAMA_FLASH_ATTENTION = '1'
$env:OLLAMA_KV_CACHE_TYPE = 'q8_0'

$stdout = Join-Path $LogDir 'ollama-32100.stdout.log'
$stderr = Join-Path $LogDir 'ollama-32100.stderr.log'

$process = Start-Process -FilePath $resolved.Source `
    -ArgumentList 'serve' `
    -WindowStyle Hidden `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr `
    -PassThru

Start-Sleep -Seconds 2

$started = Get-ListenerProcess -Port $endpoint.Port
if (-not $started -or $started.Process.Id -ne $process.Id) {
    throw "ollama serve was started as PID $($process.Id), but port $($endpoint.Port) is not listening as expected. Check $stderr"
}

Write-Host "Ollama serve started on $OllamaHost as PID $($process.Id)."
Write-Host "Logs: $stdout ; $stderr"
