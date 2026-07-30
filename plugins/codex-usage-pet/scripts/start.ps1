[CmdletBinding()]
param(
    [ValidateRange(30, 3600)]
    [int]$RefreshSeconds = 120
)

$ErrorActionPreference = 'Stop'
$petScript = Join-Path $PSScriptRoot 'CodexUsagePetV2.ps1'

$arguments = @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-WindowStyle', 'Hidden',
    '-File', ('"{0}"' -f $petScript),
    '-RefreshSeconds', $RefreshSeconds
) -join ' '

Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -WindowStyle Hidden
