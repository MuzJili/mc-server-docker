# Game Server Docker Stack

这个目录准备的是一个只用预构建镜像的游戏服务器 Docker 部署栈，不在本机构建镜像。

核心服务是 MCSManager Web + Daemon。Daemon 挂载宿主机 Docker socket，用于在 Linux Docker 主机上创建和管理游戏实例。这个仓库只部署管理底座，不定义、不启动任何 Minecraft、Terraria 或其他游戏实例；实例由你后续在 MCSManager 中自行创建。默认按局域网模式暴露管理端口，使用 NUC 的 LAN IP 访问。

MCSManager 的实例根目录会放在项目根目录的 `instances/` 下。`data/` 只保存 MCSManager 自身配置和日志，游戏实例不会落在容器 root 目录里。`data/` 和 `instances/` 都是本机运行数据，默认不提交到 Git。

## 文件结构

- `compose.yaml`: MCSManager 主栈。
- `.env.example`: 部署参数模板。
- `instances/`: MCSManager 实例目录，本机运行数据，不提交到 Git。
- `scripts/init-env.sh`: 在目标服务器上生成 `.env` 和持久化目录。
- `scripts/mcsm.sh`: MCSManager 常用操作封装。
- `scripts/bootstrap-new-host.sh`: 新 Linux 主机一键初始化脚本。
- `scripts/export-host-software.sh`: 导出当前电脑的大项软件清单到 `host-software/`。
- `scripts/install-host-software.sh`: 在新主机按 `host-software/major-apps.tsv` 安装大项软件。
- `docs/`: 部署说明和端口规划。

## NUC 部署

在 NUC 的 Linux Docker 主机上执行：

```bash
./scripts/init-env.sh
docker compose -f compose.yaml pull
docker compose -f compose.yaml up -d
```

如果是在另一台新 Linux 主机上完整初始化，优先看 `docs/NEW_HOST_BOOTSTRAP.md`，也可以直接执行：

```bash
./scripts/bootstrap-new-host.sh
```

如果要连同当前电脑的大项软件清单一起复刻，先在当前电脑导出：

```bash
./scripts/export-host-software.sh
```

然后把 `host-software/` 一起迁移到新机器，并执行：

```bash
INSTALL_HOST_SOFTWARE=1 ./scripts/bootstrap-new-host.sh
```

`host-software/` 只记录人工关心的大项，例如 NoMachine、ToDesk、VS Code、Chrome、Codex、Docker，以及需要预拉或重建的 Docker 镜像。它不保存 apt/dpkg 依赖快照、snap 基础组件、systemd 服务清单、Docker 容器运行状态或 Clash/cc-switch 配置。

然后在局域网内访问：

```text
http://<NUC_LAN_IP>:23333
```

首次进入面板后，在“节点”里添加 Daemon：

- 地址：当前浏览器能直接访问到的 Daemon 地址
- 端口：`.env` 里的 `MCSM_DAEMON_PORT`，默认 `24444`，或 Sakura Frp 的 Daemon 远程端口
- 密钥：启动后执行 `./scripts/mcsm.sh key` 查看

节点地址填 NUC 的局域网 IP。不要填 `127.0.0.1` 作为长期配置；NUC 本机浏览器访问 `127.0.0.1:24444` 时会命中 Daemon，但 Web 容器后台访问 `127.0.0.1` 时会访问 Web 容器自己。

建议在路由器里给 NUC 做 DHCP 静态绑定，让它一直拿到同一个局域网 IP。比在 NUC 系统里手写静态 IP 更省心，也更不容易和路由器 DHCP 池冲突。

## Sakura Frp

如果还需要公网访问，使用 Sakura Frp 官方启动器或官方应用程序管理隧道。MCSManager 需要同时穿透 Web 和 Daemon；游戏端口等你自己建实例后再按实际端口添加：

- MCSManager Web：`23333/tcp`
- MCSManager Daemon：`24444/tcp`
- Minecraft Forge/Java 示例：`25565/tcp`
- Minecraft Bedrock 示例：`19132/udp`
- Terraria 示例：`7777/tcp`

Sakura Frp 应用程序里的隧道本地地址统一填 NUC 本机：

```text
127.0.0.1:对应端口
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

创建实例时，如果希望局域网玩家直连，宿主机端口绑定到 `0.0.0.0` 或 NUC 的局域网 IP；如果只想走 Sakura Frp，再绑定到 `127.0.0.1`。示例配置见 `docs/MCSMANAGER_INSTANCES.md`。

`instances/` 可能包含整合包、mods、世界、日志和玩家数据，体积大且带有本机状态。需要迁移时用 `rsync`、压缩包或备份工具单独同步，不通过 Git 保存。

## 注意

- MCSManager 的 Docker 隔离能力面向 Linux Docker 主机；当前目录只准备文件。
- 当前 Compose 不包含任何游戏实例服务，也不会帮你构建或启动实例。
- Minecraft Java 版本通过每个游戏实例的 Docker 镜像选择；自构建服务端文件时用纯 Java 运行时镜像，不安装到 MCSManager Daemon 容器里；见 `docs/MINECRAFT_JAVA_DOCKER.md`。
- 默认管理端口监听 `0.0.0.0`，用于局域网访问。如果只想本机或 Sakura 访问，把对应 `*_BIND` 改成 `127.0.0.1`。
- 如果目标 Linux 主机没有 `/etc/timezone`，删除 `compose.yaml` 里对应 bind mount。
- 公网访问时至少穿透 `23333/tcp`、`24444/tcp`，以及你后续手动创建实例时配置的实际游戏端口。

## 参考

- MCSManager Docker 部署文档：https://docs.mcsmanager.com/zh_cn/docker-install.html
- MCSManager 网络架构说明：https://docs.mcsmanager.com/zh_cn/ops/mcsm_network.html
- Minecraft Java Docker 运行时说明：`docs/MINECRAFT_JAVA_DOCKER.md`
- SakuraFrp 启动器文档：https://doc.natfrp.com/launcher/usage.html
- itzg Minecraft 镜像说明：https://github.com/itzg/docker-minecraft-server
