[CmdletBinding()]
param(
    [ValidateRange(30, 3600)]
    [int]$RefreshSeconds = 120,
    [string]$PreviewPath,
    [ValidateSet('Hidden', 'Compact', 'Detail', 'ThemePicker', 'Settings')]
    [string]$PreviewState = 'Detail',
    [string]$PreviewTheme
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms
Add-Type -Path (Join-Path $PSScriptRoot 'CodexUsageClient.cs') -ReferencedAssemblies System.Web.Extensions
. (Join-Path $PSScriptRoot 'ResolveCodex.ps1')
[CodexUsagePet.DpiAwareness]::EnablePerMonitorV2()

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\CodexUsagePet-v1', [ref]$createdNew)
if (-not $createdNew) {
    $mutex.Dispose()
    return
}

$settingsDirectory = Join-Path $env:LOCALAPPDATA 'CodexUsagePet'
$settingsPath = Join-Path $settingsDirectory 'settings.json'
$script:settings = [ordered]@{
    Edge = 'Right'
    Left = $null
    Top = $null
    Theme = 'Owl'
    UsageWindow = 'Minimum'
    Language = 'Auto'
}

if (Test-Path -LiteralPath $settingsPath) {
    try {
        $saved = Get-Content -Raw -Encoding UTF8 -LiteralPath $settingsPath | ConvertFrom-Json
        if ($saved.UsageWindow -in @('Minimum', 'FiveHour', 'Weekly')) {
            $script:settings.UsageWindow = [string]$saved.UsageWindow
        }
        if ($saved.Language -in @('Auto', 'zh-CN', 'en-US')) { $script:settings.Language = [string]$saved.Language }
        if ($saved.Edge -in @('Top', 'Bottom', 'Left', 'Right')) { $script:settings.Edge = $saved.Edge }
        if ($null -ne $saved.Left) { $script:settings.Left = [double]$saved.Left }
        if ($null -ne $saved.Top) { $script:settings.Top = [double]$saved.Top }
        if ($saved.Theme -in @('Owl', 'Fox', 'MechaCat', 'CloudBunny', 'EmberDragon', 'AuroraPenguin', 'SpaceShiba', 'BambooPanda', 'PixelSlime', 'DuneElephant')) {
            $script:settings.Theme = [string]$saved.Theme
        }
    } catch { }
}

. (Join-Path $PSScriptRoot 'Localization.ps1')
$script:localization = Get-PetLocalization $script:settings.Language

if ($PreviewTheme -in @('Owl', 'Fox', 'MechaCat', 'CloudBunny', 'EmberDragon', 'AuroraPenguin', 'SpaceShiba', 'BambooPanda', 'PixelSlime', 'DuneElephant')) {
    $script:settings.Theme = $PreviewTheme
}

function Save-Settings {
    if (-not (Test-Path -LiteralPath $settingsDirectory)) {
        [void][System.IO.Directory]::CreateDirectory($settingsDirectory)
    }
    $json = $script:settings | ConvertTo-Json
    [System.IO.File]::WriteAllText($settingsPath, $json, (New-Object System.Text.UTF8Encoding($false)))
}

$xaml = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot '..\ui\CodexUsagePetV2.xaml')

$reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$names = @(
    'HiddenView', 'HiddenDragSurface', 'HiddenAvatar', 'CompactView', 'CompactDragSurface', 'CompactAvatar', 'CompactAvatarColumn',
    'CompactRemainingText', 'CompactPercentText', 'CompactUsageWindowText', 'DetailUsageWindowText', 'DetailView', 'DetailHeader', 'StatusDot',
    'SettingsButton', 'SettingsView', 'SettingsTitle', 'SettingsPercentageLabel',
    'SettingsMinimum', 'SettingsFiveHour', 'SettingsWeekly',
    'SettingsBackButton', 'SettingsCancelButton', 'SettingsApplyButton',
    'ThemeButton', 'DetailAvatar', 'PlanText', 'DetailRemainingText', 'MoodText',
    'FirstWindowPanel', 'FirstWindowName', 'FirstWindowValue', 'FirstWindowProgress',
    'SecondWindowPanel', 'SecondWindowName', 'SecondWindowValue', 'SecondWindowProgress',
    'FirstWindowResetText', 'SecondWindowResetText',
    'FirstWindowTimeProgress', 'SecondWindowTimeProgress',
    'FirstWindowTimeText', 'SecondWindowTimeText',
    'CreditsText',
    'RefreshButton', 'CloseButton', 'ThemePickerView', 'ThemeBackButton',
    'CurrentThemeLabel', 'ThemePreviewPanel', 'ThemePreviewAvatar', 'ThemePreviewMiniAvatar',
    'ThemePreviewName', 'ThemePreviewDescription', 'ThemePreviewPercent', 'ThemePreviewCompact',
    'ThemeGrid', 'ThemeCancelButton', 'ThemeApplyButton'
)
foreach ($name in $names) {
    Set-Variable -Name $name -Value $window.FindName($name) -Scope Script
}

$FirstWindowResetText.Text = $script:localization.Strings.ResetTime -f '--'
$SecondWindowResetText.Text = $FirstWindowResetText.Text

