[CmdletBinding()]
param(
    [ValidateRange(30, 3600)]
    [int]$RefreshSeconds = 120,
    [string]$PreviewPath,
    [ValidateSet('Hidden', 'Compact', 'Detail', 'ThemePicker')]
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
}

if (Test-Path -LiteralPath $settingsPath) {
    try {
        $saved = Get-Content -Raw -Encoding UTF8 -LiteralPath $settingsPath | ConvertFrom-Json
        if ($saved.UsageWindow -in @('Minimum', 'FiveHour', 'Weekly')) {
            $script:settings.UsageWindow = [string]$saved.UsageWindow
        }
        if ($saved.Edge -in @('Top', 'Bottom', 'Left', 'Right')) { $script:settings.Edge = $saved.Edge }
        if ($null -ne $saved.Left) { $script:settings.Left = [double]$saved.Left }
        if ($null -ne $saved.Top) { $script:settings.Top = [double]$saved.Top }
        if ($saved.Theme -in @('Owl', 'Fox', 'MechaCat', 'CloudBunny', 'EmberDragon', 'AuroraPenguin', 'SpaceShiba', 'BambooPanda', 'PixelSlime', 'DuneElephant')) {
            $script:settings.Theme = [string]$saved.Theme
        }
    } catch { }
}

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

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="PetWindow"
        Title="Codex 余量宠物"
        SizeToContent="WidthAndHeight"
        WindowStyle="None" ResizeMode="NoResize"
        AllowsTransparency="True" Background="Transparent"
        Topmost="True" ShowInTaskbar="False"
        UseLayoutRounding="True" SnapsToDevicePixels="True">
    <Window.Resources>
        <SolidColorBrush x:Key="SurfaceBrush" Color="#FF111827" />
        <SolidColorBrush x:Key="SurfaceRaisedBrush" Color="#FF1B263B" />
        <SolidColorBrush x:Key="TextBrush" Color="#FFF8FAFC" />
        <SolidColorBrush x:Key="MutedBrush" Color="#FFB8C4D6" />
        <SolidColorBrush x:Key="TrackBrush" Color="#FF2A3850" />
        <SolidColorBrush x:Key="BorderBrush" Color="#FF42526C" />
        <SolidColorBrush x:Key="ButtonBrush" Color="#FF26344C" />
        <SolidColorBrush x:Key="ButtonHoverBrush" Color="#FF31415D" />
        <SolidColorBrush x:Key="ThemeAccentBrush" Color="#FF7DE2C0" />
        <SolidColorBrush x:Key="ThemeWarmBrush" Color="#FFFF7757" />
        <SolidColorBrush x:Key="StatusBrush" Color="#FF7DE2C0" />

        <DataTemplate x:Key="AvatarOwl">
            <Viewbox Stretch="Uniform">
                <Canvas Width="100" Height="116">
                    <Path Fill="#FF17305D" Data="M15,34 C5,24 7,8 24,17 C38,4 62,4 76,17 C93,8 95,24 85,34 L82,49 L18,49 Z" />
                    <Ellipse Canvas.Left="14" Canvas.Top="22" Width="72" Height="82" Fill="#FF17305D" />
                    <Ellipse Canvas.Left="22" Canvas.Top="35" Width="56" Height="48" Fill="#FFFFF8E8" />
                    <Ellipse Canvas.Left="25" Canvas.Top="39" Width="22" Height="25" Fill="#FFD8F5EA" Stroke="#FF17305D" StrokeThickness="3" />
                    <Ellipse Canvas.Left="53" Canvas.Top="39" Width="22" Height="25" Fill="#FFD8F5EA" Stroke="#FF17305D" StrokeThickness="3" />
                    <Ellipse Canvas.Left="32" Canvas.Top="47" Width="8" Height="10" Fill="#FF071426" />
                    <Ellipse Canvas.Left="60" Canvas.Top="47" Width="8" Height="10" Fill="#FF071426" />
                    <Path Fill="#FFFF7757" Data="M36,22 L47,29 L42,33 L28,24 L28,19 Z M64,22 L53,29 L58,33 L72,24 L72,19 Z" />
                    <Path Fill="#FFFF7757" Data="M46,63 L54,63 L50,70 Z" />
                    <Ellipse Canvas.Left="34" Canvas.Top="76" Width="32" Height="32" Fill="#FF0D203E" Stroke="#FFFFF8E8" StrokeThickness="3" />
                    <Path Stroke="#FF7DE2C0" StrokeThickness="5" StrokeStartLineCap="Round" Data="M50,82 A10,10 0 1 1 41,96" />
                    <Ellipse Canvas.Left="47" Canvas.Top="89" Width="6" Height="6" Fill="#FFFFF8E8" />
                </Canvas>
            </Viewbox>
        </DataTemplate>

        <DataTemplate x:Key="AvatarFox">
            <Viewbox Stretch="Uniform"><Canvas Width="100" Height="116">
                <Path Fill="#FFFF8B58" Data="M14,35 L20,8 L39,25 C46,21 54,21 61,25 L80,8 L86,35 C94,48 91,75 75,91 C61,105 39,105 25,91 C9,75 6,48 14,35 Z" />
                <Path Fill="#FF4B326A" Data="M20,9 L25,29 L38,24 Z M80,9 L75,29 L62,24 Z" />
                <Path Fill="#FFFFF2DE" Data="M19,52 C23,39 39,39 50,52 C61,39 77,39 81,52 C79,79 66,94 50,98 C34,94 21,79 19,52 Z" />
                <Path Fill="#FFFF8B58" Data="M50,47 C42,52 40,66 50,74 C60,66 58,52 50,47 Z" />
                <Ellipse Canvas.Left="31" Canvas.Top="51" Width="8" Height="12" Fill="#FF241A38" />
                <Ellipse Canvas.Left="61" Canvas.Top="51" Width="8" Height="12" Fill="#FF241A38" />
                <Path Fill="#FF241A38" Data="M45,70 L55,70 L50,77 Z" />
                <Path Stroke="#FF6FE7F7" StrokeThickness="5" StrokeStartLineCap="Round" Data="M28,95 C18,110 51,112 70,99" />
            </Canvas></Viewbox>
        </DataTemplate>

        <DataTemplate x:Key="AvatarMechaCat">
            <Viewbox Stretch="Uniform"><Canvas Width="100" Height="116">
                <Path Fill="#FF66746B" Stroke="#FFB7F34A" StrokeThickness="3" Data="M14,37 L18,13 L38,27 L62,27 L82,13 L86,37 L82,87 C73,102 27,102 18,87 Z" />
                <Path Fill="#FF1C241F" Data="M22,44 L78,44 L74,67 L26,67 Z" />
                <Path Stroke="#FFB7F34A" StrokeThickness="5" StrokeStartLineCap="Round" Data="M31,55 L42,55 M58,55 L69,55" />
                <Rectangle Canvas.Left="39" Canvas.Top="75" Width="22" Height="12" RadiusX="4" RadiusY="4" Fill="#FFB7F34A" />
                <Ellipse Canvas.Left="18" Canvas.Top="70" Width="10" Height="10" Fill="#FFF7C65D" />
                <Ellipse Canvas.Left="72" Canvas.Top="70" Width="10" Height="10" Fill="#FFF7C65D" />
                <Path Stroke="#FF7DD3B0" StrokeThickness="4" Data="M36,98 L36,108 M50,99 L50,111 M64,98 L64,108" />
            </Canvas></Viewbox>
        </DataTemplate>

        <DataTemplate x:Key="AvatarCloudBunny">
            <Viewbox Stretch="Uniform"><Canvas Width="100" Height="116">
                <Ellipse Canvas.Left="23" Canvas.Top="2" Width="20" Height="52" Fill="#FFF7FBFF" Stroke="#FF4FAED1" StrokeThickness="3" />
                <Ellipse Canvas.Left="57" Canvas.Top="2" Width="20" Height="52" Fill="#FFF7FBFF" Stroke="#FF4FAED1" StrokeThickness="3" />
                <Ellipse Canvas.Left="29" Canvas.Top="9" Width="8" Height="34" Fill="#FFF59A76" />
                <Ellipse Canvas.Left="63" Canvas.Top="9" Width="8" Height="34" Fill="#FFF59A76" />
                <Ellipse Canvas.Left="14" Canvas.Top="35" Width="72" Height="67" Fill="#FFF7FBFF" Stroke="#FF4FAED1" StrokeThickness="3" />
                <Ellipse Canvas.Left="31" Canvas.Top="57" Width="9" Height="12" Fill="#FF263849" />
                <Ellipse Canvas.Left="60" Canvas.Top="57" Width="9" Height="12" Fill="#FF263849" />
                <Ellipse Canvas.Left="46" Canvas.Top="69" Width="8" Height="6" Fill="#FFF59A76" />
                <Path Stroke="#FF2F9E8F" StrokeThickness="3" StrokeStartLineCap="Round" Data="M50,76 C45,84 38,81 38,77 M50,76 C55,84 62,81 62,77" />
                <Path Fill="#FFFFFFFF" Data="M18,92 C9,91 8,105 22,105 C26,113 39,109 39,101 C34,91 27,89 18,92 Z M82,92 C91,91 92,105 78,105 C74,113 61,109 61,101 C66,91 73,89 82,92 Z" />
            </Canvas></Viewbox>
        </DataTemplate>

        <DataTemplate x:Key="AvatarEmberDragon">
            <Viewbox Stretch="Uniform"><Canvas Width="100" Height="116">
                <Path Fill="#FFF5C451" Data="M23,29 L13,7 L36,22 M77,29 L87,7 L64,22" />
                <Path Fill="#FF8B3641" Data="M18,39 C8,22 4,51 16,61 C3,66 9,92 27,84 L73,84 C91,92 97,66 84,61 C96,51 92,22 82,39 Z" />
                <Ellipse Canvas.Left="20" Canvas.Top="24" Width="60" Height="78" Fill="#FFD9563C" />
                <Path Fill="#FFF6C96B" Data="M32,46 C41,37 59,37 68,46 L64,86 C57,98 43,98 36,86 Z" />
                <Ellipse Canvas.Left="32" Canvas.Top="48" Width="9" Height="12" Fill="#FF211317" />
                <Ellipse Canvas.Left="59" Canvas.Top="48" Width="9" Height="12" Fill="#FF211317" />
                <Path Fill="#FFFFF7F2" Data="M31,65 L42,69 L34,76 Z M69,65 L58,69 L66,76 Z" />
                <Path Fill="#FFFF8B45" Data="M45,87 C48,77 52,77 55,87 C60,94 55,104 50,110 C45,104 40,94 45,87 Z" />
            </Canvas></Viewbox>
        </DataTemplate>

        <DataTemplate x:Key="AvatarAuroraPenguin">
            <Viewbox Stretch="Uniform"><Canvas Width="100" Height="116">
                <Ellipse Canvas.Left="16" Canvas.Top="9" Width="68" Height="98" Fill="#FF0A3544" Stroke="#FF61D6E6" StrokeThickness="3" />
                <Ellipse Canvas.Left="27" Canvas.Top="31" Width="46" Height="62" Fill="#FFDDF8FF" />
                <Ellipse Canvas.Left="29" Canvas.Top="36" Width="9" Height="12" Fill="#FF082F3A" />
                <Ellipse Canvas.Left="62" Canvas.Top="36" Width="9" Height="12" Fill="#FF082F3A" />
                <Path Fill="#FFF6C66B" Data="M42,53 L58,53 L50,63 Z" />
                <Path Fill="#FF61D6E6" Data="M18,56 C3,65 7,86 26,88 Z M82,56 C97,65 93,86 74,88 Z" />
                <Path Stroke="#FFB982FF" StrokeThickness="4" StrokeStartLineCap="Round" Data="M28,23 C40,11 59,11 72,23" />
                <Path Stroke="#FF73F0BE" StrokeThickness="3" StrokeStartLineCap="Round" Data="M35,19 C44,13 56,13 65,19" />
                <Path Fill="#FFF6C66B" Data="M28,98 L45,98 L39,108 L24,108 Z M72,98 L55,98 L61,108 L76,108 Z" />
            </Canvas></Viewbox>
        </DataTemplate>

        <DataTemplate x:Key="AvatarSpaceShiba">
            <Viewbox Stretch="Uniform"><Canvas Width="100" Height="116">
                <Ellipse Canvas.Left="8" Canvas.Top="8" Width="84" Height="94" Fill="#FF27344E" Stroke="#FF75D7E8" StrokeThickness="4" />
                <Path Fill="#FFFF8A3D" Data="M24,43 L23,20 L41,34 C47,31 53,31 59,34 L77,20 L76,43 C83,55 79,82 66,91 C57,98 43,98 34,91 C21,82 17,55 24,43 Z" />
                <Path Fill="#FFFFE1B3" Data="M28,56 C34,47 43,50 50,58 C57,50 66,47 72,56 C72,78 62,91 50,94 C38,91 28,78 28,56 Z" />
                <Ellipse Canvas.Left="34" Canvas.Top="52" Width="8" Height="10" Fill="#FF151C2B" />
                <Ellipse Canvas.Left="58" Canvas.Top="52" Width="8" Height="10" Fill="#FF151C2B" />
                <Path Fill="#FF151C2B" Data="M45,68 L55,68 L50,76 Z" />
                <Path Stroke="#FFFFFFFF" StrokeThickness="3" StrokeStartLineCap="Round" Data="M15,51 C12,66 16,82 26,92 M85,51 C88,66 84,82 74,92" />
                <Ellipse Canvas.Left="73" Canvas.Top="18" Width="6" Height="6" Fill="#FFFFFFFF" />
                <Ellipse Canvas.Left="19" Canvas.Top="28" Width="4" Height="4" Fill="#FFFFFFFF" />
            </Canvas></Viewbox>
        </DataTemplate>

        <DataTemplate x:Key="AvatarBambooPanda">
            <Viewbox Stretch="Uniform"><Canvas Width="100" Height="116">
                <Ellipse Canvas.Left="14" Canvas.Top="12" Width="28" Height="28" Fill="#FF202722" />
                <Ellipse Canvas.Left="58" Canvas.Top="12" Width="28" Height="28" Fill="#FF202722" />
                <Ellipse Canvas.Left="13" Canvas.Top="23" Width="74" Height="79" Fill="#FFF6F3E8" Stroke="#FF48584D" StrokeThickness="3" />
                <Ellipse Canvas.Left="25" Canvas.Top="44" Width="23" Height="28" Fill="#FF202722" RenderTransformOrigin="0.5,0.5"><Ellipse.RenderTransform><RotateTransform Angle="-20" /></Ellipse.RenderTransform></Ellipse>
                <Ellipse Canvas.Left="52" Canvas.Top="44" Width="23" Height="28" Fill="#FF202722" RenderTransformOrigin="0.5,0.5"><Ellipse.RenderTransform><RotateTransform Angle="20" /></Ellipse.RenderTransform></Ellipse>
                <Ellipse Canvas.Left="33" Canvas.Top="52" Width="7" Height="9" Fill="#FFF6F3E8" />
                <Ellipse Canvas.Left="60" Canvas.Top="52" Width="7" Height="9" Fill="#FFF6F3E8" />
                <Ellipse Canvas.Left="44" Canvas.Top="69" Width="12" Height="9" Fill="#FF202722" />
                <Path Stroke="#FF5FD0A5" StrokeThickness="5" StrokeStartLineCap="Round" Data="M72,94 L84,70 M79,80 L70,77 M80,79 L87,74" />
            </Canvas></Viewbox>
        </DataTemplate>

        <DataTemplate x:Key="AvatarPixelSlime">
            <Viewbox Stretch="Uniform"><Canvas Width="100" Height="116">
                <Path Fill="#FF4DE3C1" Stroke="#FF514B77" StrokeThickness="3" Data="M17,91 L17,55 L25,55 L25,39 L36,39 L36,27 L64,27 L64,39 L75,39 L75,55 L83,55 L83,91 L73,91 L73,101 L27,101 L27,91 Z" />
                <Rectangle Canvas.Left="30" Canvas.Top="55" Width="12" Height="15" Fill="#FF19152E" />
                <Rectangle Canvas.Left="58" Canvas.Top="55" Width="12" Height="15" Fill="#FF19152E" />
                <Rectangle Canvas.Left="34" Canvas.Top="59" Width="4" Height="5" Fill="#FFFFFFFF" />
                <Rectangle Canvas.Left="62" Canvas.Top="59" Width="4" Height="5" Fill="#FFFFFFFF" />
                <Path Stroke="#FF19152E" StrokeThickness="5" StrokeStartLineCap="Square" Data="M38,82 L45,88 L55,88 L62,82" />
                <Rectangle Canvas.Left="23" Canvas.Top="73" Width="7" Height="7" Fill="#FFF472B6" />
                <Rectangle Canvas.Left="70" Canvas.Top="73" Width="7" Height="7" Fill="#FFF8D66D" />
                <Rectangle Canvas.Left="45" Canvas.Top="15" Width="10" Height="10" Fill="#FFB982FF" />
            </Canvas></Viewbox>
        </DataTemplate>

        <DataTemplate x:Key="AvatarDuneElephant">
            <Viewbox Stretch="Uniform"><Canvas Width="100" Height="116">
                <Ellipse Canvas.Left="5" Canvas.Top="31" Width="42" Height="55" Fill="#FFCF6B4C" />
                <Ellipse Canvas.Left="53" Canvas.Top="31" Width="42" Height="55" Fill="#FFCF6B4C" />
                <Ellipse Canvas.Left="19" Canvas.Top="19" Width="62" Height="82" Fill="#FFF0B58E" Stroke="#FFD09A72" StrokeThickness="3" />
                <Ellipse Canvas.Left="31" Canvas.Top="49" Width="8" Height="11" Fill="#FF3B3028" />
                <Ellipse Canvas.Left="61" Canvas.Top="49" Width="8" Height="11" Fill="#FF3B3028" />
                <Path Fill="#FFF0B58E" Stroke="#FFD09A72" StrokeThickness="3" Data="M43,62 C42,82 40,105 53,108 C66,106 63,94 56,96 L57,62 Z" />
                <Path Stroke="#FF4D5D8C" StrokeThickness="4" StrokeStartLineCap="Round" Data="M30,29 C41,17 59,17 70,29" />
                <Path Stroke="#FF5D9275" StrokeThickness="4" StrokeStartLineCap="Round" Data="M71,91 C78,81 83,75 89,67" />
                <Path Fill="#FF5D9275" Data="M83,74 C76,69 79,61 88,64 C94,67 91,73 83,74 Z" />
            </Canvas></Viewbox>
        </DataTemplate>

        <Style x:Key="QuotaProgressStyle" TargetType="ProgressBar">
            <Setter Property="Height" Value="8" />
            <Setter Property="Minimum" Value="0" />
            <Setter Property="Maximum" Value="100" />
            <Setter Property="Foreground" Value="{DynamicResource StatusBrush}" />
            <Setter Property="Background" Value="{DynamicResource TrackBrush}" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Grid ClipToBounds="True">
                            <Border x:Name="PART_Track" Background="{TemplateBinding Background}" CornerRadius="4" />
                            <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}" CornerRadius="4" />
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ActionButton" TargetType="Button">
            <Setter Property="Height" Value="36" />
            <Setter Property="MinWidth" Value="78" />
            <Setter Property="Padding" Value="12,0" />
            <Setter Property="Margin" Value="0,0,8,0" />
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}" />
            <Setter Property="Background" Value="{DynamicResource ButtonBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="FontFamily" Value="Microsoft YaHei UI" />
            <Setter Property="FontSize" Value="12" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Chrome" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="10">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Chrome" Property="Background" Value="{DynamicResource ButtonHoverBrush}" /></Trigger>
                            <Trigger Property="IsPressed" Value="True"><Setter TargetName="Chrome" Property="Opacity" Value="0.72" /></Trigger>
                            <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource ThemeAccentBrush}" /><Setter TargetName="Chrome" Property="BorderThickness" Value="2" /></Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="IconButton" TargetType="Button">
            <Setter Property="Width" Value="44" /><Setter Property="Height" Value="44" />
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}" />
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" /><Setter Property="Cursor" Value="Hand" />
            <Setter Property="FontFamily" Value="Microsoft YaHei UI" /><Setter Property="FontSize" Value="20" />
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Chrome" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="12">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Chrome" Property="Background" Value="{DynamicResource ButtonBrush}" /></Trigger>
                    <Trigger Property="IsPressed" Value="True"><Setter TargetName="Chrome" Property="Opacity" Value="0.72" /></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>

        <Style x:Key="DetailActionButton" TargetType="Button">
            <Setter Property="Width" Value="44" /><Setter Property="Height" Value="44" />
            <Setter Property="Margin" Value="0,0,8,0" />
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}" />
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" /><Setter Property="Cursor" Value="Hand" />
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Chrome" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="12">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Chrome" Property="Background" Value="{DynamicResource SurfaceRaisedBrush}" />
                        <Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource ThemeAccentBrush}" />
                        <Setter Property="Foreground" Value="{DynamicResource ThemeAccentBrush}" />
                    </Trigger>
                    <MultiTrigger>
                        <MultiTrigger.Conditions><Condition Property="Tag" Value="Danger" /><Condition Property="IsMouseOver" Value="True" /></MultiTrigger.Conditions>
                        <Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource ThemeWarmBrush}" />
                        <Setter Property="Foreground" Value="{DynamicResource ThemeWarmBrush}" />
                    </MultiTrigger>
                    <Trigger Property="IsPressed" Value="True"><Setter TargetName="Chrome" Property="Opacity" Value="0.72" /></Trigger>
                    <Trigger Property="IsKeyboardFocused" Value="True">
                        <Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource ThemeAccentBrush}" />
                        <Setter TargetName="Chrome" Property="BorderThickness" Value="2" />
                        <Setter Property="Foreground" Value="{DynamicResource ThemeAccentBrush}" />
                    </Trigger>
                    <MultiTrigger>
                        <MultiTrigger.Conditions><Condition Property="Tag" Value="Danger" /><Condition Property="IsKeyboardFocused" Value="True" /></MultiTrigger.Conditions>
                        <Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource ThemeWarmBrush}" />
                        <Setter Property="Foreground" Value="{DynamicResource ThemeWarmBrush}" />
                    </MultiTrigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>

        <Style x:Key="ThemeCardButton" TargetType="Button">
            <Setter Property="Width" Value="174" /><Setter Property="Height" Value="84" />
            <Setter Property="Margin" Value="0,0,10,10" /><Setter Property="Padding" Value="10" />
            <Setter Property="BorderThickness" Value="1" /><Setter Property="Cursor" Value="Hand" />
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Chrome" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="14" Padding="{TemplateBinding Padding}">
                    <ContentPresenter HorizontalAlignment="Stretch" VerticalAlignment="Stretch" />
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Chrome" Property="Opacity" Value="0.88" /></Trigger>
                    <Trigger Property="IsPressed" Value="True"><Setter TargetName="Chrome" Property="Opacity" Value="0.68" /></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>

        <Style x:Key="ThemeScrollPageButton" TargetType="RepeatButton">
            <Setter Property="Focusable" Value="False" />
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="OverridesDefaultStyle" Value="True" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RepeatButton">
                        <Border Background="Transparent" />
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ThemeScrollThumb" TargetType="Thumb">
            <Setter Property="Width" Value="6" />
            <Setter Property="MinHeight" Value="36" />
            <Setter Property="Focusable" Value="False" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Grid Background="Transparent">
                            <Border x:Name="ThumbChrome"
                                    Width="6"
                                    HorizontalAlignment="Center"
                                    Background="{DynamicResource BorderBrush}"
                                    CornerRadius="3"
                                    Opacity="0.70" />
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ThumbChrome" Property="Background" Value="{DynamicResource ThemeAccentBrush}" />
                                <Setter TargetName="ThumbChrome" Property="Opacity" Value="0.90" />
                            </Trigger>
                            <Trigger Property="IsDragging" Value="True">
                                <Setter TargetName="ThumbChrome" Property="Background" Value="{DynamicResource ThemeAccentBrush}" />
                                <Setter TargetName="ThumbChrome" Property="Opacity" Value="1" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ThemeScrollBar" TargetType="ScrollBar">
            <Setter Property="Width" Value="10" />
            <Setter Property="MinWidth" Value="10" />
            <Setter Property="Margin" Value="0,4,4,4" />
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Width="10" Background="Transparent">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="{x:Static ScrollBar.PageUpCommand}" Style="{StaticResource ThemeScrollPageButton}" />
                                </Track.DecreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource ThemeScrollThumb}" />
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="{x:Static ScrollBar.PageDownCommand}" Style="{StaticResource ThemeScrollPageButton}" />
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <Grid>
        <Grid x:Name="HiddenView" Width="52" Height="52" Visibility="Collapsed">
            <Border Margin="4" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="22" Cursor="Hand">
                <Grid x:Name="HiddenDragSurface" Background="Transparent" ToolTip="点击或向桌面内拖拽，显示 Codex 余量" AutomationProperties.Name="展开 Codex 余量宠物">
                    <ContentControl x:Name="HiddenAvatar" Content="pet" ContentTemplate="{StaticResource AvatarOwl}" Margin="6" />
                </Grid>
            </Border>
        </Grid>

        <Grid x:Name="CompactView" Width="112" Height="52">
            <Border Margin="4" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="20" Cursor="Hand">
                <Grid x:Name="CompactDragSurface" Background="Transparent" AutomationProperties.Name="Codex 剩余用量，点击展开详情">
                    <Grid.ColumnDefinitions><ColumnDefinition x:Name="CompactAvatarColumn" Width="46" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                    <ContentControl x:Name="CompactAvatar" Grid.Column="0" Content="pet" ContentTemplate="{StaticResource AvatarOwl}" Margin="5,4,2,4" />
                    <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,8,1">
                        <TextBlock x:Name="CompactRemainingText" Text="--" Foreground="{DynamicResource TextBrush}" FontFamily="Microsoft YaHei UI" FontSize="27" FontWeight="Bold" />
                        <TextBlock x:Name="CompactPercentText" Text="%" Foreground="{DynamicResource MutedBrush}" FontFamily="Microsoft YaHei UI" FontSize="12" Margin="2,10,0,0" />
                        <TextBlock x:Name="CompactUsageWindowText" Visibility="Collapsed" Foreground="{DynamicResource MutedBrush}" FontSize="9" VerticalAlignment="Center" Margin="4,7,0,0" />
                    </StackPanel>
                </Grid>
            </Border>
        </Grid>

        <Grid x:Name="DetailView" Width="330" Visibility="Collapsed">
            <Border Margin="8" Padding="16" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="24">
                <StackPanel>
                    <Grid x:Name="DetailHeader" Height="62" Background="Transparent" Cursor="SizeAll" AutomationProperties.Name="拖动窗口，单击收起详情">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="62" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                        <ContentControl x:Name="DetailAvatar" Grid.Column="0" Content="pet" ContentTemplate="{StaticResource AvatarOwl}" Margin="3,0,8,0" IsHitTestVisible="False" />
                        <Grid Grid.Column="1">
                            <Grid.RowDefinitions><RowDefinition Height="Auto" /><RowDefinition Height="Auto" /></Grid.RowDefinitions>
                            <DockPanel Grid.Row="0" LastChildFill="False">
                                <Ellipse x:Name="StatusDot" Width="7" Height="7" Margin="0,1,7,0" Fill="#FF7DE2C0" VerticalAlignment="Center" />
                                <TextBlock Text="Codex Usage Limit" Foreground="{DynamicResource MutedBrush}" FontFamily="Microsoft YaHei UI" FontSize="11" FontWeight="SemiBold" />
                                <TextBlock x:Name="PlanText" Text="连接中" Foreground="{DynamicResource MutedBrush}" Opacity="0.72" FontFamily="Microsoft YaHei UI" FontSize="10" Margin="8,0,0,0" />
                            </DockPanel>
                            <StackPanel Grid.Row="1" Orientation="Horizontal">
                                <TextBlock x:Name="DetailRemainingText" Text="--" Foreground="{DynamicResource TextBrush}" FontFamily="Microsoft YaHei UI" FontSize="32" FontWeight="Bold" />
                                <TextBlock Text="%" Foreground="{DynamicResource MutedBrush}" FontFamily="Microsoft YaHei UI" FontSize="14" Margin="3,12,0,0" />
                                <TextBlock x:Name="DetailUsageWindowText" Visibility="Collapsed" Foreground="{DynamicResource MutedBrush}" FontFamily="Microsoft YaHei UI" FontSize="11" Margin="9,14,0,0" />
                                <TextBlock x:Name="MoodText" Text="正在唤醒…" Foreground="{DynamicResource StatusBrush}" FontFamily="Microsoft YaHei UI" FontSize="11" Margin="9,14,0,0" />
                            </StackPanel>
                        </Grid>
                    </Grid>

                    <Border Height="1" Background="{DynamicResource BorderBrush}" Opacity="0.65" Margin="0,9,0,12" />

                    <StackPanel>
                        <Border x:Name="FirstWindowPanel" Background="{DynamicResource SurfaceRaisedBrush}" CornerRadius="12" Padding="12,10" Margin="0,0,0,8">
                            <Grid>
                                <Grid.RowDefinitions><RowDefinition Height="Auto" /><RowDefinition Height="Auto" /></Grid.RowDefinitions>
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /></Grid.ColumnDefinitions>
                                <TextBlock x:Name="FirstWindowName" Text="周期余量" Foreground="{DynamicResource TextBrush}" FontFamily="Microsoft YaHei UI" FontSize="12" FontWeight="SemiBold" />
                                <TextBlock x:Name="FirstWindowValue" Grid.Column="1" Text="--%" Foreground="{DynamicResource StatusBrush}" FontFamily="Microsoft YaHei UI" FontSize="12" FontWeight="Bold" />
                                <ProgressBar x:Name="FirstWindowProgress" Grid.Row="1" Grid.ColumnSpan="2" Style="{StaticResource QuotaProgressStyle}" Margin="0,8,0,0" />
                            </Grid>
                        </Border>

                        <Border x:Name="SecondWindowPanel" Background="{DynamicResource SurfaceRaisedBrush}" CornerRadius="12" Padding="12,10" Margin="0,0,0,8" Visibility="Collapsed">
                            <Grid>
                                <Grid.RowDefinitions><RowDefinition Height="Auto" /><RowDefinition Height="Auto" /></Grid.RowDefinitions>
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /></Grid.ColumnDefinitions>
                                <TextBlock x:Name="SecondWindowName" Text="周期余量" Foreground="{DynamicResource TextBrush}" FontFamily="Microsoft YaHei UI" FontSize="12" FontWeight="SemiBold" />
                                <TextBlock x:Name="SecondWindowValue" Grid.Column="1" Text="--%" Foreground="{DynamicResource StatusBrush}" FontFamily="Microsoft YaHei UI" FontSize="12" FontWeight="Bold" />
                                <ProgressBar x:Name="SecondWindowProgress" Grid.Row="1" Grid.ColumnSpan="2" Style="{StaticResource QuotaProgressStyle}" Margin="0,8,0,0" />
                            </Grid>
                        </Border>
                    </StackPanel>

                    <DockPanel Margin="2,1,2,10">
                        <TextBlock x:Name="ResetExactText" DockPanel.Dock="Left" Text="重置时间：--" Foreground="{DynamicResource MutedBrush}" FontFamily="Microsoft YaHei UI" FontSize="10" />
                        <TextBlock x:Name="CreditsText" Text="本地读取" Foreground="{DynamicResource MutedBrush}" Opacity="0.72" FontFamily="Microsoft YaHei UI" FontSize="10" HorizontalAlignment="Right" VerticalAlignment="Top" />
                    </DockPanel>

                    <StackPanel Orientation="Horizontal">
                        <Button x:Name="ThemeButton" Style="{StaticResource DetailActionButton}" ToolTip="选择宠物主题" AutomationProperties.Name="选择宠物主题">
                            <Viewbox Width="20" Height="20"><Canvas Width="20" Height="20">
                                <Path Data="M10,2 C5.58,2 2,5.58 2,10 C2,14.42 5.58,18 10,18 L11.5,18 C12.33,18 13,17.33 13,16.5 C13,15.85 12.58,15.28 11.97,15.08 C11.4,14.9 11,14.36 11,13.75 C11,12.78 11.78,12 12.75,12 L14,12 C16.21,12 18,10.21 18,8 C18,4.69 14.42,2 10,2 Z" Fill="Transparent" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType={x:Type Button}}}" StrokeThickness="1.8" StrokeLineJoin="Round" />
                                <Ellipse Canvas.Left="5" Canvas.Top="6" Width="2.5" Height="2.5" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType={x:Type Button}}}" />
                                <Ellipse Canvas.Left="8.6" Canvas.Top="4" Width="2.5" Height="2.5" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType={x:Type Button}}}" />
                                <Ellipse Canvas.Left="12.4" Canvas.Top="5.2" Width="2.5" Height="2.5" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType={x:Type Button}}}" />
                            </Canvas></Viewbox>
                        </Button>
                        <Button x:Name="RefreshButton" Style="{StaticResource DetailActionButton}" ToolTip="立即刷新" AutomationProperties.Name="立即刷新 Codex 余量">
                            <Viewbox Width="20" Height="20"><Canvas Width="20" Height="20">
                                <Path Data="M17,4 L17,9 L12,9 M3,16 L3,11 L8,11 M4.7,7.2 C6,4.8 8.4,3.3 11.2,3.3 C13.5,3.3 15.6,4.4 17,6.1 M15.3,12.8 C14,15.2 11.6,16.7 8.8,16.7 C6.5,16.7 4.4,15.6 3,13.9" Fill="Transparent" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType={x:Type Button}}}" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" />
                            </Canvas></Viewbox>
                        </Button>
                        <Button x:Name="CloseButton" Tag="Danger" Style="{StaticResource DetailActionButton}" ToolTip="退出余量宠物" AutomationProperties.Name="退出 Codex 余量宠物" Margin="0">
                            <Viewbox Width="20" Height="20"><Canvas Width="20" Height="20">
                                <Path Data="M10,2 L10,10" Fill="Transparent" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType={x:Type Button}}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" />
                                <Path Data="M5.1,4.9 C2.4,7.6 2.4,12 5.1,14.7 C7.8,17.4 12.2,17.4 14.9,14.7 C17.6,12 17.6,7.6 14.9,4.9" Fill="Transparent" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType={x:Type Button}}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" />
                            </Canvas></Viewbox>
                        </Button>
                    </StackPanel>
                </StackPanel>
            </Border>
        </Grid>

        <Grid x:Name="ThemePickerView" Width="420" Visibility="Collapsed">
            <Border Margin="8" Padding="16" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="24">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="44" /><RowDefinition Height="12" /><RowDefinition Height="96" />
                        <RowDefinition Height="14" /><RowDefinition Height="350" /><RowDefinition Height="12" /><RowDefinition Height="44" />
                    </Grid.RowDefinitions>
                    <Grid Grid.Row="0">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="44" /><ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /></Grid.ColumnDefinitions>
                        <Button x:Name="ThemeBackButton" Grid.Column="0" Content="‹" Style="{StaticResource IconButton}" AutomationProperties.Name="返回详情" />
                        <StackPanel Grid.Column="1" Margin="12,1,0,0">
                            <TextBlock Text="选择宠物主题" Foreground="{DynamicResource TextBrush}" FontFamily="Microsoft YaHei UI" FontSize="17" FontWeight="Bold" />
                            <TextBlock Text="头像、配色与三种状态同步切换" Foreground="{DynamicResource MutedBrush}" FontFamily="Microsoft YaHei UI" FontSize="10" Margin="0,2,0,0" />
                        </StackPanel>
                        <Border Grid.Column="2" Background="{DynamicResource SurfaceRaisedBrush}" CornerRadius="10" Padding="9,0" Height="28" VerticalAlignment="Center">
                            <TextBlock x:Name="CurrentThemeLabel" Text="当前：夜枭守卫" Foreground="{DynamicResource ThemeAccentBrush}" FontFamily="Microsoft YaHei UI" FontSize="10" VerticalAlignment="Center" />
                        </Border>
                    </Grid>

                    <Border x:Name="ThemePreviewPanel" Grid.Row="2" Background="{DynamicResource SurfaceRaisedBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="16" Padding="12">
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="72" /><ColumnDefinition Width="*" /><ColumnDefinition Width="112" /></Grid.ColumnDefinitions>
                            <ContentControl x:Name="ThemePreviewAvatar" Grid.Column="0" Content="pet" ContentTemplate="{StaticResource AvatarOwl}" Margin="3" />
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="10,0,8,0">
                                <TextBlock x:Name="ThemePreviewName" Text="夜枭守卫" Foreground="{DynamicResource TextBrush}" FontFamily="Microsoft YaHei UI" FontSize="16" FontWeight="Bold" />
                                <TextBlock x:Name="ThemePreviewDescription" Text="冷静、专注的深夜搭档" Foreground="{DynamicResource MutedBrush}" TextWrapping="Wrap" FontFamily="Microsoft YaHei UI" FontSize="10" Margin="0,4,0,0" />
                            </StackPanel>
                            <Border x:Name="ThemePreviewCompact" Grid.Column="2" Width="108" Height="48" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="18" VerticalAlignment="Center">
                                <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="43" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                                    <ContentControl x:Name="ThemePreviewMiniAvatar" Content="pet" ContentTemplate="{StaticResource AvatarOwl}" Margin="5" />
                                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                                        <TextBlock x:Name="ThemePreviewPercent" Text="72" Foreground="{DynamicResource TextBrush}" FontFamily="Microsoft YaHei UI" FontSize="23" FontWeight="Bold" />
                                        <TextBlock Text="%" Foreground="{DynamicResource MutedBrush}" FontFamily="Microsoft YaHei UI" FontSize="10" Margin="2,8,0,0" />
                                    </StackPanel>
                                </Grid>
                            </Border>
                        </Grid>
                    </Border>

                    <ScrollViewer Grid.Row="4"
                                  VerticalScrollBarVisibility="Auto"
                                  HorizontalScrollBarVisibility="Disabled"
                                  Focusable="True"
                                  IsTabStop="True"
                                  AutomationProperties.Name="宠物主题列表">
                        <ScrollViewer.Resources>
                            <Style TargetType="ScrollBar" BasedOn="{StaticResource ThemeScrollBar}" />
                        </ScrollViewer.Resources>
                        <WrapPanel x:Name="ThemeGrid" Width="368" />
                    </ScrollViewer>

                    <Grid Grid.Row="6">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /><ColumnDefinition Width="Auto" /></Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="选择后会立即保存" Foreground="{DynamicResource MutedBrush}" FontFamily="Microsoft YaHei UI" FontSize="10" VerticalAlignment="Center" />
                        <Button x:Name="ThemeCancelButton" Grid.Column="1" Content="取消" Style="{StaticResource ActionButton}" Width="82" />
                        <Button x:Name="ThemeApplyButton" Grid.Column="2" Content="应用主题" Style="{StaticResource ActionButton}" Width="98" Margin="0" />
                    </Grid>
                </Grid>
            </Border>
        </Grid>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$names = @(
    'HiddenView', 'HiddenDragSurface', 'HiddenAvatar', 'CompactView', 'CompactDragSurface', 'CompactAvatar', 'CompactAvatarColumn',
    'CompactRemainingText', 'CompactPercentText', 'CompactUsageWindowText', 'DetailUsageWindowText', 'DetailView', 'DetailHeader', 'StatusDot',
    'ThemeButton', 'DetailAvatar', 'PlanText', 'DetailRemainingText', 'MoodText', 'FirstWindowPanel', 'FirstWindowName',
    'FirstWindowValue', 'FirstWindowProgress', 'SecondWindowPanel', 'SecondWindowName',
    'SecondWindowValue', 'SecondWindowProgress', 'ResetExactText',
    'CreditsText', 'RefreshButton', 'CloseButton', 'ThemePickerView', 'ThemeBackButton',
    'CurrentThemeLabel', 'ThemePreviewPanel', 'ThemePreviewAvatar', 'ThemePreviewMiniAvatar',
    'ThemePreviewName', 'ThemePreviewDescription', 'ThemePreviewPercent', 'ThemePreviewCompact',
    'ThemeGrid', 'ThemeCancelButton', 'ThemeApplyButton'
)
foreach ($name in $names) {
    Set-Variable -Name $name -Value $window.FindName($name) -Scope Script
}

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

