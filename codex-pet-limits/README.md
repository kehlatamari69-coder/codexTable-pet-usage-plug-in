# codex桌宠用量插件

一个轻量 macOS app，用来给 Codex 桌宠增加“剩余用量状态胶囊”。

## 功能

- 登录后自动启动 `CodexPetLimits.app`
- Codex 打开时进入工作状态，Codex 关闭时断开用量连接并清空状态
- 桌宠隐藏时隐藏胶囊并清空当前用量状态
- 直接使用 Codex 保存的桌宠坐标计算锚点，兼容旧版位置数据
- 不枚举系统窗口，不需要屏幕录制或辅助功能权限
- 自动适配 sproutpal v1（8×9）和 v2（8×11）spritesheet
- 显示 5 小时剩余用量
- Codex 未提供 5 小时窗口时显示 `--%`，不会用一周数据代替
- 一周剩余用量为 0 时显示一周刷新倒计时
- 每分钟读取 Codex 最新 session 里的 `rate_limits` 快照
- 按 `window_minutes=300/10080` 识别 5 小时和一周窗口
- 重置时间已过时自动归零已用量，避免显示过期百分比
- 不启动 `codex app-server`，不访问网络，不读取浏览器 Cookie
- 不保存旧用量数据
- 不创建缓存或插件日志
- 不再使用 watcher/cleanup 旧脚本

## 数据来源

只读最近 8 天的本地 session 文件尾部：

```text
~/.codex/sessions/YYYY/MM/DD/*.jsonl
```

没有可用快照时胶囊停留在“读取中”，不会启动额外服务或使用旧缓存。
若快照只包含一周窗口，5 小时位置显示 `--%`；一周已用完时仍会显示一周刷新倒计时。

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

`build.sh` 只是兼容入口，会转到 `build-app.sh`。

## English

`CodexPetLimits.app` is a lightweight macOS app that shows a usage capsule near the Codex desktop pet.

It starts at login, waits for Codex, reads the newest local session snapshot once per minute, and clears in-memory state when Codex closes or the pet hides. If Codex omits the five-hour window, the capsule shows `--%` instead of reusing weekly data.

It uses no network, browser cookies, app-server process, cache, or plugin logs.
