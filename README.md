<div align="center">

# Repo HUD

**Live git status HUD for your local repositories — branch, dirty count, ahead/behind.**  
macOS menu extra — lives in the menu bar, no Dock icon.

<br/>

[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/repo-hud?style=flat-square&color=76B900&label=latest)](https://github.com/BadryansahBangsawan/repo-hud/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/repo-hud/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)

<br/>

</div>

---

## Download

| Platform | File |
|---|---|
| **macOS** (Apple Silicon & Intel, macOS 14+) | `RepoHUD-*-macos.zip` |

[Go to Releases](https://github.com/BadryansahBangsawan/repo-hud/releases/latest)

---

## Installation

### Homebrew (recommended)

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew install --cask repo-hud
```

A **Repo HUD** icon appears in the menu bar. If Gatekeeper blocks it on first launch:

```bash
xattr -cr /Applications/RepoHUD.app && open /Applications/RepoHUD.app
```

Or: right-click the app, Open, then Open again. Still blocked? **System Settings → Privacy & Security → Open Anyway**.

### GitHub Releases

1. Download `RepoHUD-*-macos.zip` from [Releases](https://github.com/BadryansahBangsawan/repo-hud/releases/latest)
2. Unzip and drag **RepoHUD** into Applications
3. On first launch, run the xattr command above if Gatekeeper blocks it

### Build from source

```bash
git clone https://github.com/BadryansahBangsawan/repo-hud.git
cd repo-hud
bash package-app.sh
open dist/RepoHUD.app
```

Requires Xcode Command Line Tools and Swift 5.9+.

---

## Notes

– Add watch folders in Settings; every nested git repo is listed.
– FSEvents refreshes the view when files change.
– Requires git on PATH (included on macOS).
– No Dock icon; lives entirely in the menu bar.

---

## Troubleshooting

**HUD shows no repos after adding a folder:** Quit and relaunch Repo HUD — the watcher registers on startup, so newly added root folders need a fresh launch to begin tracking.

**Ahead/behind count is stale:** The count reflects the last `git fetch` you ran; Repo HUD reads local state only and does not fetch from remote automatically.

---

<div align="center">

Made with ♥ for developers who prefer staying in the flow.

</div>

