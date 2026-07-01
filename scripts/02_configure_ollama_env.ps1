param(
    [switch]$Apply,
    [string]$ModelDir = 'G:\ollama',
    [string]$OllamaHost = '127.0.0.1:11700'
)

$ErrorActionPreference = 'Stop'

$settings = [ordered]@{
    OLLAMA_FLASH_ATTENTION = '1'
    OLLAMA_KV_CACHE_TYPE   = 'q8_0'
    OLLAMA_MODELS          = $ModelDir
    OLLAMA_HOST            = $OllamaHost
}

Write-Host 'Proposed user environment variables:'
$settings.GetEnumerator() | Format-Table -AutoSize

if (-not (Test-Path $ModelDir)) {
    Write-Warning "Model directory does not exist: $ModelDir"
}

$port = [int]($OllamaHost.Split(':')[-1])
$listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    Write-Warning "Port $port is currently listening. Confirm it is the intended Ollama process before applying."
}

if (-not $Apply) {
    Write-Host 'DRY RUN. Re-run with -Apply after audit.'
    exit 0
}

foreach ($entry in $settings.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, 'User')
}

Write-Host 'Environment variables applied. Fully quit and restart Ollama.'
