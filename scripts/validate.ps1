[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$pluginRoot = Join-Path $repoRoot 'plugins\codex-usage-pet'
$manifestPath = Join-Path $pluginRoot '.codex-plugin\plugin.json'
$marketplacePath = Join-Path $repoRoot '.agents\plugins\marketplace.json'

function Assert-Valid {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-Valid (Test-Path -LiteralPath $manifestPath) "Missing plugin manifest: $manifestPath"
Assert-Valid (Test-Path -LiteralPath $marketplacePath) "Missing marketplace: $marketplacePath"

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
$marketplace = Get-Content -Raw -Encoding UTF8 -LiteralPath $marketplacePath | ConvertFrom-Json

Assert-Valid ($manifest.name -eq 'codex-usage-pet') 'Manifest name must be codex-usage-pet.'
Assert-Valid ($manifest.version -match '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$') 'Manifest version is not valid SemVer.'
Assert-Valid (-not [string]::IsNullOrWhiteSpace($manifest.description)) 'Manifest description is required.'
Assert-Valid (-not [string]::IsNullOrWhiteSpace($manifest.author.name)) 'Manifest author.name is required.'
Assert-Valid ($manifest.skills -eq './skills/') 'Manifest skills path must be ./skills/.'
Assert-Valid ($marketplace.name -eq 'codex-usage-pet') 'Unexpected marketplace name.'

$entry = @($marketplace.plugins | Where-Object { $_.name -eq $manifest.name }) | Select-Object -First 1
Assert-Valid ($null -ne $entry) 'Marketplace does not contain the plugin.'
Assert-Valid ($entry.source.source -eq 'local') 'Marketplace source must be local.'
Assert-Valid ($entry.source.path -eq './plugins/codex-usage-pet') 'Marketplace source path is incorrect.'
Assert-Valid ($entry.policy.installation -eq 'AVAILABLE') 'Marketplace installation policy must be AVAILABLE.'
Assert-Valid ($entry.policy.authentication -eq 'ON_INSTALL') 'Marketplace authentication policy must be ON_INSTALL.'

$assetReferences = @(
    $manifest.interface.composerIcon
    $manifest.interface.logo
    $manifest.interface.logoDark
) + @($manifest.interface.screenshots)

foreach ($reference in @($assetReferences | Where-Object { $_ })) {
    Assert-Valid ($reference.StartsWith('./')) "Asset path must start with ./: $reference"
    $relative = $reference.Substring(2).Replace('/', '\')
    $assetPath = Join-Path $pluginRoot $relative
    Assert-Valid (Test-Path -LiteralPath $assetPath) "Referenced asset does not exist: $reference"
}

$parseFailures = @()
Get-ChildItem -Recurse -File -Filter '*.ps1' -LiteralPath $repoRoot |
    ForEach-Object {
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $_.FullName,
            [ref]$tokens,
            [ref]$errors
        )
        foreach ($parseError in @($errors)) {
            $parseFailures += "$($_.FullName): $($parseError.Message)"
        }
    }

Assert-Valid ($parseFailures.Count -eq 0) ("PowerShell parse errors:`n" + ($parseFailures -join "`n"))

$skillPath = Join-Path $pluginRoot 'skills\codex-usage-pet\SKILL.md'
$skill = Get-Content -Raw -Encoding UTF8 -LiteralPath $skillPath
Assert-Valid ($skill -match '(?s)^---\r?\n.*?name:\s*codex-usage-pet\r?\n.*?description:\s*.+?\r?\n---') 'Skill frontmatter is missing or invalid.'

Add-Type -Path (Join-Path $pluginRoot 'scripts\CodexUsageClient.cs') -ReferencedAssemblies System.Web.Extensions
Assert-Valid ($null -ne ('CodexUsagePet.CodexAppServerClient' -as [type])) 'C# usage client did not compile.'

Write-Output 'Plugin validation passed.'