function Set-ViewState([ValidateSet('Hidden', 'Compact', 'Detail', 'ThemePicker')]$state, [bool]$fromHiddenDrag = $false) {
    $oldWidth = Get-ActualWidth
    $oldHeight = Get-ActualHeight
    $centerX = $window.Left + ($oldWidth / 2)
    $centerY = $window.Top + ($oldHeight / 2)
    $previous = $script:viewState

    if ($state -eq 'ThemePicker') { Ensure-ThemePicker }
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
    if (-not $quotaWindow -or -not $quotaWindow.resetsAt) { return '重置时间：--' }
    $reset = [DateTimeOffset]::FromUnixTimeSeconds([long]$quotaWindow.resetsAt).ToLocalTime()
    return ('重置时间：{0}' -f $reset.ToString('M月d日 HH:mm'))
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

function Set-WindowRow($quotaWindow, $panel, $nameText, $valueText, $progress) {
    if (-not $quotaWindow) { $panel.Visibility = 'Collapsed'; return }
    $remaining = [Math]::Max(0, [Math]::Min(100, 100 - [int]$quotaWindow.usedPercent))
    $panel.Visibility = 'Visible'
    $nameText.Text = Get-WindowName $quotaWindow
    $valueText.Text = ('{0}%' -f $remaining)
    $progress.Value = $remaining
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
        $ResetExactText.Text = Get-ResetExact $limitingWindow
        if ($snapshot.individualLimit) {
            $CreditsText.Text = ('个人限额余量 {0}%' -f [int]$snapshot.individualLimit.remainingPercent)
        } elseif ($snapshot.credits -and $snapshot.credits.hasCredits) {
            $CreditsText.Text = ('积分余额 {0}' -f $snapshot.credits.balance)
        } else {
            $CreditsText.Text = '套餐内额度'
        }

        Set-WindowRow $quotaWindows[0] $FirstWindowPanel $FirstWindowName $FirstWindowValue $FirstWindowProgress
        Set-WindowRow $quotaWindows[1] $SecondWindowPanel $SecondWindowName $SecondWindowValue $SecondWindowProgress
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

$ThemeButton.add_Click({ Show-ThemePicker })
$ThemeBackButton.add_Click({ Close-ThemePicker $false })
$ThemeCancelButton.add_Click({ Close-ThemePicker $false })
$ThemeApplyButton.add_Click({ Close-ThemePicker $true })
$RefreshButton.add_Click({ Request-Refresh })
$CloseButton.add_Click({ $window.Close() })

$window.add_KeyDown({
    param($sender, $eventArgs)
    if ($eventArgs.Key -eq [System.Windows.Input.Key]::Escape) {
        if ($script:viewState -eq 'ThemePicker') { Close-ThemePicker $false }
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
