---
name: codex-usage-pet
description: Launch, theme, or troubleshoot the local Codex Usage Pet desktop widget. Use when the user asks to 查看/显示 Codex 余量, 启动/关闭余量宠物, 切换宠物主题, set the pet to start with Windows, or verify the local Codex quota connection.
---

# Codex Usage Pet

This skill manages the Windows desktop companion bundled in this plugin.

## Default action

When the user mentions or invokes Codex Usage Pet without specifying an action, launch the pet immediately using the Launch procedure below. Do not ask whether to launch or troubleshoot. An explicit action such as theme, close, troubleshoot, or Windows startup takes precedence. A bare plugin mention does not enable Windows startup.

## Resolve paths

The plugin root is two directories above this `SKILL.md`. Resolve it from the selected skill path; do not assume a fixed username or installation folder.

## Launch

For requests such as “启动余量宠物”, “显示 Codex 余量”, or “打开 quota pet”:

1. Run `<plugin-root>\scripts\start.ps1` with Windows PowerShell:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<plugin-root>\scripts\start.ps1"
   ```

2. Tell the user the pet is running. Do not read `auth.json`; the pet talks only to `codex app-server`.

The app uses a single-instance mutex, so repeated launch requests safely keep the existing pet instead of creating duplicates.

The compact view has a fixed small size and intentionally shows only the mascot and remaining percentage. Clicking it opens details. Dragging the compact or detail view within 30 pixels of any screen edge hides it as a small edge avatar; clicking or dragging that avatar toward the desktop restores the compact view.

The detail card has four icon-only action buttons, in order: palette opens the theme picker, gear opens Settings, rotate-cw refreshes usage, and power exits the widget. Settings selects the remaining percentage shown as the main number in compact and detail views: lowest remaining (default), 5-hour, or weekly. Apply saves the selection and updates the display from the latest available quota data. Cancel, Back, or Escape discards unapplied changes. The selection persists as UsageWindow in `%LOCALAPPDATA%\CodexUsagePet\settings.json`. The mascot itself is display-only. The picker includes ten mascots: Owl, Fox, Mecha Cat, Cloud Bunny, Ember Dragon, Aurora Penguin, Space Shiba, Bamboo Panda, Pixel Slime, and Dune Elephant. Applying a theme updates the edge, compact, and detail states and persists the choice in `%LOCALAPPDATA%\CodexUsagePet\settings.json`.

## Start with Windows

Only when the user explicitly asks for automatic startup, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<plugin-root>\scripts\install-startup.ps1"
```

To disable it, run `uninstall-startup.ps1` from the same directory.

## Troubleshoot

Run `self-test.ps1`. Report its concise result and preserve privacy:

- Never print or inspect tokens from `~/.codex/auth.json`.
- If `codex.exe` is missing, ask the user to install or update Codex.
- If the account is logged out, ask the user to sign in through Codex.
- Do not change Codex configuration as part of troubleshooting unless requested.
