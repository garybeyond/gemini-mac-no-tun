# Gemini Mac 免 TUN 启动器

在 macOS 上用 Clash Verge/mihomo 跑 Gemini 桌面版，**全程不开 TUN**。

[English](README.en.md) · [问题排查](#排查表)

> 独立社区工具，并非 Google 官方项目。包装 App 只启动你已经安装的官方 Gemini.app；仓库不提供修改版 Gemini，也不收集账号信息。

## 为什么需要这个

Gemini 桌面版有两个网络栈：

| 网络栈 | 用途 | 认不认环境变量代理 |
|---|---|---|
| gRPC (C-core) | 主 API 通道 | ✅ 认 `http_proxy` |
| OAuth (janus C++) | 登录/token 刷新 | ❌ 只认透明代理(TUN) |

只开 macOS 系统代理或只设环境变量时，OAuth 栈会直连 Google IP，在国内被墙，永远卡在加载页。本工具用 **tun 路由** 把 Google IP 段指进 mihomo，只拦截 Gemini 需要的流量，其他流量不动。

## 前提条件

- macOS 13+ (Ventura 或更新)
- 已安装官方 [Gemini.app](https://gemini.google.com/app/download/mac)
- 已安装 [Clash Verge](https://github.com/clash-verge-rev/clash-verge-rev) 或兼容的 mihomo 客户端
- Clash Verge 的混合代理端口任意(包装 App 会自动检测实际端口)

## 安装

### 1. 下载 Release

从 [Releases](https://github.com/garybeyond/gemini-mac-no-tun/releases/latest) 下载 `gemini-mac-no-tun-macos-source.zip`，解压。

### 2. 安装包装 App

```sh
# 把 App 复制到 /Applications
cp -R "Gemini via Clash.app" /Applications/

# 可选：隐藏官方 Gemini.app，避免误点
mv /Applications/Gemini.app /Applications/_Gemini.app.bak
```

### 3. 安装 tun 路由守护进程

需要管理员权限(会弹密码框)：

```sh
sudo sh macos/gemini-tun-routes.sh --install
```

这会：
- 启用 mihomo 的 tun 设备(关闭 auto-route，不影响其他流量)
- 把 Google IP 段路由指进 tun 设备
- 安装 LaunchDaemon，开机自动生效
- 每 30 秒检测一次，Clash Verge 重启内核后自动修复

### 4. 启动

从 Launchpad 或 Applications 文件夹打开 **Gemini via Clash**。

> **升级注意**：Gemini 提示有新版本时，点击升级会重新生成 `Gemini.app`。升级完成后，**仍然要从 `Gemini via Clash.app` 启动**，不要直接点原来的 `Gemini.app`（否则又会卡在加载页）。

## 原理

```
Gemini.app
  ├─ gRPC 栈 → $http_proxy → 127.0.0.1:7890 (Clash Verge) → 代理服务器
  └─ OAuth 栈 → 直连 Google IP → 路由表 → utun1024 → mihomo → 代理服务器
```

包装 App 注入环境变量，tun 路由守护进程处理 OAuth 栈。两者互补，覆盖 Gemini 的全部网络流量。

## 排查表

| 症状 | 可能原因 | 解决 |
|---|---|---|
| 卡在加载页/登录无反应/无法跳转回客户端 | tun 路由未生效，OAuth 栈直连 Google 超时 | 运行 `sudo sh macos/gemini-tun-routes.sh --install` |
| 日志有 `Transport error: 86` 或 `DEADLINE_EXCEEDED` | mihomo 未运行 | 检查 Clash Verge 是否运行 |
| 其他 App 无法上网 | 误开了 Clash Verge 的 TUN 开关 | 在 Clash Verge 设置里关闭 TUN |
| 重启后失效 | LaunchDaemon 未加载 | `sudo launchctl load -w /Library/LaunchDaemons/local.gemini.tun-routes.plist` |

> 如果你在 B 站、V2EX、linux.do 看到过"Gemini Mac 登录卡住"、"Gemini 桌面版无法跳转"之类的帖子——那就是这个问题。本工具解决的就是它。

## 卸载

```sh
# 删除包装 App
rm -rf "/Applications/Gemini via Clash.app"

# 恢复官方 App(如果之前隐藏了)
mv /Applications/_Gemini.app.bak /Applications/Gemini.app

# 删除 tun 路由守护进程
sudo launchctl bootout system/local.gemini.tun-routes
sudo rm /Library/LaunchDaemons/local.gemini.tun-routes.plist
sudo rm /usr/local/bin/gemini-tun-routes.sh

# 删除路由(重启后自动失效，也可手动删)
sudo route -n delete -inet -net 172.217.0.0/16 -interface utun1024 2>/dev/null
# ... 其他 Google IP 段同理
```

## 边界与安全

- 本工具只包装官方 Gemini.app，不修改二进制、不注入代码、不收集账号信息。
- tun 路由只拦截 Google IP 段(约 15 个 /16 和 /19 网段)，其他流量走默认路由。
- Clash Verge 的代理规则由你自己配置，本工具不改变你的代理策略。
- 如果 Google 更换 IP 段，需要更新路由表(守护进程脚本里的 `V4` 和 `V6` 变量)。

## 同类项目

- [awesome-chatgpt-remote](https://github.com/garybeyond/awesome-chatgpt-remote) — ChatGPT 桌面版免 TUN 启动(同一作者，类似思路)

## 许可

MIT License。见 [LICENSE](LICENSE) 文件。
