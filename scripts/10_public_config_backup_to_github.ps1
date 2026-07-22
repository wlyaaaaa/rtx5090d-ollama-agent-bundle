param(
    [switch]$Apply,
    [string]$Branch = "codex/public-config-backup",
    [string]$Remote = "origin"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

$pathContract = Get-Content -LiteralPath "configs/public-backup-paths.json" -Raw | ConvertFrom-Json
if ($pathContract.schema -ne "rtx5090d.public-backup-paths.v1") {
    throw "Unsupported public backup path contract: $($pathContract.schema)"
}
$publicBackupPaths = @($pathContract.paths | ForEach-Object { [string]$_ })

$allowList = @($publicBackupPaths + "SHA256SUMS.txt")

function Write-PublicBackupChecksums {
    param(
        [string[]]$Paths
    )

    $lines = @()
    foreach ($path in $Paths) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $items = @(Get-Item -LiteralPath $path)
        } elseif (Test-Path -LiteralPath $path -PathType Container) {
            $items = @(Get-ChildItem -LiteralPath $path -Recurse -File)
        } else {
            $items = @()
        }

        foreach ($item in $items) {
            $relative = Resolve-Path -LiteralPath $item.FullName -Relative
            $relative = $relative -replace "^\.\\", ""
            $relative = $relative -replace "\\", "/"
            $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.FullName).Hash.ToLowerInvariant()
            $lines += "$hash  $relative"
        }
    }

    $lines | Sort-Object -Unique | Set-Content -LiteralPath "SHA256SUMS.txt" -Encoding utf8
}

$currentBranch = (git branch --show-current).Trim()
if ($currentBranch -ne $Branch) {
    $exists = git branch --list $Branch
    if ($exists) {
        git switch $Branch
    } else {
        git switch -c $Branch
    }
}

git reset --quiet

Write-PublicBackupChecksums -Paths $publicBackupPaths

foreach ($path in $allowList) {
    if (Test-Path -LiteralPath $path) {
        git add -- $path
    }
}

$stagedFiles = @(git diff --cached --name-only)
if ($stagedFiles.Count -eq 0) {
    Write-Host "No public config backup changes to commit."
    exit 0
}

$secretPattern = "ghp_|sk-[A-Za-z0-9]|BEGIN [A-Z ]*PRIVATE KEY|password\s*[:=]|secret\s*[:=]|token\s*[:=]|C:\\Users\\10979|AppData\\Roaming\\xyz|AppData\\Local\\Temp"
$hits = @()
foreach ($file in $stagedFiles) {
    if (Test-Path -LiteralPath $file -PathType Leaf) {
        $matches = Select-String -LiteralPath $file -Pattern $secretPattern -CaseSensitive:$false
        foreach ($match in $matches) {
            if ($file -eq "scripts/10_public_config_backup_to_github.ps1" -and $match.Line -match '^\s*\$secretPattern\s*=') {
                continue
            }
            $hits += "${file}:$($match.LineNumber):$($match.Line.Trim())"
        }
    }
}

if ($hits.Count -gt 0) {
    git reset --quiet
    Write-Error ("Sensitive content scan failed:`n" + ($hits -join "`n"))
}

git diff --cached --check

if (-not $Apply) {
    Write-Host "Dry run only. Staged public backup files:"
    $stagedFiles | ForEach-Object { Write-Host "  $_" }
    Write-Host "Run with -Apply to commit and push."
    exit 0
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "Automated public config backup $timestamp"
git push -u $Remote $Branch
