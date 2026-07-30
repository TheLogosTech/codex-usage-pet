# Contributing

感谢你帮助改进 Codex Usage Pet。Bug 报告、兼容性反馈、文档修正和小而明确的功能改进都很欢迎。

## 开发环境

- Windows 10/11
- Windows PowerShell 5.1+
- 已安装并登录 Codex 桌面应用或 Codex CLI
- Git

克隆仓库后先运行：

```powershell
.\scripts\validate.ps1
```

需要验证真实额度连接时，再运行：

```powershell
.\plugins\codex-usage-pet\scripts\self-test.ps1
```

启动界面：

```powershell
.\plugins\codex-usage-pet\scripts\start.ps1
```

## 提交约定

- 一个 Pull Request 只处理一个清晰问题
- 不要提交登录令牌、`auth.json`、本机配置或额度快照
- 保持 Windows PowerShell 5.1 兼容
- 修改 manifest、marketplace 或资源引用后必须运行 `scripts/validate.ps1`
- UI 修改请同时检查边缘、迷你、详情和主题选择四种状态
- 用户可见行为变化应更新 README 与 CHANGELOG

提交信息使用简短的祈使句，例如 `Fix edge docking on secondary displays`。

## 报告问题

请提供 Windows 版本、Codex 版本、复现步骤、预期结果和实际结果。日志或截图中请先删除用户名、路径、额度信息及其他个人数据。
