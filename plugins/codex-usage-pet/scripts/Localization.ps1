function Get-PetLocalization([string]$Language = 'Auto') {
    if ($Language -eq 'Auto' -or [string]::IsNullOrWhiteSpace($Language)) {
        $Language = [Globalization.CultureInfo]::CurrentUICulture.Name
    }
    $locale = if ($Language -match '^zh(?:-|$)') { 'zh-CN' } else { 'en-US' }
    $path = Join-Path $PSScriptRoot ("..\locales\{0}.json" -f $locale)
    return @{
        Strings = (Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json)
        Culture = [Globalization.CultureInfo]::GetCultureInfo($locale)
    }
}