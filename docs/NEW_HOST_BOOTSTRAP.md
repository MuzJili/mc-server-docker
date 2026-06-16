# New Host Bootstrap

这份清单给另一台电脑上的 Codex 或你自己执行。目标是在一台新的 Linux 机器上部署同样的 MCSManager Docker 底座，并迁移当前电脑的大项软件清单、Codex CLI 与 SakuraFrp 官方启动器。

## 0. 先迁移项目文件

推荐方式之一：

```bash
git clone <你的仓库地址> mc-server-docker
cd mc-server-docker
```

仓库只保存部署脚本、Compose、文档和大项软件清单，不保存 `instances/`。如果要连同当前已有实例、整合包、世界一起迁移，单独把 `instances/` 同步过去。优先用 `rsync`：

```bash
rsync -aH --info=progress2 /path/to/mc-server-docker/instances/ user@new-host:/path/to/mc-server-docker/instances/
```

不要把含真实密钥的 `.env` 提交到 Git。可以手动复制 `.env` 到新机器，或者让脚本重新生成后再填 SakuraFrp 密钥。

如果要同步当前电脑的大项软件，确保 `host-software/` 目录也一起迁移。它由下面命令生成：

```bash
./scripts/export-host-software.sh
```

这份清单只保留人工关心的大项，不保留 apt/dpkg 依赖树。当前结构是：

- `major-apps.tsv`：NoMachine、ToDesk、VS Code、Chrome、Codex、Docker 等大项。
- `docker-images.txt`：需要在新主机预拉或重建的高层 Docker 镜像。
- `vscode-extensions.txt`：VS Code 扩展。
- `metadata.env`：导出时的系统摘要。

它不会包含应用登录态、浏览器账号、SSH 私钥、`.env` 密钥、桌面应用内数据、系统依赖包快照、Docker 容器运行状态、Clash/cc-switch 配置。

## 1. 一键初始化

在新机器项目根目录执行：

```bash
chmod +x scripts/*.sh
./scripts/bootstrap-new-host.sh
```

默认会做这些事：

- 安装基础工具：`curl`、`wget`、`git`、`zstd`、`rsync`、`jq` 等。
- 如果没有 Docker，使用 Docker 官方便捷脚本安装 Docker 与 Compose 插件。
- 使用 OpenAI 官方 Codex CLI 安装脚本安装 Codex。
- 运行 `scripts/init-env.sh` 生成 `.env` 和持久化目录。
- 拉取并启动 MCSManager Web + Daemon。

如果要同时按当前电脑的大项软件清单安装：

```bash
INSTALL_HOST_SOFTWARE=1 ./scripts/bootstrap-new-host.sh
```

如果想一次性安装当前电脑软件、Codex、SakuraFrp 官方启动器，并启动 MCSManager：

```bash
INSTALL_HOST_SOFTWARE=1 INSTALL_SAKURA_FRP=1 ./scripts/bootstrap-new-host.sh
```

## 2. SakuraFrp 官方启动器

如果你要按 SakuraFrp 官方 Linux 安装指令一起安装启动器：

```bash
INSTALL_SAKURA_FRP=1 ./scripts/bootstrap-new-host.sh
```

如果脚本检测到 Docker 环境但你仍然想强制安装到系统里：

```bash
INSTALL_SAKURA_FRP=1 SAKURA_FRP_DIRECT=1 ./scripts/bootstrap-new-host.sh
```

安装后到 SakuraFrp 启动器 WebUI 或远程管理里启用隧道。MCSManager 至少需要：

- Web：`127.0.0.1:23333/tcp`
- Daemon：`127.0.0.1:24444/tcp`
- 游戏实例：按实例实际端口添加，例如 Java 版 Minecraft `25565/tcp`

## 3. MCSManager 首次配置

启动后访问：

```text
http://<新机器局域网IP>:23333
```

获取 Daemon 密钥：

```bash
./scripts/mcsm.sh key
```

在 MCSManager 节点里添加 Daemon：

```text
地址：<新机器局域网IP>
端口：24444
密钥：./scripts/mcsm.sh key 输出的 key/token
```

不要把长期节点地址填成 `127.0.0.1`。如果走 SakuraFrp 公网访问，节点地址填 Daemon 隧道的公网地址和远程端口。

## 4. 常用验证

```bash
docker compose -f compose.yaml ps
./scripts/mcsm.sh status
./scripts/mcsm.sh logs
codex --version
```

如果 Docker 刚安装完后当前用户不能直接运行 `docker`，先注销再登录，或者临时用 `sudo docker ...`。

## 5. 给另一台电脑 Codex 的任务文本

可以直接把下面这段发给另一台电脑上的 Codex：

```text
请在这个仓库根目录执行新主机初始化。先阅读 README.md、docs/NEW_HOST_BOOTSTRAP.md、compose.yaml、scripts/*.sh，并确认 host-software/major-apps.tsv 和 host-software/docker-images.txt 存在。然后运行 chmod +x scripts/*.sh 和 INSTALL_HOST_SOFTWARE=1 ./scripts/bootstrap-new-host.sh。若我要使用 SakuraFrp 官方启动器，请用 INSTALL_HOST_SOFTWARE=1 INSTALL_SAKURA_FRP=1 ./scripts/bootstrap-new-host.sh。不要提交或打印 .env 密钥。启动后检查 docker compose -f compose.yaml ps、./scripts/mcsm.sh status、codex --version，并告诉我 MCSManager 访问地址、Daemon 密钥获取命令、SakuraFrp 需要配置的端口、哪些大项软件需要我手动下载官方 .deb，以及 Docker 镜像预拉情况。
```