$usageWindowLabel = switch ($script:settings.UsageWindow) {
    'FiveHour' { '5h' }
    'Weekly' { '1w' }
    default { '--' }
}
if ($usageWindowLabel) {
    $CompactUsageWindowText.Text = $usageWindowLabel
    $DetailUsageWindowText.Text = $usageWindowLabel
    $CompactUsageWindowText.Visibility = 'Visible'
    $DetailUsageWindowText.Visibility = 'Visible'
    $CompactView.Width = 140
}

function New-Brush([string]$color) {
    return [Windows.Media.BrushConverter]::new().ConvertFromString($color)
}

$script:themes = [ordered]@{
    Owl = [ordered]@{ Name = '夜枭守卫'; Avatar = 'Owl'; Description = '冷静、专注的深夜搭档'; Surface = '#FF111827'; Panel = '#FF1B263B'; Border = '#FF42526C'; Text = '#FFF8FAFC'; Muted = '#FFB8C4D6'; Track = '#FF2A3850'; Accent = '#FF7DE2C0'; Warm = '#FFFF7757'; Button = '#FF26344C'; ButtonHover = '#FF31415D' }
    Fox = [ordered]@{ Name = '星云狐'; Avatar = 'Fox'; Description = '灵动、好奇的星空探险家'; Surface = '#FF17142B'; Panel = '#FF24203D'; Border = '#FF514B78'; Text = '#FFFBF9FF'; Muted = '#FFC6BEDD'; Track = '#FF353052'; Accent = '#FF6FE7F7'; Warm = '#FFFFB86B'; Button = '#FF302A50'; ButtonHover = '#FF3B3460' }
    MechaCat = [ordered]@{ Name = '机械猫'; Avatar = 'MechaCat'; Description = '高效、精准的桌面工程师'; Surface = '#FF121714'; Panel = '#FF1C241F'; Border = '#FF46554B'; Text = '#FFF4F8F5'; Muted = '#FFABB9B0'; Track = '#FF303A33'; Accent = '#FFB7F34A'; Warm = '#FFF7C65D'; Button = '#FF29332C'; ButtonHover = '#FF344038' }
    CloudBunny = [ordered]@{ Name = '云朵兔'; Avatar = 'CloudBunny'; Description = '轻盈、温柔的白日陪伴'; Surface = '#FFFFFDF8'; Panel = '#FFF2F7FB'; Border = '#FFC9D8E6'; Text = '#FF263849'; Muted = '#FF61788C'; Track = '#FFDCE7EF'; Accent = '#FF4FAED1'; Warm = '#FFF59A76'; Button = '#FFE6F0F6'; ButtonHover = '#FFD8E8F1' }
    EmberDragon = [ordered]@{ Name = '熔岩龙'; Avatar = 'EmberDragon'; Description = '热情、坚定的高能守护者'; Surface = '#FF211317'; Panel = '#FF321A20'; Border = '#FF6A3941'; Text = '#FFFFF7F2'; Muted = '#FFD7B8B5'; Track = '#FF4A2930'; Accent = '#FFFF6B35'; Warm = '#FFF5C451'; Button = '#FF49242B'; ButtonHover = '#FF5A2C35' }
    AuroraPenguin = [ordered]@{ Name = '极光企鹅'; Avatar = 'AuroraPenguin'; Description = '清爽、稳定的极地观测员'; Surface = '#FF082F3A'; Panel = '#FF0E4652'; Border = '#FF2E6670'; Text = '#FFF3FCFF'; Muted = '#FFA9CDD3'; Track = '#FF1D5660'; Accent = '#FF61D6E6'; Warm = '#FFF6C66B'; Button = '#FF155763'; ButtonHover = '#FF1C6673' }
    SpaceShiba = [ordered]@{ Name = '太空柴犬'; Avatar = 'SpaceShiba'; Description = '乐观、可靠的轨道领航员'; Surface = '#FF151C2B'; Panel = '#FF202A3F'; Border = '#FF4B5875'; Text = '#FFFFF8EB'; Muted = '#FFC8C0B2'; Track = '#FF34415C'; Accent = '#FFFF8A3D'; Warm = '#FF75D7E8'; Button = '#FF2B3750'; ButtonHover = '#FF35435F' }
    BambooPanda = [ordered]@{ Name = '竹影熊猫'; Avatar = 'BambooPanda'; Description = '沉稳、治愈的专注护航员'; Surface = '#FF151916'; Panel = '#FF202722'; Border = '#FF48584D'; Text = '#FFF6F3E8'; Muted = '#FFB9C1B6'; Track = '#FF344139'; Accent = '#FF5FD0A5'; Warm = '#FFA9C66B'; Button = '#FF2B342E'; ButtonHover = '#FF354039' }
    PixelSlime = [ordered]@{ Name = '像素史莱姆'; Avatar = 'PixelSlime'; Description = '活泼、复古的像素小伙伴'; Surface = '#FF19152E'; Panel = '#FF252044'; Border = '#FF514B77'; Text = '#FFFFF7FD'; Muted = '#FFC8C0DB'; Track = '#FF38315B'; Accent = '#FF4DE3C1'; Warm = '#FFF472B6'; Button = '#FF302956'; ButtonHover = '#FF3B3367' }
    DuneElephant = [ordered]@{ Name = '沙丘小象'; Avatar = 'DuneElephant'; Description = '温暖、踏实的长程伙伴'; Surface = '#FFFFF8EC'; Panel = '#FFF3E7D2'; Border = '#FFD9BE98'; Text = '#FF3B3028'; Muted = '#FF756353'; Track = '#FFE3D2B7'; Accent = '#FFCF6B4C'; Warm = '#FF5D9275'; Button = '#FFEAD9BE'; ButtonHover = '#FFDFC9A8' }
}
$script:themeOrder = @($script:themes.Keys)
$script:themeButtons = @{}
$script:pendingTheme = $script:settings.Theme

