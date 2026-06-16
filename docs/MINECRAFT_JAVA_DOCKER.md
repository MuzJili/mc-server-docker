# Minecraft Java Runtime Notes

这个部署栈推荐把 Java 运行时放在每个 Minecraft 游戏容器里，而不是装进
MCSManager Web 或 Daemon 容器。MCSManager 只负责通过 Docker 管理实例；每个
Minecraft 实例自己选择匹配的 Java 镜像。

如果你自己构建 Forge、Paper、Fabric 或整合包服务端文件，这些文件通常不包含
Java。这种情况下不要使用“自动下载服务端”的思路，而是使用“纯 Java 运行时镜像
+ 你的实例工作目录文件”。

## 两种实例模式

### 预置启动器镜像

如果希望镜像负责下载和启动服务端，可以使用带 Java 版本的
`itzg/minecraft-server` tag：

```text
itzg/minecraft-server:java8
itzg/minecraft-server:java11
itzg/minecraft-server:java16
itzg/minecraft-server:java17
itzg/minecraft-server:java21
itzg/minecraft-server:java25
```

旧服和整合包不要长期使用 `latest`。`latest` 和 `stable` 会跟随当前新版
Minecraft 所需的 Java 版本移动，可能让旧 Forge 或旧插件突然无法启动。

### 自构建服务端文件

如果服务端 jar、Forge 安装结果、mods、config、world 都由你自己准备，实例镜像
只需要提供 Java。下面是常用示例，实际可用 tag 以 Docker Hub 或你的私有镜像仓库
为准：

```text
eclipse-temurin:8-jre
eclipse-temurin:17-jre
eclipse-temurin:21-jre
```

默认只预拉 Java 8、17、21。Java 11、16、25 不作为常驻基础镜像；只有明确跑
对应 Paper/服务端版本时再临时加。Java 16 不是长期支持版本，如果确实遇到只支持
Java 16 的 1.17 旧包，可以用 Docker Hub 上仍可用的 Java 16 JRE 镜像，或用
Dockerfile 自己构建一个 `mc-java16-runtime`。Java 25 同理，如果公共 JRE tag
不合适，就构建自己的 `mc-java25-runtime`。关键原则是：镜像里只放 Java，服务端
文件放 MCSManager 实例工作目录。

## 运行时选择表

整合包或服务端软件的说明优先级最高。如果没有明确说明，可以从这张表开始选：

| 目标服务端 | Java 运行时 | 预置启动器镜像示例 |
| --- | --- | --- |
| Vanilla / Forge / Fabric 1.12-1.16.5，尤其旧 Forge | Java 8 | `itzg/minecraft-server:java8` |
| Paper 1.12-1.16.4 | Java 11，只在跑这段 Paper 时需要 | `itzg/minecraft-server:java11` |
| Vanilla 1.17.x 或只适配 Java 16 的包 | Java 16，只在明确需要时临时加 | `itzg/minecraft-server:java16` |
| Vanilla / Forge / Fabric / Paper 1.18-1.20.4 | Java 17 | `itzg/minecraft-server:java17` |
| Vanilla / Forge / Fabric / Paper 1.20.5-1.21.x | Java 21 | `itzg/minecraft-server:java21` |
| Paper 26.1+ 或未来明确要求 Java 25 的服务端 | Java 25，只在明确需要时临时加 | `itzg/minecraft-server:java25` |

Forge 1.18 以下优先用 Java 8，除非整合包作者明确要求别的版本。很多旧
Forge 和旧 mod 依赖 JVM 内部行为，新 Java 反而容易出错。

## 自构建实例字段

在 MCSManager 中选择：

```text
新建实例 -> 使用 Docker 镜像
```

如果你的服务端文件由自己准备，建议这样填：

```text
镜像: eclipse-temurin:<java-version>-jre
工作目录: /data
容器端口: 25565/tcp
宿主机端口: 选择唯一端口，例如 25565, 25566, 25567...
```

