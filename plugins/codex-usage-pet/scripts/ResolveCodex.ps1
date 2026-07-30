function Resolve-CodexExecutable {
    $localBinRoot = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
    if (Test-Path -LiteralPath $localBinRoot) {
        $desktopBinary = Get-ChildItem -LiteralPath $localBinRoot -Recurse -Filter 'codex.exe' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($desktopBinary) { return $desktopBinary.FullName }
    }

    $codexShim = Get-Command 'codex.ps1' -ErrorAction SilentlyContinue
    if ($codexShim) {
        $npmRoot = Split-Path -Parent $codexShim.Source
        $npmBinary = Join-Path $npmRoot 'node_modules\@openai\codex\node_modules\@openai\codex-win32-x64\vendor\x86_64-pc-windows-msvc\bin\codex.exe'
        if (Test-Path -LiteralPath $npmBinary) { return $npmBinary }
    }

    $pathBinary = Get-Command 'codex.exe' -ErrorAction SilentlyContinue
    if ($pathBinary) { return $pathBinary.Source }
    return $null
}