function Apply-Theme([string]$themeId, [bool]$persist = $false) {
    if (-not $script:themes.Contains($themeId)) { $themeId = 'Owl' }
    $theme = $script:themes[$themeId]
    $resourceMap = [ordered]@{
        SurfaceBrush = $theme.Surface; SurfaceRaisedBrush = $theme.Panel; BorderBrush = $theme.Border
        TextBrush = $theme.Text; MutedBrush = $theme.Muted; TrackBrush = $theme.Track
        ThemeAccentBrush = $theme.Accent; ThemeWarmBrush = $theme.Warm
        ButtonBrush = $theme.Button; ButtonHoverBrush = $theme.ButtonHover
    }
    foreach ($resourceName in $resourceMap.Keys) { $window.Resources[$resourceName] = New-Brush $resourceMap[$resourceName] }
    $avatarTemplate = $window.Resources[('Avatar{0}' -f $theme.Avatar)]
    foreach ($avatar in @($HiddenAvatar, $CompactAvatar, $DetailAvatar)) { $avatar.ContentTemplate = $avatarTemplate }
    $CurrentThemeLabel.Text = ('当前：{0}' -f $theme.Name)
    $script:settings.Theme = $themeId
    if ($persist) { Save-Settings }
}

function Update-ThemeSelection([string]$themeId) {
    if (-not $script:themes.Contains($themeId)) { return }
    $script:pendingTheme = $themeId
    $theme = $script:themes[$themeId]
    $template = $window.Resources[('Avatar{0}' -f $theme.Avatar)]
    $ThemePreviewAvatar.ContentTemplate = $template
    $ThemePreviewMiniAvatar.ContentTemplate = $template
    $ThemePreviewName.Text = $theme.Name
    $ThemePreviewDescription.Text = $theme.Description
    $ThemePreviewPanel.Background = New-Brush $theme.Panel
    $ThemePreviewPanel.BorderBrush = New-Brush $theme.Border
    $ThemePreviewCompact.Background = New-Brush $theme.Surface
    $ThemePreviewCompact.BorderBrush = New-Brush $theme.Border
    $ThemePreviewName.Foreground = New-Brush $theme.Text
    $ThemePreviewDescription.Foreground = New-Brush $theme.Muted
    $ThemePreviewPercent.Foreground = New-Brush $theme.Text

    foreach ($id in $script:themeButtons.Keys) {
        $item = $script:themeButtons[$id]
        $selected = ($id -eq $themeId)
        $item.Button.BorderThickness = if ($selected) { [Windows.Thickness]::new(2) } else { [Windows.Thickness]::new(1) }
        $item.Button.BorderBrush = New-Brush $(if ($selected) { $script:themes[$id].Accent } else { $script:themes[$id].Border })
        $item.Badge.Visibility = if ($selected) { 'Visible' } else { 'Collapsed' }
    }
}

function New-ThemeCards {
    foreach ($themeId in $script:themeOrder) {
        $theme = $script:themes[$themeId]
        $button = New-Object Windows.Controls.Button
        $button.Tag = $themeId
        $button.Style = $window.Resources['ThemeCardButton']
        $button.Background = New-Brush $theme.Panel
        $button.BorderBrush = New-Brush $theme.Border
        [System.Windows.Automation.AutomationProperties]::SetName($button, ('选择主题 {0}' -f $theme.Name))

        $grid = New-Object Windows.Controls.Grid
        $grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition -Property @{ Width = [Windows.GridLength]::new(54) }))
        $grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition -Property @{ Width = [Windows.GridLength]::new(1, [Windows.GridUnitType]::Star) }))
        $grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition -Property @{ Width = [Windows.GridLength]::new(20) }))

        $avatar = New-Object Windows.Controls.ContentControl
        $avatar.Content = 'pet'; $avatar.ContentTemplate = $window.Resources[('Avatar{0}' -f $theme.Avatar)]
        $avatar.Margin = [Windows.Thickness]::new(0, 2, 8, 2)
        [Windows.Controls.Grid]::SetColumn($avatar, 0); [void]$grid.Children.Add($avatar)

        $textStack = New-Object Windows.Controls.StackPanel
        $textStack.VerticalAlignment = 'Center'; [Windows.Controls.Grid]::SetColumn($textStack, 1)
        $name = New-Object Windows.Controls.TextBlock
        $name.Text = $theme.Name; $name.Foreground = New-Brush $theme.Text; $name.FontFamily = 'Microsoft YaHei UI'; $name.FontSize = 12; $name.FontWeight = 'SemiBold'
        $description = New-Object Windows.Controls.TextBlock
        $description.Text = $theme.Description; $description.Foreground = New-Brush $theme.Muted; $description.FontFamily = 'Microsoft YaHei UI'; $description.FontSize = 9; $description.TextWrapping = 'Wrap'; $description.Margin = [Windows.Thickness]::new(0, 4, 0, 0)
        [void]$textStack.Children.Add($name); [void]$textStack.Children.Add($description); [void]$grid.Children.Add($textStack)

        $badge = New-Object Windows.Controls.Border
        $badge.Width = 20; $badge.Height = 20; $badge.CornerRadius = [Windows.CornerRadius]::new(10); $badge.Background = New-Brush $theme.Accent; $badge.VerticalAlignment = 'Top'
        [Windows.Controls.Grid]::SetColumn($badge, 2)
        $check = New-Object Windows.Controls.TextBlock
        $check.Text = '✓'; $check.Foreground = New-Brush $theme.Surface; $check.FontSize = 12; $check.FontWeight = 'Bold'; $check.HorizontalAlignment = 'Center'; $check.VerticalAlignment = 'Center'
        $badge.Child = $check; [void]$grid.Children.Add($badge)

        $button.Content = $grid
        $button.add_Click({ param($sender, $eventArgs); Update-ThemeSelection ([string]$sender.Tag) })
        [void]$ThemeGrid.Children.Add($button)
        $script:themeButtons[$themeId] = [pscustomobject]@{ Button = $button; Badge = $badge }
    }
}

