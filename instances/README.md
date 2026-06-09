# MCSManager Instances

这个目录用于保存 MCSManager 创建的所有游戏实例。

`./scripts/init-env.sh` 会把 `.env` 里的 `MCSM_INSTANCE_ROOT` 设置为本目录的绝对路径，并由 `compose.yaml` 挂载到 Daemon 的 `InstanceData`。

实例目录可以提交到 GitHub；`data/` 仍只保存 MCSManager 自身配置和日志。

