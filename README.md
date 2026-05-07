# MiraBox StreamDock 操作日志

这个仓库用于保存和追踪 MiraBox 妙联宝 / StreamDock 在 macOS 上的操作日志，便于后续定位启动、插件、设备连接和配置数据库相关问题。

## 当前日志

- `log-2026-05-07-14-08-14.txt`: 418 行，记录一次 StreamDock 启动、插件连接、设备扫描和后续操作。
- `log-2026-05-07-14-14-44.txt`: 791 行，记录另一次启动、插件连接、设备扫描、网络请求和数据库访问异常。

## 环境线索

- StreamDock 版本: `3.10.200.0402`
- Qt 版本: `6.4.3`
- macOS: `15.5`
- Darwin: `24.5.0`
- 语言: `Chinese`

以上信息来自 `log-2026-05-07-14-14-44.txt` 开头的启动记录。

## 初步关注点

- `Another instance is already running`: 可能有已有 StreamDock 实例占用本地服务名。
- `Unable to create keyboard event tap`: 可能与 macOS 辅助功能 / 输入监控权限有关。
- `no such table: StreamDock[293S]`: `DataCache.db` 中缺少设备对应表，可能导致 Profile 缓存读写失败。
- `QFSFileEngine::open: No file name specified`: 有大量空路径文件打开请求，建议结合具体 UI 操作时间点排查。
- `网络错误: Operation canceled` 与 `请求超时（1000 ms）`: 可能是接口请求被取消或超时。
- `Microsoft YaHei` 字体缺失: macOS 环境下字体 fallback 产生额外耗时。

## 使用建议

新增日志时直接放入本目录，并用日期时间命名。排查问题时优先搜索 `Critical`、`Warning`、`SQL error`、`timeout`、`onSocketDisconnected` 等关键字。