function Ensure-ThemePicker {
    if ($script:themeButtons.Count -eq 0) { New-ThemeCards }
    Update-ThemeSelection $script:settings.Theme
}

function Get-WorkArea {
    try {
        $handle = (New-Object System.Windows.Interop.WindowInteropHelper($window)).Handle
        if ($handle -ne [IntPtr]::Zero) {
            $area = [System.Windows.Forms.Screen]::FromHandle($handle).WorkingArea
            return [pscustomobject]@{
                Left = [double]$area.Left
                Top = [double]$area.Top
                Right = [double]$area.Right
                Bottom = [double]$area.Bottom
            }
        }
    } catch { }
    $area = [System.Windows.SystemParameters]::WorkArea
    return [pscustomobject]@{ Left = $area.Left; Top = $area.Top; Right = $area.Right; Bottom = $area.Bottom }
}

function Get-ActualWidth { return [Math]::Max(1, [double]$window.ActualWidth) }
function Get-ActualHeight { return [Math]::Max(1, [double]$window.ActualHeight) }

function Clamp-WindowPosition([double]$left, [double]$top) {
    $area = Get-WorkArea
    $width = Get-ActualWidth
    $height = Get-ActualHeight
    return [pscustomobject]@{
        Left = [Math]::Max($area.Left, [Math]::Min($left, $area.Right - $width))
        Top = [Math]::Max($area.Top, [Math]::Min($top, $area.Bottom - $height))
    }
}

function Get-NearestEdge {
    $area = Get-WorkArea
    $width = Get-ActualWidth
    $height = Get-ActualHeight
    $distances = @(
        [pscustomobject]@{ Edge = 'Left'; Distance = [Math]::Abs($window.Left - $area.Left) },
        [pscustomobject]@{ Edge = 'Right'; Distance = [Math]::Abs($area.Right - ($window.Left + $width)) },
        [pscustomobject]@{ Edge = 'Top'; Distance = [Math]::Abs($window.Top - $area.Top) },
        [pscustomobject]@{ Edge = 'Bottom'; Distance = [Math]::Abs($area.Bottom - ($window.Top + $height)) }
    )
    return $distances | Sort-Object Distance | Select-Object -First 1
}

$script:viewState = 'Compact'
$script:hiddenEdge = $script:settings.Edge
$script:lastInteractionAt = [DateTime]::UtcNow

function Set-ViewState([ValidateSet('Hidden', 'Compact', 'Detail', 'ThemePicker', 'Settings')]$state, [bool]$fromHiddenDrag = $false) {
    $oldWidth = Get-ActualWidth
    $oldHeight = Get-ActualHeight
    $centerX = $window.Left + ($oldWidth / 2)
    $centerY = $window.Top + ($oldHeight / 2)
    $previous = $script:viewState

    if ($state -eq 'ThemePicker') { Ensure-ThemePicker }
    if ($state -eq 'Settings') { Initialize-SettingsView }
    $SettingsView.Visibility = if ($state -eq 'Settings') { 'Visible' } else { 'Collapsed' }
    $HiddenView.Visibility = if ($state -eq 'Hidden') { 'Visible' } else { 'Collapsed' }
    $CompactView.Visibility = if ($state -eq 'Compact') { 'Visible' } else { 'Collapsed' }
    $DetailView.Visibility = if ($state -eq 'Detail') { 'Visible' } else { 'Collapsed' }
    $ThemePickerView.Visibility = if ($state -eq 'ThemePicker') { 'Visible' } else { 'Collapsed' }
    $script:viewState = $state
    $window.UpdateLayout()

    $area = Get-WorkArea
    $width = Get-ActualWidth
    $height = Get-ActualHeight

    if ($state -eq 'Hidden') {
        switch ($script:hiddenEdge) {
            'Left' { $left = $area.Left + 1; $top = $centerY - ($height / 2) }
            'Right' { $left = $area.Right - $width - 1; $top = $centerY - ($height / 2) }
            'Top' { $left = $centerX - ($width / 2); $top = $area.Top + 1 }
            'Bottom' { $left = $centerX - ($width / 2); $top = $area.Bottom - $height - 1 }
        }
        $position = Clamp-WindowPosition $left $top
    } elseif ($previous -eq 'Hidden' -and -not $fromHiddenDrag) {
        switch ($script:hiddenEdge) {
            'Left' { $left = $area.Left + 5; $top = $centerY - ($height / 2) }
            'Right' { $left = $area.Right - $width - 5; $top = $centerY - ($height / 2) }
            'Top' { $left = $centerX - ($width / 2); $top = $area.Top + 5 }
            'Bottom' { $left = $centerX - ($width / 2); $top = $area.Bottom - $height - 5 }
        }
        $position = Clamp-WindowPosition $left $top
    } else {
        $position = Clamp-WindowPosition ($centerX - ($width / 2)) ($centerY - ($height / 2))
    }

    $window.Left = $position.Left
    $window.Top = $position.Top
    $script:lastInteractionAt = [DateTime]::UtcNow
}

