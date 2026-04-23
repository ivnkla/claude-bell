#!/usr/bin/env bash
set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
BACKUP="$HOME/.claude/settings.json.bak"

# --- Prerequisites ---

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with your package manager." >&2
  exit 1
fi

# --- OS detection ---

OS="$(uname -s)"

case "$OS" in
  Linux)
    PLAYER="paplay"
    SOUND_STOP="/usr/share/sounds/freedesktop/stereo/complete.oga"
    SOUND_WAIT="/usr/share/sounds/freedesktop/stereo/window-question.oga"
    CMD_STOP="paplay --volume=32768 $SOUND_STOP 2>/dev/null || true"
    CMD_WAIT="paplay $SOUND_WAIT 2>/dev/null || true"
    ;;
  Darwin)
    PLAYER="afplay"
    SOUND_STOP="/System/Library/Sounds/Glass.aiff"
    SOUND_WAIT="/System/Library/Sounds/Tink.aiff"
    CMD_STOP="afplay $SOUND_STOP 2>/dev/null || true"
    CMD_WAIT="afplay $SOUND_WAIT 2>/dev/null || true"
    ;;
  *)
    echo "Error: unsupported OS ($OS). Only Linux and macOS are supported." >&2
    exit 1
    ;;
esac

if ! command -v "$PLAYER" &>/dev/null; then
  echo "Warning: $PLAYER is not installed — sounds will not work." >&2
fi

# --- Backup and initialize settings.json ---

mkdir -p "$HOME/.claude"

if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$BACKUP"
  echo "Backup created: $BACKUP"
  CURRENT="$(cat "$SETTINGS")"
else
  CURRENT='{}'
fi

# --- Merge hooks without overwriting existing content ---

MERGED="$(echo "$CURRENT" | jq \
  --arg cmd_stop "$CMD_STOP" \
  --arg cmd_wait "$CMD_WAIT" \
  '
  .hooks.Stop = (
    [{"type": "command", "command": $cmd_stop}]
    + ((.hooks.Stop // []) | map(select(.command != $cmd_stop)))
  ) |
  .hooks.PermissionRequest = (
    [{"type": "command", "command": $cmd_wait}]
    + ((.hooks.PermissionRequest // []) | map(select(.command != $cmd_wait)))
  ) |
  .hooks.PreToolUse = (
    [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": $cmd_wait}]}]
    + ((.hooks.PreToolUse // []) | map(select(.matcher != "AskUserQuestion")))
  )
')"

echo "$MERGED" > "$SETTINGS"
echo "Hooks installed in $SETTINGS"
echo "Done. Restart Claude Code to enable sound notifications."
