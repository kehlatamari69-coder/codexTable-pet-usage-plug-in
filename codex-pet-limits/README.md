# Codex 桌宠用量插件

一个轻量 macOS app，用来给当前版 Codex 桌宠增加“剩余用量状态胶囊”。当前适配 Codex `26.715.31251`（build `5538`）和 sproutpal v2。

## 功能

- 登录后自动启动 `CodexPetLimits.app`
- Codex 打开时进入工作状态，Codex 关闭时断开用量连接并清空状态
- 桌宠隐藏时隐藏胶囊并清空当前用量状态
- 状态文件临时写入不完整时保留上次稳定位置，不闪烁或误隐藏
- 直接读取当前 Codex 保存的根级桌宠坐标并锚定可视身体
- 不枚举系统窗口，不需要屏幕录制或辅助功能权限
- 使用 sproutpal v2（8×11）spritesheet
- 只显示一周剩余用量
- 一周剩余用量为 0 时显示刷新倒计时
- 每分钟检查 Codex 最新 session，只读取新增内容
- 只接受 `window_minutes=10080` 的一周窗口
- 重置时间已过的窗口直接失效，不会错误显示为 100%
- 冷启动最多读取 1MB，常规刷新最多读取 128KB
- 不启动 `codex app-server`，不访问网络，不读取浏览器 Cookie
- 不保存旧用量数据
- 不创建缓存或插件日志

## 数据来源

只读最近的本地 session 文件：

```text
~/.codex/sessions/YYYY/MM/DD/*.jsonl
```

应用只在内存中保留文件偏移、未完成的 JSONL 行和当前快照。文件没有新增内容时不会重复读取；文件轮换或截断时会自动重新定位。

没有可用的一周快照时胶囊显示 `--%`，不会启动额外服务或使用旧缓存。一周已用完时显示一周刷新倒计时。

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

用量窗口映射自检：

```sh
./CodexPetLimits.app/Contents/MacOS/CodexPetLimits --self-test
```

按需查看一次读取预算和耗时（不会保存结果）：

```sh
./CodexPetLimits.app/Contents/MacOS/CodexPetLimits --benchmark
```

## English

`CodexPetLimits.app` is a lightweight macOS app that shows a usage capsule near the current Codex desktop pet. This release targets Codex `26.715.31251` (build `5538`) and sproutpal v2.

It starts at login, waits for Codex, incrementally reads new data from recent local sessions, and clears all in-memory state when Codex closes or the pet hides. It displays only the weekly usage window (`window_minutes=10080`); expired windows are discarded instead of being shown as 100% remaining.

Cold-start reads are capped at 1MB and normal refreshes at 128KB. It uses no network, browser cookies, app-server process, cache, persistent state, or plugin logs.
