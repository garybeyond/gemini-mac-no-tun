# Gemini Mac No-TUN Launcher

Run Gemini desktop on macOS with Clash Verge/mihomo **without enabling TUN mode**.

[中文](README.md) · [Troubleshooting](#troubleshooting)

> Independent community tool, not affiliated with Google. The wrapper app only launches the official Gemini.app you already installed; this repository does not provide a modified Gemini binary or collect account information.

## Why this exists

Gemini desktop has two network stacks:

| Stack | Purpose | Respects env proxy? |
|---|---|---|
| gRPC (C-core) | Main API channel | ✅ Yes (`http_proxy`) |
| OAuth (janus C++) | Login/token refresh | ❌ No, only transparent proxy (TUN) |

With only macOS system proxy or environment variables, the OAuth stack connects directly to Google IPs, which are blocked in China, causing the app to hang on the loading screen. This tool uses **tun routing** to direct Google IP ranges into mihomo, intercepting only Gemini's traffic while leaving other traffic untouched.

## Prerequisites

- macOS 13+ (Ventura or newer)
- Official [Gemini.app](https://gemini.google.com/app/download/mac) installed
- [Clash Verge](https://github.com/clash-verge-rev/clash-verge-rev) or compatible mihomo client installed
- Clash Verge mixed proxy port can be any value (the wrapper app auto-detects it)

## Installation

### 1. Download Release

Download `gemini-mac-no-tun-macos-source.zip` from [Releases](https://github.com/garybeyond/gemini-mac-no-tun/releases/latest) and extract it.

### 2. Install the wrapper app

```sh
# Copy the app to /Applications
cp -R "Gemini via Clash.app" /Applications/

# Optional: hide the official Gemini.app to avoid accidental launch
mv /Applications/Gemini.app /Applications/_Gemini.app.bak
```

### 3. Install the tun routing daemon

Requires admin privileges (password dialog will appear):

```sh
sudo sh macos/gemini-tun-routes.sh --install
```

This will:
- Enable mihomo's tun device (auto-route disabled, no impact on other traffic)
- Route Google IP ranges into the tun device
- Install a LaunchDaemon for automatic startup
- Check every 30 seconds and auto-recover after Clash Verge kernel restarts

### 4. Launch

Open **Gemini via Clash** from Launchpad or the Applications folder.

> **Upgrade note**: When Gemini prompts for an update and you click upgrade, it will regenerate `Gemini.app`. After upgrading, **still launch from `Gemini via Clash.app`**, not the original `Gemini.app` (otherwise it will hang on the loading screen again).

## How it works

```
Gemini.app
  ├─ gRPC stack → $http_proxy → 127.0.0.1:7890 (Clash Verge) → proxy server
  └─ OAuth stack → direct to Google IP → route table → utun1024 → mihomo → proxy server
```

The wrapper app injects environment variables; the tun routing daemon handles the OAuth stack. Together they cover all of Gemini's network traffic.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Stuck on loading screen, log shows `Transport error: 86` | Tun routing not active | Run `sudo sh macos/gemini-tun-routes.sh --install` |
| Log shows `DEADLINE_EXCEEDED` | mihomo not running | Check if Clash Verge is running |
| Other apps can't access internet | Clash Verge TUN mode accidentally enabled | Disable TUN in Clash Verge settings |
| Stops working after reboot | LaunchDaemon not loaded | `sudo launchctl load -w /Library/LaunchDaemons/local.gemini.tun-routes.plist` |

## Uninstall

```sh
# Remove the wrapper app
rm -rf "/Applications/Gemini via Clash.app"

# Restore the official app (if you hid it)
mv /Applications/_Gemini.app.bak /Applications/Gemini.app

# Remove the tun routing daemon
sudo launchctl bootout system/local.gemini.tun-routes
sudo rm /Library/LaunchDaemons/local.gemini.tun-routes.plist
sudo rm /usr/local/bin/gemini-tun-routes.sh

# Remove routes (they expire after reboot, but can be deleted manually)
sudo route -n delete -inet -net 172.217.0.0/16 -interface utun1024 2>/dev/null
# ... same for other Google IP ranges
```

## Boundaries and security

- This tool only wraps the official Gemini.app; it does not modify binaries, inject code, or collect account information.
- Tun routing only intercepts Google IP ranges (~15 /16 and /19 subnets); other traffic uses the default route.
- Clash Verge's proxy rules are configured by you; this tool does not change your proxy policy.
- If Google changes its IP ranges, the route table needs updating (the `V4` and `V6` variables in the daemon script).

## Related projects

- [awesome-chatgpt-remote](https://github.com/garybeyond/awesome-chatgpt-remote) — No-TUN launcher for ChatGPT desktop (same author, similar approach)

## License

MIT License. See [LICENSE](LICENSE) file.
