# codex桌宠用量插件

给 Codex 桌面宠物增加一个跟随移动的用量状态小胶囊。

![codex桌宠用量插件预览](assets/usage-preview.svg)

## 中文说明

`codex桌宠用量插件` 现在是一个轻量 macOS app：`CodexPetLimits.app`。它登录后自动启动，等待 Codex 打开；Codex 打开并显示桌宠时，它在桌宠附近显示用量胶囊；Codex 关闭或桌宠隐藏时，它会关闭用量连接并清空内存状态。

它不修改 Codex.app，不上传数据，不保存旧用量数据，也不写插件日志。

## 功能

- 跟随 Codex 软件启动和关闭
- 跟随 Codex 桌宠显示、隐藏和移动
- 显示 Codex 当前 5 小时剩余用量百分比
- 当一周剩余用量为 0 时，显示一周刷新倒计时
- 关闭或隐藏后清空内存状态，下次启动重新读取新数据
- 低频读取用量，避免频繁刷写 Codex 本地日志
- 单 app 自启动，没有 watcher/cleanup 旧脚本

## 安装

```sh
cd codex-pet-limits
./install-app.sh
```

安装位置：

```text
~/Applications/CodexPetLimits.app
```

自启动项：

```text
~/Library/LaunchAgents/com.yy.codex-pet-limits.plist
```

## 卸载

```sh
cd codex-pet-limits
./uninstall-app.sh
```

## 状态含义

| 剩余用量 | 显示状态 |
| --- | --- |
| 60-100% | 满电 |
| 30-59% | 稳定 |
| 10-29% | 省用 |
| 1-9% | 低电 |
| 0% 或达到 5 小时限制 | 5 小时重置倒计时 |
| 一周剩余 0% | 一周刷新倒计时 |

## 数据读取

插件只读取本机数据：

- `~/.codex/.codex-global-state.json`：获取 Codex 桌宠位置
- `codex app-server --stdio` + `account/rateLimits/read`：读取当前 rate limits

读取只发生在 Codex 和桌宠可见时。Codex 关闭或桌宠隐藏后，插件会断开连接并清空状态。

---

# Codex Pet Usage Plugin

A lightweight macOS app that adds a small usage capsule near the Codex desktop pet.

`CodexPetLimits.app` starts at login, waits for Codex, shows the capsule only while Codex and the pet are visible, and clears in-memory usage state when Codex closes or the pet hides.

It does not modify Codex.app, upload data, keep old usage data, or write plugin logs.

## Install

```sh
cd codex-pet-limits
./install-app.sh
```

## Uninstall

```sh
cd codex-pet-limits
./uninstall-app.sh
```

## Behavior

- Shows the 5-hour remaining usage percentage
- Shows the weekly reset countdown only when weekly remaining usage is 0%
- Starts automatically at login as a single lightweight app
- Uses no watcher or cleanup legacy scripts
