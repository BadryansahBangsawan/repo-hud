# Repo HUD

A live HUD of local git repositories: branch, dirty count, ahead/behind, without opening a terminal.

Menu extra for macOS 14+. It lives in the menu bar and does not show a Dock icon.

## Features

- Watch folders; every nested git repo is listed.
- Branch name, dirty file count, ahead/behind vs upstream.
- FSEvents refresh when files change.
- Fetch, copy branch, Reveal in Finder.
- Add or remove watch folders in Settings.

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later
- `git` on `PATH`

## Install

```bash
git clone https://github.com/BadryansahBangsawan/repo-hud.git
cd repo-hud
bash package-app.sh
open dist/RepoHUD.app
```

`package-app.sh` builds a release binary, wraps `dist/RepoHUD.app`, and ad-hoc codesigns it (`codesign -s -`). Unsigned is fine for local use.

Enable **Open at Login** from Settings if you want it after reboot.

## Usage

- Add a folder that contains git repos (for example your `Developer` or `Downloads` directory).
- Click a row’s context menu for Fetch, Copy branch, or Reveal in Finder.
- If `git` is missing, the panel shows **git not in PATH**.

## Permissions

- Folder access via the standard open panel. No Accessibility or Screen Recording.

Denied permissions must not crash the app. You should see a banner and a button to open System Settings.

## Privacy

No network except `git fetch` when you choose Fetch. Watch list is `~/Library/Application Support/Repo HUD/watches.json`.

Bundle ID: `engineer.badry.repohud`.

## Development

```bash
swift build
swift build -c release --product RepoHUD
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`.

## License

[MIT](LICENSE)
