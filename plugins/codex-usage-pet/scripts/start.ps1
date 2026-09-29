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

# Check desktop visibility, not the hidden PowerShell console or launcher exit code.
. (Join-Path $PSScriptRoot 'PetWindow.ps1')
$windows = @(Get-PetWindow -ScriptPath $petScript)
if ($windows.Count -gt 0) {
    $windows
    return
}
$null = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -WindowStyle Hidden -PassThru
$deadline = [DateTime]::UtcNow.AddSeconds(15)
do {
    $windows = @(Get-PetWindow -ScriptPath $petScript)
    if ($windows.Count -gt 0) {
        $windows
        return
    }
    Start-Sleep -Milliseconds 500
} while ([DateTime]::UtcNow -lt $deadline)
throw 'No on-screen Usage Pet window was verified. Run this launcher on the interactive Windows desktop (with approved unsandboxed execution in Codex). An existing instance may also be hidden or off-screen. Do not report launch success.'
