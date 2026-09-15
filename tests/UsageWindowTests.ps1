[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repoRoot 'plugins\codex-usage-pet\scripts\CodexUsagePetV2.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Cannot test a script with parse errors.' }

# Load the actual production functions without starting WPF or an app-server.
foreach ($name in @('Update-Usage', 'Get-UsageWindowLabel', 'Save-Settings', 'Save-WindowPosition')) {
    $node = $ast.Find({ param($item)
        $item -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $item.Name -eq $name
    }, $true)
    if (-not $node) { throw "Missing production function: $name" }
    Invoke-Expression $node.Extent.Text
}
$defaults = $ast.EndBlock.Statements | Where-Object {
    $_ -is [System.Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -eq '$script:settings'
}
$loader = $ast.EndBlock.Statements | Where-Object {
    $_ -is [System.Management.Automation.Language.IfStatementAst] -and $_.Clauses[0].Item1.Extent.Text -eq 'Test-Path -LiteralPath $settingsPath'
}
if (@($defaults).Count -ne 1 -or @($loader).Count -ne 1) { throw 'Cannot identify production settings initialization.' }

function Assert-Equal($actual, $expected, [string]$name) {
    if ($actual -cne $expected) { throw "$name`: expected '$expected', got '$actual'" }
}

# Only UI dependencies are stubbed; selection and settings code run unchanged.
function Get-ResetExact($quotaWindow) { return $quotaWindow.windowDurationMins }
function Set-WindowRow { }
function Set-Accent { }
function Set-ErrorState($message) {
    $CompactRemainingText.Text = '--'
    $DetailRemainingText.Text = '--'
    $script:reportedError = $message
}
$CompactRemainingText = @{}; $DetailRemainingText = @{}; $PlanText = @{}
$CompactUsageWindowText = @{}; $DetailUsageWindowText = @{}
$ResetExactText = @{}; $CreditsText = @{}; $window = @{}
$script:settings = @{}

foreach ($reverse in @($false, $true)) {
    $fiveHour = @{ windowDurationMins = 300; usedPercent = 20 }
    $weekly = @{ windowDurationMins = 10080; usedPercent = 90 }
    $windows = if ($reverse) { @($weekly, $fiveHour) } else { @($fiveHour, $weekly) }
    $json = @{ result = @{ rateLimits = @{ primary = $windows[0]; secondary = $windows[1] } } } | ConvertTo-Json -Depth 6
    foreach ($case in @(@('Minimum', '10', 10080), @('FiveHour', '80', 300), @('Weekly', '10', 10080))) {
        $script:settings.UsageWindow = $case[0]
        $script:reportedError = $null
        Update-Usage $json
        Assert-Equal $reportedError $null "$($case[0]) error"
        Assert-Equal $CompactRemainingText.Text $case[1] "$($case[0]) compact percentage"
        Assert-Equal $DetailRemainingText.Text $case[1] "$($case[0]) detail percentage"
        Assert-Equal $ResetExactText.Text $case[2] "$($case[0]) reset window"
        $expectedLabel = if ($case[2] -eq 300) { '5h' } else { '1w' }
        Assert-Equal $CompactUsageWindowText.Text $expectedLabel 'Compact window label'
        Assert-Equal $DetailUsageWindowText.Text $expectedLabel 'Detail window label'
    }
}
$script:settings.UsageWindow = 'Minimum'
Update-Usage '{"result":{"rateLimits":{"primary":{"windowDurationMins":300,"usedPercent":95},"secondary":{"windowDurationMins":10080,"usedPercent":20}}}}'
Assert-Equal $CompactUsageWindowText.Text '5h' 'Minimum label switches to five-hour window'
Assert-Equal $DetailUsageWindowText.Text '5h' 'Detail minimum label switches to five-hour window'

foreach ($mode in @('FiveHour', 'Weekly')) {
    $script:settings.UsageWindow = $mode
    $otherDuration = if ($mode -eq 'FiveHour') { 10080 } else { 300 }
    $json = @{ result = @{ rateLimits = @{ primary = @{ windowDurationMins = $otherDuration; usedPercent = 30 } } } } | ConvertTo-Json -Depth 6
    Update-Usage $json
    Assert-Equal $CompactRemainingText.Text '--' "$mode unavailable"
    if (-not $reportedError) { throw 'Missing window must report an error.' }
}

# Use an isolated temporary file; never touch the installed pet's settings.
$settingsDirectory = Join-Path ([IO.Path]::GetTempPath()) ('usage-window-tests-' + [Guid]::NewGuid().ToString('N'))
$settingsPath = Join-Path $settingsDirectory 'settings.json'
[void][IO.Directory]::CreateDirectory($settingsDirectory)
try {
    Invoke-Expression $defaults.Extent.Text
    Invoke-Expression $loader.Extent.Text
    Assert-Equal $script:settings.UsageWindow 'Minimum' 'Fresh installation default'
    foreach ($case in @(@('{}', 'Minimum'), @('{"UsageWindow":"Invalid"}', 'Minimum'), @('{"UsageWindow":"FiveHour"}', 'FiveHour'), @('{"UsageWindow":"Weekly"}', 'Weekly'), @('{"UsageWindow":"Minimum"}', 'Minimum'))) {
        [IO.File]::WriteAllText($settingsPath, $case[0])
        Invoke-Expression $defaults.Extent.Text
        Invoke-Expression $loader.Extent.Text
        Assert-Equal $script:settings.UsageWindow $case[1] 'Loaded mode'
        $window.Left = 123
        $window.Top = 456
        Save-WindowPosition
        $savedSettings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
        Assert-Equal $savedSettings.UsageWindow $case[1] 'Mode preserved after position save'
        Assert-Equal $savedSettings.Left 123 'Position saved'
    }
} finally {
    if ([IO.File]::Exists($settingsPath)) { [IO.File]::Delete($settingsPath) }
    [IO.Directory]::Delete($settingsDirectory)
}
Write-Output 'Usage window selection and settings regression tests passed.'
