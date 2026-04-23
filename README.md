# claude-bell

Sound notifications for [Claude Code](https://claude.ai/code) via hooks.

Plays a sound when Claude finishes a response, requests a permission, or asks a question — so you can look away while it works.

## Hooks installed

| Event | Sound |
|---|---|
| Claude stops (response complete) | `complete.oga` / `Glass.aiff` |
| Permission request | `window-question.oga` / `Tink.aiff` |
| Claude asks a question | `window-question.oga` / `Tink.aiff` |

## Requirements

- **jq** — to merge hooks into `settings.json` without overwriting existing content
- **paplay** (Linux) or **afplay** (macOS) — to play sounds

```bash
# Debian / Ubuntu / Kali
sudo apt install jq

# macOS
brew install jq
```

`paplay` is included with PulseAudio (standard on most Linux desktops). `afplay` is built into macOS.

## Install

```bash
bash install.sh
```

The script:
1. Backs up `~/.claude/settings.json` to `~/.claude/settings.json.bak`
2. Merges the three hooks into your existing configuration
3. Does not overwrite any hooks you already have

Restart Claude Code after installation.

## Uninstall

Remove the three hook entries from `~/.claude/settings.json`, or restore the backup:

```bash
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```