function Initialize-SettingsView {
    $SettingsTitle.Text = $script:localization.Strings.SettingsTitle
    $SettingsPercentageLabel.Text = $script:localization.Strings.DisplayPercentage
    $SettingsMinimum.Content = $script:localization.Strings.LowestRemaining
    $SettingsFiveHour.Content = $script:localization.Strings.FiveHourRemaining
    $SettingsWeekly.Content = $script:localization.Strings.WeeklyRemaining
    $SettingsCancelButton.Content = $script:localization.Strings.Cancel
    $SettingsApplyButton.Content = $script:localization.Strings.Apply
    $SettingsBackButton.ToolTip = $script:localization.Strings.Cancel
    [Windows.Automation.AutomationProperties]::SetName($SettingsBackButton, $script:localization.Strings.Cancel)
    foreach ($option in @($SettingsMinimum, $SettingsFiveHour, $SettingsWeekly)) {
        $option.IsChecked = $option.Tag -eq $script:settings.UsageWindow
    }
}

function Close-SettingsView([bool]$apply) {
    if ($apply) {
        $selected = @($SettingsMinimum, $SettingsFiveHour, $SettingsWeekly) | Where-Object { $_.IsChecked } | Select-Object -First 1
        if ($selected -and $selected.Tag -in @('Minimum', 'FiveHour', 'Weekly')) {
            $script:settings.UsageWindow = [string]$selected.Tag
            Save-Settings
            if ($client.LatestJson) { Update-Usage $client.LatestJson }
            else { Set-LoadingState }
        }
    }
    Set-ViewState 'Detail'
}
function Show-ThemePicker {
    Ensure-ThemePicker
    Set-ViewState 'ThemePicker'
    $ThemeBackButton.Focus() | Out-Null
}

function Close-ThemePicker([bool]$apply) {
    if ($apply) { Apply-Theme $script:pendingTheme $true }
    else { $script:pendingTheme = $script:settings.Theme }
    Set-ViewState 'Detail'
}

function Move-ThemeSelection([int]$offset) {
    $index = [Array]::IndexOf([object[]]$script:themeOrder, $script:pendingTheme)
    if ($index -lt 0) { $index = 0 }
    $next = ($index + $offset) % $script:themeOrder.Count
    if ($next -lt 0) { $next += $script:themeOrder.Count }
    Update-ThemeSelection $script:themeOrder[$next]
    $script:themeButtons[$script:pendingTheme].Button.BringIntoView()
}

function Hide-ToEdge([ValidateSet('Top', 'Bottom', 'Left', 'Right')]$edge) {
    $script:hiddenEdge = $edge
    $script:settings.Edge = $edge
    Save-Settings
    Set-ViewState 'Hidden'
}

function Save-WindowPosition {
    $script:settings.Left = [Math]::Round($window.Left, 1)
    $script:settings.Top = [Math]::Round($window.Top, 1)
    Save-Settings
}

function Get-WindowName($quotaWindow) {
    $minutes = [long]$quotaWindow.windowDurationMins
    if ($minutes -eq 10080) { return '每周余量' }
    if ($minutes -eq 1440) { return '每日余量' }
    if ($minutes -gt 0 -and $minutes -lt 1440 -and ($minutes % 60) -eq 0) { return ('{0} 小时余量' -f ($minutes / 60)) }
    if ($minutes -gt 0) { return ('{0} 分钟余量' -f $minutes) }
    return '周期余量'
}

function Get-ResetExact($quotaWindow) {
    $value = '--'
    if ($quotaWindow -and $quotaWindow.resetsAt) {
        $reset = [DateTimeOffset]::FromUnixTimeSeconds([long]$quotaWindow.resetsAt).ToLocalTime()
        $value = $reset.ToString($script:localization.Strings.ResetDateFormat, $script:localization.Culture)
    }
    return ($script:localization.Strings.ResetTime -f $value)
}

