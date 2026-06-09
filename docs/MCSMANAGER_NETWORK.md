# MCSManager Network Notes

MCSManager 的 Web 和 Daemon 是两个服务。Web 面板负责界面，Daemon 负责实例管理、文件传输、日志和控制台。

关键点：浏览器也需要能直接访问 Daemon。只让 Web 能访问 Daemon 不够。

## 节点地址怎么填

### NUC 本机浏览器

```text
地址: 127.0.0.1
端口: 24444
```

### 局域网其他电脑浏览器

`.env` 里需要：

```dotenv
MCSM_DAEMON_BIND=0.0.0.0
```

节点里填写：

```text
地址: NUC 的局域网 IP
端口: 24444
```

### Sakura Frp 远程访问

需要至少两条隧道：

```text
Web    -> 127.0.0.1:23333
Daemon -> 127.0.0.1:24444
```

节点里填写 Daemon 那条隧道的公网地址和远程端口，不要填 `127.0.0.1`。

## 密钥

启动 Daemon 后在 NUC 上执行：

```bash
./scripts/mcsm.sh key
```

它会打印 Daemon 配置文件路径、可能的密钥字段和节点地址填写建议。

## 常见错误

- Web 能打开，但节点显示网络连接失败：通常是 Daemon 端口没有暴露给当前浏览器。
- 网页直连失败：浏览器访问不到节点里填写的 Daemon 地址。
- 远程浏览器里填 `127.0.0.1`：这会连到你当前电脑自己，不会连到 NUC。

