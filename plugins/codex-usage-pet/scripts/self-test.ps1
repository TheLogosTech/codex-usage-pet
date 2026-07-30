[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ResolveCodex.ps1')
$codexPath = Resolve-CodexExecutable
if (-not $codexPath) {
    throw '找不到 codex.exe。请先安装或更新 Codex 桌面应用/CLI。'
}

Add-Type -Path (Join-Path $PSScriptRoot 'CodexUsageClient.cs')
$client = New-Object CodexUsagePet.CodexAppServerClient($codexPath)

try {
    $client.Start()
    $deadline = [DateTime]::UtcNow.AddSeconds(12)
    while ([DateTime]::UtcNow -lt $deadline -and -not $client.LatestJson) {
        Start-Sleep -Milliseconds 100
    }

    if (-not $client.LatestJson) {
        $detail = if ($client.LatestError) { $client.LatestError } else { '读取超时' }
        throw "未能读取 Codex 余量：$detail"
    }

    $payload = $client.LatestJson | ConvertFrom-Json
    $snapshot = $payload.result.rateLimits
    $windows = @(@($snapshot.primary, $snapshot.secondary) | Where-Object { $_ })
    $remaining = @($windows | ForEach-Object { 100 - [int]$_.usedPercent } | Measure-Object -Minimum).Minimum
    if ($null -eq $remaining) { $remaining = 100 }

    [pscustomobject]@{
        Status = 'OK'
        Plan = $snapshot.planType
        RemainingPercent = $remaining
        Windows = $windows.Count
        DataSource = 'codex app-server / account/rateLimits/read'
    } | Format-List
} finally {
    $client.Dispose()
}