function Get-State([int]$remaining) {
    if ($remaining -ge 60) { return @('#FF7DE2C0', '精力充沛') }
    if ($remaining -ge 30) { return @('#FFF5C76B', '状态不错') }
    if ($remaining -ge 10) { return @('#FFFF9B66', '有点困了') }
    return @('#FFFF6B72', '需要休息')
}

function Set-Accent([int]$remaining) {
    $state = Get-State $remaining
    $brush = New-Brush $state[0]
    $window.Resources['StatusBrush'] = $brush
    $MoodText.Text = $state[1]
    $MoodText.Foreground = $brush
    $StatusDot.Fill = $brush
}

function Get-TimeRemainingPercent($quotaWindow, [long]$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) {
    if (-not $quotaWindow -or -not $quotaWindow.resetsAt -or $quotaWindow.windowDurationMins -le 0) { return $null }
    return [Math]::Max(0, [Math]::Min(100, 100.0 * ([long]$quotaWindow.resetsAt - $now) / (60.0 * $quotaWindow.windowDurationMins)))
}

function Update-TimeBar($quotaWindow, $bar, $label) {
    $percent = Get-TimeRemainingPercent $quotaWindow
    $bar.Value = if ($null -eq $percent) { 0 } else { $percent }
    $value = '--'
    if ($null -ne $percent) {
        $minutes = [long][Math]::Ceiling([Math]::Max(0, [long]$quotaWindow.resetsAt - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) / 60.0)
        $days = [long][Math]::Floor($minutes / 1440.0)
        $hours = [long][Math]::Floor(($minutes % 1440) / 60.0)
        $value = $script:localization.Strings.RemainingDuration -f $days, $hours, ($minutes % 60)
    }
    $label.Text = $script:localization.Strings.TimeRemaining -f $value
    $bar.ToolTip = $label.Text
}
function Set-WindowRow($quotaWindow, $panel, $nameText, $valueText, $progress, $resetText, $timeProgress, $timeText) {
    if ($timeProgress) { $timeProgress.Tag = $quotaWindow; Update-TimeBar $quotaWindow $timeProgress $timeText }
    if (-not $quotaWindow) { $panel.Visibility = 'Collapsed'; return }
    $remaining = [Math]::Max(0, [Math]::Min(100, 100 - [int]$quotaWindow.usedPercent))
    $panel.Visibility = 'Visible'
    $nameText.Text = Get-WindowName $quotaWindow
    $valueText.Text = ('{0}%' -f $remaining)
    $progress.Value = $remaining
    $resetText.Text = Get-ResetExact $quotaWindow
    $state = Get-State $remaining
    $brush = New-Brush $state[0]
    $valueText.Foreground = $brush
    $progress.Foreground = $brush
}

function Update-Usage($json) {
    try {
        $payload = $json | ConvertFrom-Json
        $snapshot = $payload.result.rateLimits
        if (-not $snapshot) { throw 'Codex 没有返回额度快照。' }
        $quotaWindows = @(@($snapshot.primary, $snapshot.secondary) | Where-Object { $_ } | Sort-Object { if ($_.windowDurationMins) { [long]$_.windowDurationMins } else { [long]::MaxValue } })

        if ($script:settings.UsageWindow -in @('FiveHour', 'Weekly')) {
            $duration = if ($script:settings.UsageWindow -eq 'FiveHour') { 300 } else { 10080 }
            $limitingWindow = $quotaWindows | Where-Object { $_.windowDurationMins -eq $duration } | Select-Object -First 1
            if ($null -eq $limitingWindow) {
                throw ('Codex 没有返回所选额度窗口：{0}' -f $script:settings.UsageWindow)
            }
            $remaining = [Math]::Max(0, [Math]::Min(100, 100 - [int]$limitingWindow.usedPercent))
        } elseif ($quotaWindows.Count -eq 0) {
            $remaining = 100; $limitingWindow = $null
        } else {
            $remainingValues = @($quotaWindows | ForEach-Object { [Math]::Max(0, [Math]::Min(100, 100 - [int]$_.usedPercent)) })
            $remaining = [int]($remainingValues | Measure-Object -Minimum).Minimum
            $limitingWindow = $quotaWindows[[Array]::IndexOf($remainingValues, $remaining)]
        }

        $CompactRemainingText.Text = [string]$remaining
        $DetailRemainingText.Text = [string]$remaining
        $usageWindowLabel = Get-UsageWindowLabel $limitingWindow
        $CompactUsageWindowText.Text = $usageWindowLabel
        $DetailUsageWindowText.Text = $usageWindowLabel
        $PlanText.Text = if ($snapshot.planType) { ([string]$snapshot.planType).ToUpperInvariant() } else { '已连接' }
        if ($snapshot.individualLimit) {
            $CreditsText.Text = ('个人限额余量 {0}%' -f [int]$snapshot.individualLimit.remainingPercent)
        } elseif ($snapshot.credits -and $snapshot.credits.hasCredits) {
            $CreditsText.Text = ('积分余额 {0}' -f $snapshot.credits.balance)
        } else {
            $CreditsText.Text = '套餐内额度'
        }

        Set-WindowRow $quotaWindows[0] $FirstWindowPanel $FirstWindowName $FirstWindowValue $FirstWindowProgress $FirstWindowResetText $FirstWindowTimeProgress $FirstWindowTimeText
        Set-WindowRow $quotaWindows[1] $SecondWindowPanel $SecondWindowName $SecondWindowValue $SecondWindowProgress $SecondWindowResetText $SecondWindowTimeProgress $SecondWindowTimeText
        Set-Accent $remaining
        $window.ToolTip = ('Codex 剩余 {0}%' -f $remaining)
        $script:lastSuccessfulUpdate = [DateTime]::UtcNow
    } catch {
        Set-ErrorState $_.Exception.Message
    }
}

