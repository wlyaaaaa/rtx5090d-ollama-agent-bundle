param(
    [string]$HostUrl = 'http://127.0.0.1:32100',
    [string]$NormalModel = 'qwen3.6-35b-100k',
    [string]$ReviewModel = 'qwen3.6-27b-100k'
)

$ErrorActionPreference = 'Stop'

Write-Host '=== GPU ==='
nvidia-smi

Write-Host '=== Ollama tags ==='
Invoke-RestMethod -Uri "$HostUrl/api/tags" -Method Get | ConvertTo-Json -Depth 6

foreach ($model in @($NormalModel, $ReviewModel)) {
    Write-Host "=== Smoke test: $model ==="
    $body = @{
        model = $model
        messages = @(@{ role = 'user'; content = 'Reply with exactly: ok' })
        stream = $false
        think = $false
        options = @{ num_ctx = 100000; num_predict = 16; temperature = 0 }
    } | ConvertTo-Json -Depth 8

    $response = Invoke-RestMethod -Uri "$HostUrl/api/chat" -Method Post -ContentType 'application/json' -Body $body
    $response | ConvertTo-Json -Depth 8
    if ($response.message.content.Trim().ToLowerInvariant() -ne 'ok') {
        Write-Warning "$model did not reply exactly 'ok'. Inspect the output."
    }
}

Write-Host '=== Ollama process/offload ==='
ollama ps
