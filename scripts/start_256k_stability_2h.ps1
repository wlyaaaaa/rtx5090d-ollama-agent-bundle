param(
  [int]$DurationMinutes = 120,
  [string]$Model = "qwen-main-v1",
  [string]$HostUrl = "http://127.0.0.1:32100"
)

$ErrorActionPreference = "Stop"

$bundle = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$runRoot = Join-Path $bundle "results\stability"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir = Join-Path $runRoot "stability_256k_$stamp"
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$pythonScript = Join-Path $bundle "scripts\run_256k_stability_2h.py"
$runnerLog = Join-Path $runDir "runner.stdout.log"
$runnerErr = Join-Path $runDir "runner.stderr.log"
$durationSeconds = $DurationMinutes * 60

$arguments = @(
  $pythonScript,
  "--host", $HostUrl,
  "--model", $Model,
  "--duration-seconds", $durationSeconds,
  "--run-dir", $runDir
)

$process = Start-Process -FilePath "python.exe" -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput $runnerLog -RedirectStandardError $runnerErr -PassThru

$meta = [ordered]@{
  run_dir = $runDir
  pid = $process.Id
  started_at_local = (Get-Date).ToString("o")
  duration_minutes = $DurationMinutes
  model = $Model
  host = $HostUrl
  runner_log = $runnerLog
  runner_error_log = $runnerErr
}

$metaPath = Join-Path $runDir "launcher.json"
$meta | ConvertTo-Json -Depth 4 | Set-Content -Path $metaPath -Encoding UTF8

Write-Host "RUN_DIR=$runDir"
Write-Host "PID=$($process.Id)"
Write-Host "STATUS=$runDir\status.json"
Write-Host "EVENTS=$runDir\events.jsonl"
Write-Host "GPU=$runDir\gpu_samples.csv"
