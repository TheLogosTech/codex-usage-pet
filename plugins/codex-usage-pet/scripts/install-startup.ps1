[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'Codex Usage Pet.lnk'
$startScript = Join-Path $PSScriptRoot 'start.ps1'

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = 'powershell.exe'
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}"' -f $startScript
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Description = 'Codex 余量宠物'
$shortcut.Save()

Write-Output "已启用开机启动：$shortcutPath"
