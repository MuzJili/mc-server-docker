# Game Server Docker Stack

这个目录准备的是一个只用预构建镜像的游戏服务器 Docker 部署栈，不在本机构建镜像。

核心服务是 MCSManager Web + Daemon。Daemon 挂载宿主机 Docker socket，用于在 Linux Docker 主机上创建和管理游戏实例。这个仓库只部署管理底座，不定义、不启动任何 Minecraft、Terraria 或其他游戏实例；实例由你后续在 MCSManager 中自行创建。默认管理端口只绑定到 NUC 的 `127.0.0.1`，再由 Sakura Frp 应用程序穿透出去。

MCSManager 的实例根目录会放在项目根目录的 `instances/` 下。`data/` 只保存 MCSManager 自身配置和日志，游戏实例不会落在容器 root 目录里。

## 文件结构

- `compose.yaml`: MCSManager 主栈。
- `compose.frp.yml`: 可选 Sakura Frp 客户端。
- `.env.example`: 部署参数模板。
- `instances/`: MCSManager 实例目录，会提交到 GitHub。
- `scripts/init-env.sh`: 在目标服务器上生成 `.env` 和持久化目录。
- `scripts/mcsm.sh`: MCSManager 常用操作封装。
- `scripts/frp.sh`: Sakura Frp 客户端常用操作封装。
- `docs/`: 部署说明和端口规划。

## NUC 部署

在 NUC 的 Linux Docker 主机上执行：

```bash
./scripts/init-env.sh
docker compose -f compose.yaml pull
docker compose -f compose.yaml up -d
```

然后在 NUC 本机或通过 Sakura Frp 访问：

```text
http://127.0.0.1:23333
```

首次进入面板后，在“节点”里添加 Daemon：

- 地址：当前浏览器能直接访问到的 Daemon 地址
- 端口：`.env` 里的 `MCSM_DAEMON_PORT`，默认 `24444`，或 Sakura Frp 的 Daemon 远程端口
- 密钥：启动后执行 `./scripts/mcsm.sh key` 查看

节点地址不建议填 `127.0.0.1` 作为长期配置。NUC 本机浏览器访问 `127.0.0.1:24444` 时会命中 Daemon，但 Web 容器后台访问 `127.0.0.1` 时会访问 Web 容器自己。更稳的做法是：局域网使用 NUC 的 LAN IP，并把 `MCSM_DAEMON_BIND` 设为 `0.0.0.0`；Sakura Frp 远程访问则填 Daemon 那条隧道的公网地址和端口。

## Sakura Frp

NUC 在内网时，推荐直接使用 Sakura Frp 应用程序管理隧道。Docker 中的 `compose.frp.yml` 只是备用方案。MCSManager 需要同时穿透 Web 和 Daemon；游戏端口等你自己建实例后再按实际端口添加：

- MCSManager Web：`23333/tcp`
- MCSManager Daemon：`24444/tcp`
- Minecraft Forge/Java 示例：`25565/tcp`
- Minecraft Bedrock 示例：`19132/udp`
- Terraria 示例：`7777/tcp`

Sakura Frp 应用程序里的隧道本地地址统一填 NUC 本机：

```text
127.0.0.1:对应端口
```

如果改用 Docker 版 frpc，再把 Sakura Frp 面板里复制的 `-f <访问密钥>:<隧道ID列表>` 拆到 `.env`：

```dotenv
SAKURA_FRP_TOKEN=访问密钥
SAKURA_FRP_TUNNEL_IDS=隧道ID1,隧道ID2,隧道ID3
```

然后在 NUC 上启动 Docker 版 frpc：

```bash
docker compose -f compose.yaml -f compose.frp.yml up -d sakura-frpc
```

详细说明见 `docs/SAKURA_FRP.md`。

如果面板提示“网络连接失败”或“网页直连失败”，优先检查 Daemon 端口是否也被穿透，以及节点地址是否填的是 Daemon 隧道地址。Web 能打开不代表 Daemon 也能被浏览器访问。更多排错见 `docs/MCSMANAGER_NETWORK.md`。

## 实例创建

所有游戏实例都由你在 MCSManager 中手动创建。推荐每个游戏、版本、整合包、周目都建立独立实例，切换时停止旧实例、启动新实例。数据保存在：

```text
${MCSM_INSTANCE_ROOT}
```

如果使用 `./scripts/init-env.sh` 生成 `.env`，它会自动设置为：

```text
<当前项目目录>/instances
```

创建实例时建议把宿主机端口绑定到 `127.0.0.1`，再由 Sakura Frp 应用程序穿透对应端口。示例配置见 `docs/MCSMANAGER_INSTANCES.md`。

## 注意

- MCSManager 的 Docker 隔离能力面向 Linux Docker 主机；当前目录只准备文件。
- 当前 Compose 不包含任何游戏实例服务，也不会帮你构建或启动实例。
- 默认管理端口只监听 `127.0.0.1`。如果要给局域网设备直连，把对应 `*_BIND` 改成 `0.0.0.0`。
- 如果目标 Linux 主机没有 `/etc/timezone`，删除 `compose.yaml` 里对应 bind mount。
- 公网访问时至少穿透 `23333/tcp`、`24444/tcp`，以及你后续手动创建实例时配置的实际游戏端口。

## 参考

- MCSManager Docker 部署文档：https://docs.mcsmanager.com/zh_cn/docker-install.html
- MCSManager 网络架构说明：https://docs.mcsmanager.com/zh_cn/ops/mcsm_network.html
- Sakura Frp frpc Docker 文档：https://doc.natfrp.com/frpc/usage.html#docker
- itzg Minecraft 镜像说明：https://github.com/itzg/docker-minecraft-server
