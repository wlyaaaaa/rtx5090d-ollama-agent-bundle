param(
    [switch]$Apply,
    [string]$BaseModel = 'qwen3.6:35b'
)

$ErrorActionPreference = 'Stop'
$BundleRoot = Resolve-Path "$PSScriptRoot\.."
$NormalFile = Join-Path $BundleRoot 'configs\Modelfile.normal'
$UnrestrictedFile = Join-Path $BundleRoot 'configs\Modelfile.unrestricted'

Write-Host "Base model requested: $BaseModel"
ollama show $BaseModel | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Base model '$BaseModel' is not available. Run 'ollama list' and pass the exact audited ID."
}

$tempDir = Join-Path $env:TEMP "ollama5090d-models-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

function Prepare-Modelfile([string]$Source, [string]$Destination) {
    $content = Get-Content $Source -Raw
    $content = $content -replace '(?m)^FROM\s+.+$', "FROM $BaseModel"
    Set-Content -Path $Destination -Value $content -Encoding utf8
}

$normalTemp = Join-Path $tempDir 'Modelfile.normal'
$unrestrictedTemp = Join-Path $tempDir 'Modelfile.unrestricted'
Prepare-Modelfile $NormalFile $normalTemp
Prepare-Modelfile $UnrestrictedFile $unrestrictedTemp

Write-Host "Would create qwen3.6-35b-normal from $BaseModel"
Write-Host "Would create qwen3.6-35b-unrestricted from $BaseModel"

if (-not $Apply) {
    Write-Host "DRY RUN. Prepared files at $tempDir"
    exit 0
}

ollama create qwen3.6-35b-normal -f $normalTemp
if ($LASTEXITCODE -ne 0) { throw 'Failed to create normal model.' }

ollama create qwen3.6-35b-unrestricted -f $unrestrictedTemp
if ($LASTEXITCODE -ne 0) { throw 'Failed to create unrestricted model.' }

ollama show --modelfile qwen3.6-35b-normal
ollama show --modelfile qwen3.6-35b-unrestricted
Write-Host 'Model creation completed.'
