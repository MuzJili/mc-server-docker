# Host Software Manifest

这里只保留需要在新主机复刻的大项软件，不保存 apt/dpkg 依赖树。

- `major-apps.tsv`: 桌面应用、远程控制、核心开发工具等大项。
- `docker-images.txt`: 需要预拉或重建的 Docker 镜像。
- `vscode-extensions.txt`: VS Code 扩展。
- `metadata.env`: 导出时的系统摘要。

不要把系统依赖包快照、Docker 容器运行状态、登录态、SSH 私钥、`.env` 密钥、Clash/cc-switch 配置放进这里。
