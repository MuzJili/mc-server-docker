# MCSManager Instance Notes

所有实例目录都应落在 `.env` 的 `MCSM_INSTANCE_ROOT` 下。使用 `./scripts/init-env.sh` 时，这个目录会是项目根目录下的 `instances/`，便于在 NUC 上直接管理、备份和迁移。

`instances/` 是本机运行数据，不提交到 Git。它可能包含整合包、mods、世界、日志和玩家数据；需要换机器时用 `rsync`、压缩包或备份工具单独迁移。

## Minecraft Java Runtime

推荐把 Java 运行时放在每个 Minecraft Docker 实例的镜像里，而不是安装到 MCSManager Daemon 容器里。这样同一台 MCSManager 可以同时跑 Java 8 的旧 Forge、Java 17 的整合包、Java 21 的新版服务端，互不影响。

默认预拉的纯 Java 运行时镜像：

```text
eclipse-temurin:8-jre
eclipse-temurin:17-jre
eclipse-temurin:21-jre
```

如果想让镜像负责下载和启动服务端，再按目标版本选择 `itzg/minecraft-server`。其中
`java11`、`java16`、`java25` 是按需项，不需要默认预拉：

```text
itzg/minecraft-server:java8
itzg/minecraft-server:java11
itzg/minecraft-server:java16
itzg/minecraft-server:java17
itzg/minecraft-server:java21
itzg/minecraft-server:java25
```

不要给旧服和整合包长期使用 `latest`。`latest` 会跟随最新 Minecraft/Paper 需要的 Java 版本移动，可能让旧 Forge 或旧插件突然无法启动。

如果服务端 jar、Forge 安装结果、mods、config、world 都由你自己准备，优先使用 `eclipse-temurin:<版本>-jre` 这类纯 Java 运行时镜像；如果想让镜像负责下载和启动服务端，再使用 `itzg/minecraft-server:<版本>`。

版本选择和排错表见 `docs/MINECRAFT_JAVA_DOCKER.md`。

## Minecraft Java Forge

如果使用 itzg 镜像自动安装 Forge，推荐镜像：

```text
itzg/minecraft-server:java17
```

常用环境变量：

```text
EULA=TRUE
TYPE=FORGE
VERSION=1.20.1
FORGE_VERSION=RECOMMENDED
MEMORY=4G
MAX_PLAYERS=20
MOTD=Managed Forge Server
ENABLE_RCON=true
RCON_PASSWORD=change-me
```

端口：

```text
0.0.0.0:25565 -> 25565/tcp
```

工作目录：

```text
/data
```

需要更换 Forge 版本或整合包时，优先新建实例并调整 `TYPE`、`VERSION`、`FORGE_VERSION` 等变量，不要覆盖已有稳定周目。

Forge 模组放在实例工作目录的：

```text
/data/mods
```

常用目录：

```text
/data/config
/data/defaultconfigs
/data/world/serverconfig
```

Forge 端建议固定 `VERSION`，不要长期使用 `LATEST`，否则模组和服务端版本容易不一致。

如果是 1.18 以下的 Forge 或老整合包，优先把镜像换成：

```text
itzg/minecraft-server:java8
```

如果是 1.20.5 以后或 1.21.x，按 `docs/MINECRAFT_JAVA_DOCKER.md` 选择 Java 21 运行时。只有 Paper 26.1+ 或明确要求 Java 25 的服务端才临时加 Java 25 镜像。

## Minecraft Java Self-built Server

适合你自己构建 Forge、Paper、Fabric、整合包服务端文件的情况。推荐镜像：

```text
eclipse-temurin:17-jre
```

工作目录：

```text
/data
```

端口：

```text
0.0.0.0:25565 -> 25565/tcp
```

把服务端文件上传到实例文件管理器，对应容器内 `/data`：

```text
server.jar
eula.txt
server.properties
mods/
config/
world/
```

Paper / Fabric / 普通 jar 启动命令：

```text
java -Dfile.encoding=UTF-8 -Xms1G -Xmx4G -jar server.jar nogui
```

老 Forge universal jar 启动命令：

```text
java -Dfile.encoding=UTF-8 -Xms1G -Xmx4G -jar forge-server.jar nogui
```

新 Forge 生成 `run.sh` 时启动命令：

```text
bash run.sh nogui
```

如果日志提示 `java: command not found`，说明实例镜像没有 Java，换成对应版本的 `eclipse-temurin:<版本>-jre` 或你自己构建的纯 Java 运行时镜像。

## Minecraft Bedrock

推荐镜像：

```text
itzg/minecraft-bedrock-server:latest
```

常用环境变量：

```text
EULA=TRUE
VERSION=LATEST
SERVER_NAME=Managed Bedrock
LEVEL_NAME=world
MAX_PLAYERS=10
```

端口：

```text
0.0.0.0:19132 -> 19132/udp
```

工作目录：

```text
/data
```

## Terraria

推荐镜像：

```text
ryshe/terraria:latest
```

端口：

```text
0.0.0.0:7777 -> 7777/tcp
```

世界目录：

```text
/root/.local/share/Terraria/Worlds
```

启动参数示例：

```text
-world /root/.local/share/Terraria/Worlds/world.wld -autocreate 2 -port 7777 -maxplayers 8
```

`autocreate` 的常见值：

```text
1 = Small
2 = Medium
3 = Large
```

## 切换策略

建议每个游戏、版本、周目都建成独立实例：

```text
mc-forge-survival
mc-forge-modpack-test
terraria-vanilla
terraria-tshock
```

热切换时只做两步：

1. 停止当前实例。
2. 启动目标实例。

这样不需要改镜像、不需要 build，也不会把不同游戏的数据混到一个目录里。

如果新建更多实例，局域网直连时宿主机端口绑定到 `0.0.0.0` 或 NUC 的局域网 IP；只走 Sakura Frp 时再绑定到 `127.0.0.1`。
