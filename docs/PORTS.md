# Port Plan

默认只部署 MCSManager 管理端口，并绑定在 NUC 的 `127.0.0.1`，由 Sakura Frp 应用程序穿透到公网。游戏端口由你在 MCSManager 中手动创建实例时配置：

| 服务 | 协议 | 默认端口 | 说明 |
| --- | --- | ---: | --- |
| MCSManager Web | TCP | 23333 | 面板入口 |
| MCSManager Daemon | TCP | 24444 | 浏览器和面板需要能访问 Daemon |
| Minecraft Forge/Java | TCP | 25565 | 手动创建实例时的常用端口 |
| Minecraft Bedrock | UDP | 19132 | 手动创建实例时的常用端口 |
| Terraria | TCP | 7777 | 手动创建实例时的常用端口 |

建议保留一些额外端口给多实例：

| 用途 | 建议范围 |
| --- | --- |
| Minecraft Forge/Java 多周目/测试服 | `25565-25575/tcp` |
| Minecraft Bedrock 多周目/测试服 | `19132-19142/udp` |
| Terraria 多周目/测试服 | `7777-7787/tcp` |

如果使用反向代理，MCSManager 的 Web 和每个 Daemon 都需要被浏览器访问到。不要只代理 Web 端口。

## Sakura Frp

NUC 在内网时，Sakura Frp 应用程序里的隧道应该指向 NUC 本机端口：

| 用途 | 隧道类型 | 本地 IP | 本地端口 |
| --- | --- | --- | ---: |
| MCSManager Web | TCP 或 HTTP/HTTPS | `127.0.0.1` | `23333` |
| MCSManager Daemon | TCP | `127.0.0.1` | `24444` |
| Minecraft Forge/Java | TCP | `127.0.0.1` | `25565` |
| Minecraft Bedrock | UDP | `127.0.0.1` | `19132` |
| Terraria | TCP | `127.0.0.1` | `7777` |

如果使用 MCSManager 创建更多实例，每个实例需要独立的远程端口和本地端口映射。

实例文件位置统一在：

```text
${MCSM_INSTANCE_ROOT}
```

通过 `./scripts/init-env.sh` 生成时，实际路径是项目根目录下的 `instances/`。

在 MCSManager 里创建 Docker 实例时，也建议把宿主机端口绑定到 `127.0.0.1`，例如：

```text
127.0.0.1:25565 -> 25565/tcp
127.0.0.1:7777 -> 7777/tcp
127.0.0.1:19132 -> 19132/udp
```
