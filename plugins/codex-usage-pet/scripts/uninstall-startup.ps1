[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'Codex Usage Pet.lnk'

if (Test-Path -LiteralPath $shortcutPath) {
    Remove-Item -LiteralPath $shortcutPath -Force
    Write-Output '已关闭 Codex 余量宠物的开机启动。'
} else {
    Write-Output '开机启动原本就是关闭的。'
}