function Get-UsageWindowLabel($quotaWindow) {
    $minutes = [long]$quotaWindow.windowDurationMins
    if ($minutes -eq 10080) { return '1w' }
    if ($minutes -gt 0 -and $minutes % 60 -eq 0) { return ('{0}h' -f ($minutes / 60)) }
    if ($minutes -gt 0) { return ('{0}m' -f $minutes) }
    return '--'
}

function Set-LoadingState {
    $MoodText.Text = '正在刷新…'
    $MoodText.Foreground = $window.Resources['MutedBrush']
    $StatusDot.Fill = New-Brush '#FFF5C76B'
}

function Set-ErrorState([string]$message) {
    $CompactUsageWindowText.Text = '--'
    $DetailUsageWindowText.Text = '--'
    $CompactRemainingText.Text = '--'
    $DetailRemainingText.Text = '--'
    $PlanText.Text = '离线'
    $MoodText.Text = '暂时连不上'
    $MoodText.Foreground = New-Brush '#FFFF9B66'
    $StatusDot.Fill = New-Brush '#FFFF9B66'
    $window.ToolTip = $message
}

function Request-Refresh {
    Set-LoadingState
    try { $client.Refresh(); $script:lastRequestAt = [DateTime]::UtcNow }
    catch { Set-ErrorState $_.Exception.Message }
}

