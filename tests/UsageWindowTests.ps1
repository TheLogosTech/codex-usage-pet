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
foreach ($name in @('Update-Usage', 'Get-UsageWindowLabel', 'Save-Settings', 'Save-WindowPosition', 'Set-WindowRow', 'Get-WindowName', 'Get-State', 'Set-Accent')) {
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
function New-Brush($color) { return $color }
function Set-ErrorState($message) {
    $CompactRemainingText.Text = '--'
    $DetailRemainingText.Text = '--'
    $script:reportedError = $message
}
$CompactRemainingText = @{}; $DetailRemainingText = @{}; $PlanText = @{}
$CompactUsageWindowText = @{}; $DetailUsageWindowText = @{}
$ResetExactText = @{}; $CreditsText = @{}; $window = @{ Resources = @{} }
$MoodText = @{}; $StatusDot = @{}
$FirstWindowPanel = @{}; $FirstWindowName = @{}; $FirstWindowValue = @{}; $FirstWindowProgress = @{}
$SecondWindowPanel = @{}; $SecondWindowName = @{}; $SecondWindowValue = @{}; $SecondWindowProgress = @{}
$script:settings = @{}

foreach ($reverse in @($false, $true)) {
    $fiveHour = @{ windowDurationMins = 300; usedPercent = 20 }
    $weekly = @{ windowDurationMins = 10080; usedPercent = 95 }
    $windows = if ($reverse) { @($weekly, $fiveHour) } else { @($fiveHour, $weekly) }
    $json = @{ result = @{ rateLimits = @{ primary = $windows[0]; secondary = $windows[1] } } } | ConvertTo-Json -Depth 6
    foreach ($case in @(@('Minimum', '5', 10080), @('FiveHour', '80', 300), @('Weekly', '5', 10080))) {
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
        Assert-Equal $FirstWindowValue.Foreground '#FF7DE2C0' 'Five-hour percentage stays green'
        Assert-Equal $FirstWindowProgress.Foreground '#FF7DE2C0' 'Five-hour bar stays green'
        Assert-Equal $SecondWindowValue.Foreground '#FFFF6B72' 'Weekly percentage stays red'
        Assert-Equal $SecondWindowProgress.Foreground '#FFFF6B72' 'Weekly bar stays red'
        $expectedAccent = if ($case[0] -eq 'FiveHour') { '#FF7DE2C0' } else { '#FFFF6B72' }
        Assert-Equal $window.Resources['StatusBrush'] $expectedAccent 'Overall accent follows selected window'
    }
}
$script:settings.UsageWindow = 'Minimum'
Update-Usage '{"result":{"rateLimits":{"primary":{"windowDurationMins":300,"usedPercent":95},"secondary":{"windowDurationMins":10080,"usedPercent":20}}}}'
Assert-Equal $CompactUsageWindowText.Text '5h' 'Minimum label switches to five-hour window'
Assert-Equal $DetailUsageWindowText.Text '5h' 'Detail minimum label switches to five-hour window'
Assert-Equal $FirstWindowProgress.Foreground '#FFFF6B72' 'Five-hour bar changes to red after refresh'
Assert-Equal $SecondWindowProgress.Foreground '#FF7DE2C0' 'Weekly bar changes to green after refresh'

foreach ($case in @(@(100, '#FF7DE2C0'), @(60, '#FF7DE2C0'), @(59, '#FFF5C76B'), @(30, '#FFF5C76B'), @(29, '#FFFF9B66'), @(10, '#FFFF9B66'), @(9, '#FFFF6B72'), @(0, '#FFFF6B72'))) {
    Set-WindowRow @{ windowDurationMins = 300; usedPercent = 100 - $case[0] } $FirstWindowPanel $FirstWindowName $FirstWindowValue $FirstWindowProgress
    Assert-Equal $FirstWindowValue.Foreground $case[1] "Percentage color at $($case[0])%"
    Assert-Equal $FirstWindowProgress.Foreground $case[1] "Bar color at $($case[0])%"
    Assert-Equal $FirstWindowProgress.Value $case[0] 'Bar remaining value'
}
Set-WindowRow $null $SecondWindowPanel $SecondWindowName $SecondWindowValue $SecondWindowProgress
Assert-Equal $SecondWindowPanel.Visibility 'Collapsed' 'Absent quota row stays hidden'

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
