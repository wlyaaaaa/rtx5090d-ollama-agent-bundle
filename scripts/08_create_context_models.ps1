param(
    [switch]$Apply,
    [string]$ConfigRoot = "$PSScriptRoot\..\configs"
)

$ErrorActionPreference = 'Stop'

$models = @(
    @{ Name = 'qwen3.6-35b-100k'; File = 'Modelfile.qwen3.6-35b-100k' },
    @{ Name = 'qwen3.6-27b-100k'; File = 'Modelfile.qwen3.6-27b-100k' },
    @{ Name = 'qwen3.6-35b-256k'; File = 'Modelfile.qwen3.6-35b-256k' },
    @{ Name = 'qwen3.6-27b-256k'; File = 'Modelfile.qwen3.6-27b-256k' }
)

foreach ($model in $models) {
    $file = Join-Path $ConfigRoot $model.File
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Missing Modelfile: $file"
    }
    if (Select-String -LiteralPath $file -Pattern '^\s*SYSTEM\b' -Quiet) {
        throw "Refusing to create $($model.Name): SYSTEM directive found in $file"
    }
}

Write-Host 'Context models to create:'
$models | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Modelfile = Join-Path $ConfigRoot $_.File } } |
    Format-Table -AutoSize

if (-not $Apply) {
    Write-Host 'DRY RUN. Re-run with -Apply to create the context models.'
    exit 0
}

foreach ($model in $models) {
    $file = Join-Path $ConfigRoot $model.File
    ollama create $model.Name -f $file
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create $($model.Name)."
    }
}

Write-Host 'Context model creation completed.'