function Save-Preview([string]$path) {
    $window.UpdateLayout()
    $width = [Math]::Max(1, [int][Math]::Ceiling($window.ActualWidth))
    $height = [Math]::Max(1, [int][Math]::Ceiling($window.ActualHeight))
    $bitmap = New-Object Windows.Media.Imaging.RenderTargetBitmap($width, $height, 96, 96, [Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($window)
    $encoder = New-Object Windows.Media.Imaging.PngBitmapEncoder
    $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $directory = Split-Path -Parent $path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) { [void][System.IO.Directory]::CreateDirectory($directory) }
    $stream = [System.IO.File]::Create($path)
    try { $encoder.Save($stream) } finally { $stream.Dispose() }
}

function Invoke-StandardDrag([string]$surface) {
    $beforeLeft = $window.Left; $beforeTop = $window.Top
    try { $window.DragMove() } catch { return }
    $distance = [Math]::Abs($window.Left - $beforeLeft) + [Math]::Abs($window.Top - $beforeTop)
    $script:lastInteractionAt = [DateTime]::UtcNow

    if ($distance -lt 4) {
        if ($surface -eq 'Compact') { Set-ViewState 'Detail' }
        elseif ($surface -eq 'Detail') { Set-ViewState 'Compact' }
        return
    }

    $near = Get-NearestEdge
    if ($near.Distance -le 30) { Hide-ToEdge $near.Edge; return }
    Save-WindowPosition
}

$codexPath = Resolve-CodexExecutable
if (-not $codexPath) {
    [System.Windows.MessageBox]::Show('找不到 codex.exe。请先安装或更新 Codex 桌面应用/CLI。', 'Codex 余量宠物', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    $mutex.ReleaseMutex(); $mutex.Dispose(); return
}

$client = New-Object CodexUsagePet.CodexAppServerClient($codexPath)
$script:lastRevision = -1
$script:lastRequestAt = [DateTime]::UtcNow
$script:lastSuccessfulUpdate = [DateTime]::MinValue
$script:previewSaved = $false
$script:previewStartedAt = [DateTime]::UtcNow

Apply-Theme $script:settings.Theme $false

$initialArea = [System.Windows.SystemParameters]::WorkArea
$window.Left = if ($null -ne $script:settings.Left) { $script:settings.Left } else { $initialArea.Right - $CompactView.Width - 18 }
$window.Top = if ($null -ne $script:settings.Top) { $script:settings.Top } else { $initialArea.Bottom - $CompactView.Height - 18 }

$HiddenDragSurface.add_MouseLeftButtonDown({
    param($sender, $eventArgs)
    if ($eventArgs.ChangedButton -ne [System.Windows.Input.MouseButton]::Left) { return }
    $beforeLeft = $window.Left; $beforeTop = $window.Top
    try { $window.DragMove() } catch { return }
    $distance = [Math]::Abs($window.Left - $beforeLeft) + [Math]::Abs($window.Top - $beforeTop)
    Set-ViewState 'Compact' ($distance -ge 4)
    Save-WindowPosition
})

$CompactDragSurface.add_MouseLeftButtonDown({
    param($sender, $eventArgs)
    if ($eventArgs.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) { Invoke-StandardDrag 'Compact' }
})
$DetailHeader.add_MouseLeftButtonDown({
    param($sender, $eventArgs)
    if ($eventArgs.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) { Invoke-StandardDrag 'Detail' }
})

$SettingsButton.ToolTip = $script:localization.Strings.SettingsTitle
$SettingsButton.add_Click({ Set-ViewState 'Settings' })
$SettingsBackButton.add_Click({ Close-SettingsView $false })
$SettingsCancelButton.add_Click({ Close-SettingsView $false })
$SettingsApplyButton.add_Click({ Close-SettingsView $true })
$ThemeButton.add_Click({ Show-ThemePicker })
$ThemeBackButton.add_Click({ Close-ThemePicker $false })
$ThemeCancelButton.add_Click({ Close-ThemePicker $false })
$ThemeApplyButton.add_Click({ Close-ThemePicker $true })
$RefreshButton.add_Click({ Request-Refresh })
$CloseButton.add_Click({ $window.Close() })

$window.add_KeyDown({
    param($sender, $eventArgs)
    if ($eventArgs.Key -eq [System.Windows.Input.Key]::Escape) {
        if ($script:viewState -eq 'Settings') { Close-SettingsView $false }
        elseif ($script:viewState -eq 'ThemePicker') { Close-ThemePicker $false }
        elseif ($script:viewState -eq 'Detail') { Set-ViewState 'Compact' }
        else { Hide-ToEdge $script:hiddenEdge }
        $eventArgs.Handled = $true
    } elseif ($script:viewState -eq 'ThemePicker') {
        switch ($eventArgs.Key) {
            'Left' { Move-ThemeSelection -1; $eventArgs.Handled = $true }
            'Right' { Move-ThemeSelection 1; $eventArgs.Handled = $true }
            'Up' { Move-ThemeSelection -2; $eventArgs.Handled = $true }
            'Down' { Move-ThemeSelection 2; $eventArgs.Handled = $true }
            'Enter' { Close-ThemePicker $true; $eventArgs.Handled = $true }
        }
    } elseif ($eventArgs.Key -eq [System.Windows.Input.Key]::R) { Request-Refresh }
})

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(250)
$timer.add_Tick({
    $nowSecond = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($nowSecond -ne $script:lastTimeBarSecond) {
        $script:lastTimeBarSecond = $nowSecond
        Update-TimeBar $FirstWindowTimeProgress.Tag $FirstWindowTimeProgress $FirstWindowTimeText
        Update-TimeBar $SecondWindowTimeProgress.Tag $SecondWindowTimeProgress $SecondWindowTimeText
    }
    if ($client.Revision -ne $script:lastRevision) {
        $script:lastRevision = $client.Revision
        if ($client.LatestJson) {
            Update-Usage $client.LatestJson
            if ($PreviewPath -and -not $script:previewSaved) {
                $script:previewSaved = $true
                Set-ViewState $PreviewState
                $window.Dispatcher.BeginInvoke([Action]{ Save-Preview $PreviewPath; $window.Close() }, [System.Windows.Threading.DispatcherPriority]::ContextIdle) | Out-Null
            }
        }
    }

    if ($PreviewPath -and -not $script:previewSaved -and (([DateTime]::UtcNow - $script:previewStartedAt).TotalSeconds -ge 3)) {
        $script:previewSaved = $true
        Set-ViewState $PreviewState
        $window.Dispatcher.BeginInvoke([Action]{ Save-Preview $PreviewPath; $window.Close() }, [System.Windows.Threading.DispatcherPriority]::ContextIdle) | Out-Null
    }

    $sinceRequest = [DateTime]::UtcNow - $script:lastRequestAt
    if (-not $client.LatestJson -and $sinceRequest.TotalSeconds -gt 12) {
        $reason = if ($client.LatestError) { $client.LatestError } else { '读取超时，请确认 Codex 已登录。' }
        Set-ErrorState $reason
    }

    $sinceSuccess = [DateTime]::UtcNow - $script:lastSuccessfulUpdate
    $periodicDue = ($script:lastSuccessfulUpdate -ne [DateTime]::MinValue -and $sinceSuccess.TotalSeconds -ge $RefreshSeconds)
    $retryDue = (-not $client.LatestJson -and $sinceRequest.TotalSeconds -ge 30)
    if ($periodicDue -or $retryDue) { Request-Refresh }

})

$window.add_Closed({ $timer.Stop(); $client.Dispose() })
$window.add_ContentRendered({
    $interop = New-Object System.Windows.Interop.WindowInteropHelper($window)
    [CodexUsagePet.DpiAwareness]::EnsureWindowVisible($interop.Handle)
    $position = Clamp-WindowPosition $window.Left $window.Top
    $window.Left = $position.Left; $window.Top = $position.Top
})

$app = [System.Windows.Application]::Current
if (-not $app) { $app = New-Object System.Windows.Application }
$app.add_DispatcherUnhandledException({
    param($sender, $eventArgs)
    if ($PreviewPath) {
        try { [System.IO.File]::WriteAllText(($PreviewPath + '.error.txt'), $eventArgs.Exception.ToString()) } catch { }
        $eventArgs.Handled = $true
        $window.Close()
        return
    }
    Set-ErrorState $eventArgs.Exception.Message
    $eventArgs.Handled = $true
})

try {
    $client.Start()
    $timer.Start()
    [void]$app.Run($window)
} finally {
    $timer.Stop(); $client.Dispose()
    try { $mutex.ReleaseMutex() } catch { }
    $mutex.Dispose()
}