局域网玩家要直连时，宿主机绑定用 `0.0.0.0:<端口>`。只想通过 Sakura Frp
或其他隧道访问时，再绑定 `127.0.0.1:<端口>`。

实例文件放在 MCSManager 的实例文件管理器里，也就是容器里的 `/data`。典型目录：

```text
server.jar
eula.txt
server.properties
mods/
config/
world/
```

Paper / Spigot / Fabric installer 产出的普通 jar 可以用：

```text
java -Dfile.encoding=UTF-8 -Xms1G -Xmx4G -jar server.jar nogui
```

老 Forge universal jar 常见命令：

```text
java -Dfile.encoding=UTF-8 -Xms1G -Xmx4G -jar forge-server.jar nogui
```

新 Forge 安装器生成 `run.sh` 时，优先使用：

```text
bash run.sh nogui
```

如果需要改 JVM 参数，把内存写进 `user_jvm_args.txt`，或把 `run.sh` 展开成
Forge 生成的 `@user_jvm_args.txt @libraries/.../unix_args.txt` 形式。

建议每个版本、整合包、周目都建成独立 MCSManager 实例，让 Java 镜像 tag、
启动命令和数据目录保持稳定。

## 自定义纯 Java 镜像

MCSManager 官方文档允许用 Dockerfile 构建自己的镜像。如果你想固定镜像名，
可以构建只包含 Java 的运行时镜像，例如：

```Dockerfile
FROM eclipse-temurin:17-jre
WORKDIR /data
```

构建后在 MCSManager 实例里填：

```text
镜像: mc-java17-runtime:local
工作目录: /data
启动命令: java -Dfile.encoding=UTF-8 -Xms1G -Xmx4G -jar server.jar nogui
```

不要把 Forge 服务端文件烘进这个基础镜像，除非你明确想做不可变部署。平时把
服务端文件留在实例目录，备份、换包、换周目都会轻松很多。

## 排错

如果启动日志里出现 `UnsupportedClassVersionError`，或提到 class file version：

```text
class file version 61.0 -> 需要 Java 17
class file version 65.0 -> 需要 Java 21
class file version 69.0 -> 需要 Java 25
```

只改对应实例的 Docker 镜像 tag，然后重启该实例。Minecraft 服务端里的 Java
版本问题，不要通过改 MCSManager Daemon 镜像解决。

如果旧 Forge 报类加载、mixin 或启动器兼容错误，先降到 Java 8 镜像。如果现代
整合包在 Java 21 或 Java 25 上失败，按整合包作者要求的精确 Java 版本来，较旧
的 1.20.x 整合包经常仍然需要 Java 17。

如果日志提示 `java: command not found`，说明当前实例运行环境没有 Java：

- Docker 实例：换成带 JRE 的镜像，例如 `eclipse-temurin:17-jre`。
- 普通实例：Java 必须安装在 MCSManager Daemon 实际运行的环境里。当前仓库使用
  Docker 版 Daemon，所以宿主机安装 Java 并不会自动进入 Daemon 容器。

## 参考来源

- MCSManager Docker 部署文档：https://docs.mcsmanager.com/zh_cn/docker-install.html
- MCSManager 搭建 Java 版文档：https://docs.mcsmanager.com/zh_cn/setup_java_edition.html
- MCSManager Docker 镜像实例文档：https://docs.mcsmanager.com/zh_cn/setup_docker_image.html
- MCSManager 环境隔离文档：https://docs.mcsmanager.com/zh_cn/advanced/docker.html
- itzg Minecraft 镜像 Java 版本说明：https://docker-minecraft-server.readthedocs.io/en/latest/versions/java/
- itzg Minecraft 镜像环境变量说明：https://docker-minecraft-server.readthedocs.io/en/latest/variables/
- Mojang Piston Meta 版本清单：https://piston-meta.mojang.com/mc/game/version_manifest_v2.json
- Minecraft Wiki Java 版服务端 Java 要求：https://minecraft.wiki/w/Tutorial:Setting_up_a_Java_Edition_server#Java_for_server
