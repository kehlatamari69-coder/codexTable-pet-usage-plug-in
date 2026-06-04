# codex桌宠用量插件

给 Codex 桌面宠物增加一个跟随移动的用量状态小胶囊。

![codex桌宠用量插件预览](assets/usage-preview.svg)

## 中文说明

`codex桌宠用量插件` 是一个 macOS 本地小工具。它会锚定在 Codex 桌宠附近，读取 Codex 当前剩余用量，并用一个小胶囊显示状态和百分比。

它不会修改 Codex.app，不会上传数据，也不会控制桌宠本体动画。它只是通过一个独立透明窗口显示用量状态。

## 功能

- 跟随 Codex 桌宠移动
- 从 Codex 宠物 `spritesheet.webp` 裁切不同情绪动作
- 显示 Codex 当前剩余用量百分比
- 根据剩余用量切换状态文案
- 小胶囊设计，尽量不遮挡对话窗口
- 支持手动启动、停止
- 支持登录 macOS 后自动启动

![状态映射](assets/status-capsules.svg)

## 安装要求

- macOS
- 已安装 Codex 桌面版
- 已安装 Swift 编译工具

检查 Swift：

```sh
which swiftc
```

如果没有 `swiftc`，请先安装 Xcode Command Line Tools。

## 使用方法

进入插件目录：

```sh
cd codex-pet-limits
```

构建插件：

```sh
./build.sh
```

启动插件：

```sh
./start-overlay.sh
```

停止插件：

```sh
./stop-overlay.sh
```

设置登录后自动启动：

```sh
./install-launch-agent.sh
```

![安装流程](assets/setup-flow.svg)

## 状态含义

插件会读取 Codex 的用量窗口，并取较紧张的那个作为总状态。

| 剩余用量 | 显示状态 |
| --- | --- |
| 60-100% | 满电 |
| 30-59% | 稳定 |
| 10-29% | 省用 |
| 1-9% | 低电 |
| 0% 或达到限制 | 休息 |

## 情绪动作

插件会从 `~/.codex/pets/sproutpal/spritesheet.webp` 中裁切不同动作帧：

| 用量状态 | 小噜噜动作 |
| --- | --- |
| 满电 | 开心跳跃 |
| 稳定 | 抱手待机 |
| 省用 | 思考 |
| 低电 | 难过 |
| 休息 | 难过休息 |

## 数据读取

插件只读取本机数据：

- `~/.codex/.codex-global-state.json`

用于获取 Codex 桌宠当前位置。

- `codex app-server --stdio`
- `account/rateLimits/read`

用于读取 Codex 当前 rate limits。

## 常见问题

### 没显示胶囊

确认程序是否正在运行：

```sh
ps aux | grep CodexPetLimitOverlay
```

如果没运行，重新启动：

```sh
cd codex-pet-limits
./start-overlay.sh
```

### 更新后打不开

重新构建并签名：

```sh
cd codex-pet-limits
./build.sh
./start-overlay.sh
```

### 胶囊位置不合适

当前胶囊锚定在桌宠脚边，位置刷新间隔是 `0.2` 秒。可以在 `CodexPetLimitOverlay.swift` 里调整 `movePanel(to:)` 的偏移量。

### 卸载

停止插件：

```sh
cd codex-pet-limits
./stop-overlay.sh
```

删除开机自启：

```sh
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist"
```

然后删除项目目录即可。

---

# Codex Pet Usage Plugin

A tiny macOS plugin that adds a moving usage-status capsule to the Codex desktop pet.

## English Guide

`Codex Pet Usage Plugin` anchors a compact overlay near the Codex desktop pet. It reads the current Codex usage limits locally and displays the remaining percentage as a small status capsule.

It does not modify Codex.app, upload data, or control the pet animation itself. It only renders a separate transparent overlay window.

## Features

- Follows the Codex desktop pet
- Crops mood frames from the Codex pet `spritesheet.webp`
- Shows current Codex usage remaining
- Switches status text based on remaining usage
- Compact capsule UI that avoids covering the conversation window
- Manual start and stop scripts
- Optional launch at macOS login

## Requirements

- macOS
- Codex desktop app installed
- Swift compiler installed

Check Swift:

```sh
which swiftc
```

If `swiftc` is missing, install Xcode Command Line Tools first.

## Usage

Open the plugin directory:

```sh
cd codex-pet-limits
```

Build:

```sh
./build.sh
```

Start:

```sh
./start-overlay.sh
```

Stop:

```sh
./stop-overlay.sh
```

Enable launch at login:

```sh
./install-launch-agent.sh
```

## Status Mapping

The plugin reads Codex usage windows and displays the tightest active limit.

| Remaining | Status |
| --- | --- |
| 60-100% | 满电 / Full |
| 30-59% | 稳定 / Stable |
| 10-29% | 省用 / Save |
| 1-9% | 低电 / Low |
| 0% or limited | 休息 / Rest |

## Local Data Access

The plugin only reads local data:

- `~/.codex/.codex-global-state.json`

Used to locate the current Codex pet position.

- `codex app-server --stdio`
- `account/rateLimits/read`

Used to read Codex rate limits.

## More Details

Detailed Chinese guide: [codex-pet-limits/README.md](codex-pet-limits/README.md)
