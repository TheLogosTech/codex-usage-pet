# Codex Usage Pet

[简体中文](README.md) · [Changelog](CHANGELOG.md) · [Privacy](PRIVACY.md)

A lightweight Windows desktop companion that shows your remaining Codex usage. It reads the local `codex app-server`, then presents the remaining percentage, reset time, and connection state in a draggable desktop widget.

> This is an independent community project, not an official OpenAI product. Windows is currently the only supported platform.

<p align="center">
  <img src="plugins/codex-usage-pet/assets/screenshot.png" alt="Codex Usage Pet detail view" width="280">
  <img src="plugins/codex-usage-pet/assets/screenshot-compact.png" alt="Codex Usage Pet compact view" width="160">
  <img src="plugins/codex-usage-pet/assets/screenshot-edge.png" alt="Codex Usage Pet edge view" width="96">
</p>

## Features

- Shows remaining usage, quota windows, and reset time
- Edge avatar, compact, and detailed views
- Automatically docks when dragged near any screen edge
- Ten built-in mascot themes with persistent selection
- Manual refresh and a two-minute default refresh interval
- Single-instance behavior
- Optional launch at Windows sign-in
- Local-only quota access: no `auth.json` reads and no telemetry

## Requirements

- Windows 10 or Windows 11
- Codex desktop or Codex CLI, installed and signed in
- Windows PowerShell 5.1 or later

## Install from GitHub

```powershell
codex plugin marketplace add lanyiyrt/codex-usage-pet
codex plugin add codex-usage-pet@codex-usage-pet
```

Start a new Codex task after installation and ask:

> Launch my Codex Usage Pet.

## Run from source

```powershell
git clone https://github.com/lanyiyrt/codex-usage-pet.git
cd codex-usage-pet
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\plugins\codex-usage-pet\scripts\self-test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\plugins\codex-usage-pet\scripts\start.ps1
```

The pet stores its selected theme, window position, and last docked edge in `%LOCALAPPDATA%\CodexUsagePet\settings.json`.

For startup commands, privacy details, troubleshooting, repository layout, and development instructions, see the [Chinese README](README.md) or [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 于瑞涛
