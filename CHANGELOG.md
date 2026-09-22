# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-09-22

### Added

- Settings panel opened by a gear button, with lowest remaining, 5-hour, and weekly choices for the main percentage
- Persistent quota-window selection with Apply, Cancel, Back, and Escape behavior
- Individual reset times and time-remaining progress bars for each quota window, with locally updated countdowns
- English and Chinese resources for reset times, countdowns, and the settings panel, with automatic language selection and a manual override
- Regression coverage for quota-window selection, settings persistence, reset-time localization, and countdown calculations

### Changed

- Reset timestamps and countdowns now share one line beneath each window's progress bars
- Bare Usage Pet plugin invocations default to launching the widget
- English is now the main README, with Chinese documentation in README.zh-CN.md
- Updated documentation and plugin descriptions for the settings panel and quota display options

## [0.1.0] - 2026-07-31

### Added

- Windows desktop widget with edge, compact, detail, and theme-picker views
- Ten selectable mascot themes
- Local Codex quota retrieval through `codex app-server`
- Manual and periodic refresh
- Edge docking, window-position persistence, and single-instance behavior
- Optional Windows startup shortcut
- Codex plugin skill for launch, startup management, and troubleshooting
- Repository marketplace, validation workflow, bilingual documentation, and open-source project policies

[Unreleased]: https://github.com/TheLogosTech/codex-usage-pet/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/TheLogosTech/codex-usage-pet/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/lanyiyrt/codex-usage-pet/releases/tag/v0.1.0
