<div align="center">

# Repo HUD

**Watch folders for nested git repos. Branch, dirty count, ahead/behind — Fetch or Reveal in Finder from the extra.**

Menu extra for macOS 14+. Lives on the **right** of the menu bar. No Dock icon.

<br/>

[![Build](https://github.com/BadryansahBangsawan/repo-hud/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/repo-hud/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/repo-hud?style=flat-square)](https://github.com/BadryansahBangsawan/repo-hud/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/repo-hud/releases/latest)

<br/>

| | |
|---|---|
| Product | `RepoHUD` |
| Bundle ID | `engineer.badry.repohud` |
| Cask | `repo-hud` |
| Status item | SF Symbol `arrow.triangle.branch` |
| Panel | opaque ~360×420 pt |

</div>

---

## What you get

| Piece | Behavior |
|---|---|
| **Watch** | Folders; every nested git repo is listed (cap 80, depth 3). |
| **Status** | Branch name, dirty file count, ahead/behind vs upstream. FSEvents refresh. |
| **Open** | Click a row to open in your editor. Context menu: Fetch, copy branch, Reveal in Finder. |
| **Empty** | **No repositories** → **Add folder**. Missing git: **git not in PATH**. |
| **Login** | Open at Login from Settings (`SMAppService`). |

---

## Download

| File | Use |
|---|---|
| **`RepoHUD.app.zip`** | Homebrew cask / unzip, drag **RepoHUD** onto **Applications** |

**[Releases](https://github.com/BadryansahBangsawan/repo-hud/releases/latest)**

---

## Install

### Homebrew

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew trust BadryansahBangsawan/mac-menu-apps
brew install --cask repo-hud
```

`brew trust` is required on Homebrew 6 or `brew install --cask` refuses the tap.

First open (ad-hoc signed):

```bash
xattr -cr /Applications/RepoHUD.app
open /Applications/RepoHUD.app
```

Still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/RepoHUD.app` while `/Applications/RepoHUD.app` is running (same bundle ID).

---

## How to open

This is an `LSUIElement` extra. Proof it is running is the **arrow.triangle.branch** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is opaque ~360×420 pt, not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

---

## Usage

1. With no watch folders: **No repositories** → **Add folder**.
2. While scanning: **Scanning…**.
3. Click a repo row to open it in your editor.
4. Context menu: Fetch, Copy branch, Reveal in Finder.
5. **Settings** at the bottom: watch folders (**Add folder** / Remove), Open at Login, Quit.

If `git` is missing: red **git not in PATH**.

---

## Permissions

No TCC prompts. Folder access is the standard open panel.

---

## Data

| What | Where |
|---|---|
| Watch list | `~/Library/Application Support/Repo HUD/watches.json` |
| Open at Login | `SMAppService.mainApp` (Settings toggle) |

---

## Privacy

No network except `git fetch` when you choose Fetch. Watch paths stay on this Mac.

---

## Uninstall

```bash
brew uninstall --cask repo-hud
```

Or delete `/Applications/RepoHUD.app`. Then:

```bash
rm -rf "$HOME/Library/Application Support/Repo HUD"
```

Turn off **Repo HUD** in System Settings → General → Login Items if it remains.

---

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **arrow.triangle.branch** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x RepoHUD` then `open /Applications/RepoHUD.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/RepoHUD.app`. `spctl --assess` is `rejected` even when it runs. |
| `brew install --cask` refuses the tap | `brew trust BadryansahBangsawan/mac-menu-apps` |
| **git not in PATH** | Install git (Xcode CLT or Homebrew). |
| **No repositories** | Add a folder that contains `.git` dirs (scan cap 80, depth 3). |
| Ahead/behind looks stale | Status is local `git` state. **Fetch** on that row talks to the remote. |
| **Watch missing:** | That watch path is gone. Remove it in Settings. |
| ~10px empty strip under the bar | Reinstall from this repo. |

---

## Build from source

```bash
git clone https://github.com/BadryansahBangsawan/repo-hud.git
cd repo-hud
swift build -c release --product RepoHUD
bash package-app.sh
open dist/RepoHUD.app
```

Tag `v*` runs CI: `RepoHUD.app.zip`. Never commit `dist/`.

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. `FunTheme.swift` is copied verbatim (no shared package).

---

## FAQ

**Why is there no Dock icon?**  
It is a menu extra. Click the arrow.triangle.branch item on the **right** of the menu bar.

**Does Fetch leave this Mac?**  
Yes. **Fetch** runs `git fetch` on that repo. Listing status does not.

**Where is the watch list?**  
`~/Library/Application Support/Repo HUD/watches.json`.

**How do I stop it opening at login?**  
Settings in the panel, or System Settings → General → Login Items → **Repo HUD**.

---

<div align="center">

[MIT](LICENSE)

</div>
