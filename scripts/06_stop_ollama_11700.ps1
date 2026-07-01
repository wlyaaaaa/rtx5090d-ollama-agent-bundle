param(
    [switch]$Apply,
    [string]$OllamaHost = '127.0.0.1:11700'
)

$ErrorActionPreference = 'Stop'

function Get-OllamaEndpoint {
    param([string]$HostValue)

    $parts = $HostValue.Split(':')
    if ($parts.Count -lt 2) {
        throw "OllamaHost must include host and port, for example 127.0.0.1:11700"
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
$target = Get-ListenerProcess -Port $endpoint.Port

if (-not $target) {
    Write-Host "No process is listening on port $($endpoint.Port). Nothing to stop."
    exit 0
}

$proc = $target.Process
Write-Host "Port $($endpoint.Port) is listening by PID $($proc.Id) ($($proc.ProcessName))."

if ($proc.ProcessName -ine 'ollama') {
    throw "Refusing to stop PID $($proc.Id) because it is not an ollama process."
}

if (-not $Apply) {
    Write-Host "DRY RUN. Re-run with -Apply to stop PID $($proc.Id)."
    exit 0
}

Stop-Process -Id $proc.Id -Force

for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 500
    if (-not (Get-ListenerProcess -Port $endpoint.Port)) {
        Write-Host "Ollama on $OllamaHost stopped."
        exit 0
    }
}

throw "Stop command was issued, but port $($endpoint.Port) is still listening."
