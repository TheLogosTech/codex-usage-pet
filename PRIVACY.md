# Privacy

Codex Usage Pet 在本机启动 `codex app-server --stdio`，并调用 `account/rateLimits/read` 获取当前账户的额度快照。

## 收集的数据

插件不收集或上传任何数据。额度百分比、周期、重置时间和套餐类型只在本机内存中用于渲染界面。

## 不会访问的内容

- 不读取、复制或记录 `~/.codex/auth.json`
- 不记录登录令牌
- 不包含第三方分析、广告或遥测 SDK
- 不向维护者或第三方服务器发送额度数据

## 本机存储

插件只在 `%LOCALAPPDATA%\CodexUsagePet\settings.json` 保存界面偏好，包括主题、窗口位置和最后停靠的屏幕边缘。该文件不包含登录凭据或额度快照，删除后会在下次启动时使用默认设置重新创建。

## Contact

如有隐私问题，请在不包含个人额度或凭据的前提下，通过 GitHub Issues 联系维护者。
