# Security Policy

## Supported versions

安全修复目前只针对最新发布版本。

## Reporting a vulnerability

请不要在公开 Issue 中披露尚未修复的安全漏洞。请通过 GitHub 仓库的 **Security → Report a vulnerability** 私下报告，并包含影响范围、复现步骤和建议的缓解方案。

请勿提交真实的 Codex 登录令牌、`auth.json` 内容或个人额度数据。维护者会尽快确认报告，并在评估完成后协调披露时间。

## Data boundary

本项目只应通过本机 `codex app-server --stdio` 获取额度。任何新增的网络传输、遥测、凭据读取或持久化额度数据的改动，都必须在代码和文档中明确说明并经过安全审查。
