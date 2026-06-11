# codex桌宠用量插件

一个轻量 macOS app，用来给 Codex 桌宠增加“剩余用量状态胶囊”。

## 功能

- 登录后自动启动 `CodexPetLimits.app`
- Codex 打开时进入工作状态，Codex 关闭时断开用量连接并清空状态
- 桌宠隐藏时隐藏胶囊并清空当前用量状态
- 显示 5 小时剩余用量
- 一周剩余用量为 0 时显示一周刷新倒计时
- 不保存旧用量数据
- 不写插件日志
- 不再使用 watcher/cleanup 旧脚本

## 安装

```sh
./install-app.sh
```

安装后会生成：

```text
~/Applications/CodexPetLimits.app
~/Library/LaunchAgents/com.yy.codex-pet-limits.plist
```

## 卸载

```sh
./uninstall-app.sh
```

## 构建

```sh
./build-app.sh
```

`build.sh` 只是兼容入口，会转到 `build-app.sh`。

## English

`CodexPetLimits.app` is a lightweight macOS app that shows a usage capsule near the Codex desktop pet.

It starts at login, waits for Codex, reads fresh usage while Codex and the pet are visible, and clears in-memory state when Codex closes or the pet hides.

It does not keep old usage data and does not write plugin logs.
