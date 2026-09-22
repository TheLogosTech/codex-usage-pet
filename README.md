# Codex Usage Pet

Maintained by **TheLogosTech**. Forked from [lanyiyrt/codex-usage-pet](https://github.com/lanyiyrt/codex-usage-pet), originally created by 于瑞涛. The original MIT copyright and license notices are preserved.

[简体中文](README.zh-CN.md) · [Changelog](CHANGELOG.md) · [Privacy](PRIVACY.md)

A lightweight Windows desktop companion that shows your remaining Codex usage. It reads the local `codex app-server`, then presents the remaining percentage, reset time, and connection state in a draggable desktop widget.

> This is an independent community project, not an official OpenAI product. Windows is currently the only supported platform.

<p align="center">
  <img src="plugins/codex-usage-pet/assets/screenshot.png" alt="Codex Usage Pet detail view" width="280">
  <img src="plugins/codex-usage-pet/assets/screenshot-compact.png" alt="Codex Usage Pet compact view" width="160">
  <img src="plugins/codex-usage-pet/assets/screenshot-edge.png" alt="Codex Usage Pet edge view" width="96">
</p>

## Features

- Shows remaining usage and individual reset times and countdown bars for each quota window
- Settings panel selects the main percentage: lowest remaining, 5-hour, or weekly
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
codex plugin marketplace add TheLogosTech/codex-usage-pet
codex plugin add codex-usage-pet@TheLogosTech
```

Start a new Codex task after installation and ask:

> Launch my Codex Usage Pet.

## Run from source

```powershell
git clone https://github.com/TheLogosTech/codex-usage-pet.git
cd codex-usage-pet
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\plugins\codex-usage-pet\scripts\self-test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\plugins\codex-usage-pet\scripts\start.ps1
```

The pet stores its selected theme, main quota window, language preference, window position, and last docked edge in `%LOCALAPPDATA%\CodexUsagePet\settings.json`.

For startup commands, privacy details, troubleshooting, repository layout, and development instructions, see the [Chinese README](README.zh-CN.md) or [CONTRIBUTING.md](CONTRIBUTING.md).

## Usage and settings

Click the compact pet to open details. The four buttons, in order, are **Theme**, **Settings** (gear), **Refresh**, and **Exit**.

Open Settings to choose which remaining percentage appears as the large number in both compact and detail views:

| Choice | Behavior |
| --- | --- |
| Lowest remaining (default) | Automatically uses the quota window with the lowest remaining percentage. |
| 5 hour remaining | Uses the 5-hour quota window. |
| Weekly remaining | Uses the weekly quota window. |

**Apply** saves the selection and updates the display from the latest available quota data. **Cancel**, **Back**, or **Escape** discards an unapplied selection. If the chosen window is unavailable, the pet shows an error/`--` instead of silently switching to another window. The individual quota rows remain visible regardless of the main-number selection.

For manual configuration, `UsageWindow` in `%LOCALAPPDATA%\CodexUsagePet\settings.json` accepts `Minimum` (default), `FiveHour`, or `Weekly`. Close the pet before editing so it cannot overwrite your change, then restart it to load the setting. Changes made through the settings panel apply immediately without a restart.

Each quota row has two bars: the first shows remaining quota, and the second shows time remaining as a fraction of that window's full duration. The time bar drains toward zero at reset. Below the bars, the reset date/time and countdown share one line, separated by ` - `. Reset times use the computer's local time zone. Countdown updates run locally without extra quota requests; unavailable reset data displays `--`.

Reset/countdown text and the settings panel support English and Chinese. The `Language` field in `%LOCALAPPDATA%\CodexUsagePet\settings.json` accepts `Auto` (default), `en-US`, or `zh-CN`. `Auto` follows the Windows UI language, using Chinese for Chinese locales and English otherwise. To override it manually, close the pet, edit the field while preserving the other settings, then restart. Other interface text is not yet fully localized.

## License

[MIT](LICENSE)
