param()

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifestPath = Join-Path $RepoRoot "SHA256SUMS.txt"
$contractPath = Join-Path $RepoRoot "configs/public-backup-paths.json"

$contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
if ($contract.schema -ne "rtx5090d.public-backup-paths.v1") {
    throw "Unsupported public backup path contract: $($contract.schema)"
}

$expectedFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($relativePath in @($contract.paths)) {
    $path = Join-Path $RepoRoot ([string]$relativePath -replace '/', '\')
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $items = @(Get-Item -LiteralPath $path)
    } elseif (Test-Path -LiteralPath $path -PathType Container) {
        $items = @(Get-ChildItem -LiteralPath $path -Recurse -File)
    } else {
        throw "Public backup path is missing: $relativePath"
    }
    foreach ($item in $items) {
        $relative = [System.IO.Path]::GetRelativePath($RepoRoot, $item.FullName).Replace('\', '/')
        [void]$expectedFiles.Add($relative)
    }
}

$manifest = @{}
$failures = [System.Collections.Generic.List[string]]::new()
foreach ($line in Get-Content -LiteralPath $manifestPath) {
    if ($line -notmatch '^([0-9a-f]{64})\s{2}(.+)$') {
        $failures.Add("malformed:$line")
        continue
    }
    $relative = $Matches[2]
    if ($manifest.ContainsKey($relative)) {
        $failures.Add("duplicate:$relative")
        continue
    }
    $manifest[$relative] = $Matches[1]
}

foreach ($relative in $expectedFiles) {
    if (-not $manifest.ContainsKey($relative)) {
        $failures.Add("missing_manifest_entry:$relative")
        continue
    }
    $path = Join-Path $RepoRoot ($relative -replace '/', '\')
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $manifest[$relative]) {
        $failures.Add("hash_mismatch:$relative")
    }
}
foreach ($relative in $manifest.Keys) {
    if (-not $expectedFiles.Contains([string]$relative)) {
        $failures.Add("unexpected_manifest_entry:$relative")
    }
}

$result = [ordered]@{
    schema = "rtx5090d.public-checksum-verification.v1"
    status = $(if ($failures.Count -eq 0) { "ok" } else { "failed" })
    expected_entries = $expectedFiles.Count
    manifest_entries = $manifest.Count
    failures = @($failures)
}
$result | ConvertTo-Json -Depth 4 -Compress
if ($failures.Count -gt 0) {
    exit 1
}
