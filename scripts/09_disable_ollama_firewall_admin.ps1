$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an Administrator PowerShell.'
}

netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no
netsh advfirewall firewall show rule name="ollama.exe" dir=in
