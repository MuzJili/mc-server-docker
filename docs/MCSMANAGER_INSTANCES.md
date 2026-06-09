# MCSManager Instance Notes

所有实例目录都应落在 `.env` 的 `MCSM_INSTANCE_ROOT` 下。使用 `./scripts/init-env.sh` 时，这个目录会是项目根目录下的 `instances/`，便于在 NUC 上直接管理、备份和迁移。

## Minecraft Java Forge

推荐镜像：

```text
itzg/minecraft-server:latest
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
127.0.0.1:25565 -> 25565/tcp
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
127.0.0.1:19132 -> 19132/udp
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
127.0.0.1:7777 -> 7777/tcp
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

如果新建更多实例，宿主机端口仍建议绑定到 `127.0.0.1`，再由 Sakura Frp 应用程序把对应本地端口穿透出去。
