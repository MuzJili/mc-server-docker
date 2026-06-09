# Sakura Frp on the NUC

推荐在 NUC 上直接使用 Sakura Frp 应用程序。它跑在宿主机上，可以直接访问 Docker 映射到 `127.0.0.1` 的端口，配置和排错都更直观。

这个仓库不定义任何游戏实例。Minecraft、Terraria 等实例由你在 MCSManager 里手动创建后，再把对应本地端口加进 Sakura Frp 应用程序。

这个项目仍保留 Docker 版 frpc 作为备用方案：

```bash
docker compose -f compose.yaml -f compose.frp.yml up -d sakura-frpc
```

或使用脚本：

```bash
./scripts/frp.sh up
./scripts/frp.sh logs
./scripts/frp.sh restart
./scripts/frp.sh down
```

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

MCSManager 的管理端口默认只监听 NUC 的 `127.0.0.1`。你手动创建游戏实例时，也建议把宿主机端口绑定到 `127.0.0.1`，这样 Sakura Frp 隧道本地地址统一填 `127.0.0.1` 即可。

更多节点连接排错见 `docs/MCSMANAGER_NETWORK.md`。

## `.env` 配置

如果使用 Sakura Frp 应用程序，不需要填写下面的 `.env` 字段。只有改用 Docker 版 frpc 时，才需要在 Sakura Frp 面板中选中需要启动的隧道，使用“批量操作 -> 配置文件”或隧道配置里的启动参数，复制类似下面的内容：

```text
-f your-access-key:12345,12346,12347
```

写入 `.env`：

```dotenv
SAKURA_FRP_TOKEN=your-access-key
SAKURA_FRP_TUNNEL_IDS=12345,12346,12347
```

不要把真实访问密钥提交到仓库。

## NUC 建议

- 默认已经把 `MCSM_WEB_BIND`、`MCSM_DAEMON_BIND` 设为 `127.0.0.1`，减少局域网暴露面。
- 如果要让局域网玩家不经过 Sakura Frp 直连，把对应管理端口或实例端口绑定到 `0.0.0.0`。
- Minecraft Bedrock 必须使用 UDP 隧道；Forge/Java 版和 Terraria 使用 TCP 隧道。
- 面板账号必须设置强密码。穿透后它相当于公网服务。
