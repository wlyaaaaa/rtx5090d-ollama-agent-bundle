param(
    [string]$HostUrl = 'http://127.0.0.1:32100',
    [string]$Model = 'qwen3.6-35b-100k',
    [int]$NumCtx = 100000,
    [string]$Label = 'swap',
    [switch]$Long,
    [string]$OutputRoot = "$PSScriptRoot\..\results\benchmarks"
)

$ErrorActionPreference = 'Stop'

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$safeLabel = $Label -replace '[^A-Za-z0-9_.-]', '_'
$benchScript = Join-Path $PSScriptRoot 'benchmark_ollama.py'

if (-not (Test-Path -LiteralPath $benchScript)) {
    throw "Benchmark script not found: $benchScript"
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$gpuFile = Join-Path $OutputRoot "bench_${safeLabel}_gpu_${stamp}.txt"
$psFile = Join-Path $OutputRoot "bench_${safeLabel}_ollama_ps_${stamp}.txt"
$shortFile = Join-Path $OutputRoot "bench_${safeLabel}_100k_1k_128_${stamp}.json"
$longFile = Join-Path $OutputRoot "bench_${safeLabel}_100k_45k_64_${stamp}.json"

Write-Host "=== Snapshot before benchmark ==="
nvidia-smi | Tee-Object -FilePath $gpuFile
ollama ps | Tee-Object -FilePath $psFile

Write-Host "=== Short benchmark: 1K prompt / 128 output / ctx $NumCtx ==="
python $benchScript `
    --host $HostUrl `
    --model $Model `
    --num-ctx $NumCtx `
    --prompt-tokens 1000 `
    --output-tokens 128 `
    --repeats 1 `
    --output-json $shortFile

if ($Long) {
    Write-Host "=== Long benchmark: 45K prompt / 64 output / ctx $NumCtx ==="
    python $benchScript `
        --host $HostUrl `
        --model $Model `
        --num-ctx $NumCtx `
        --prompt-tokens 45000 `
        --output-tokens 64 `
        --repeats 1 `
        --output-json $longFile
} else {
    Write-Host "Long benchmark skipped. Re-run with -Long after installing RTX 5090D."
}

Write-Host "=== Snapshot after benchmark ==="
ollama ps
Write-Host "Short result: $shortFile"
if ($Long) {
    Write-Host "Long result:  $longFile"
}
