# Sakura Frp on the NUC

推荐优先使用局域网 IP 访问 NUC。需要公网访问时，再在 NUC 上直接使用 Sakura Frp 应用程序。它跑在宿主机上，可以直接访问 Docker 映射出来的端口，配置和排错都更直观。

这个仓库不定义任何游戏实例。Minecraft、Terraria 等实例由你在 MCSManager 里手动创建后，再把对应本地端口加进 Sakura Frp 应用程序。

## 隧道规划

先在 Sakura Frp 应用程序或面板里为 NUC 创建 MCSManager 隧道；游戏隧道等实例创建后再添加：

| 用途 | 隧道类型 | 本地 IP | 本地端口 |
| --- | --- | --- | ---: |
| MCSManager Web | TCP 或 HTTP/HTTPS | `127.0.0.1` | `23333` |
| MCSManager Daemon | TCP | `127.0.0.1` | `24444` |
| Minecraft Forge/Java 示例 | TCP | `127.0.0.1` | `25565` |
| Minecraft Bedrock 示例 | UDP | `127.0.0.1` | `19132` |
| Terraria 示例 | TCP | `127.0.0.1` | `7777` |

MCSManager 的 Web 和 Daemon 都需要外部浏览器可访问。只穿透 Web 端口时，面板可能打开，但节点连接或控制台功能会异常。

在 MCSManager 节点配置里，Daemon 地址要填 Daemon 隧道的公网地址和远程端口。不要填 `127.0.0.1`：远程浏览器会把它理解成当前电脑，Web 容器后台会把它理解成容器自己。

MCSManager 的管理端口默认按局域网模式监听 `0.0.0.0`。如果只想通过 Sakura Frp 或本机访问，可以在 `.env` 里把 `MCSM_WEB_BIND` 和 `MCSM_DAEMON_BIND` 改回 `127.0.0.1`。

更多节点连接排错见 `docs/MCSMANAGER_NETWORK.md`。

## NUC 建议

- 默认已经把 `MCSM_WEB_BIND`、`MCSM_DAEMON_BIND` 设为 `0.0.0.0`，用于局域网访问。
- 如果只想允许本机或 Sakura Frp 访问，把对应管理端口或实例端口绑定到 `127.0.0.1`。
- Minecraft Bedrock 必须使用 UDP 隧道；Forge/Java 版和 Terraria 使用 TCP 隧道。
- 面板账号必须设置强密码。穿透后它相当于公网服务。
