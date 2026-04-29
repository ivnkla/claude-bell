#!/usr/bin/env bash

# -e Exit immediately if a command exits with a non-zero status.
# -u Treat unset variables as an error when substituting.
# -o pipefail ensures exiting if a pipeline fails (not just the last command).
set -euo pipefail

SETTINGS="${SETTINGS:-$HOME/.claude/settings.json}" # SETTINGS environment variable or default to ~/.claude/settings.json
BACKUP="$SETTINGS.bak"

# --- Prerequisites ---

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with your package manager." >&2
  exit 1
fi

# --- OS detection ---

OS="$(uname -s)"
VOLUME=65536 # 100% volume for paplay (which uses a 0-65536 range)

case "$OS" in
  Linux)
    PLAYER="paplay"
    SOUND_STOP="/usr/share/sounds/freedesktop/stereo/complete.oga"
    SOUND_POST_TOOL_USE="/usr/share/sounds/freedesktop/stereo/power-unplug.oga"
    SOUND_PERMISSION_REQUEST="/usr/share/sounds/freedesktop/stereo/power-plug.oga"
    CMD_STOP="paplay --volume=$((VOLUME/2)) $SOUND_STOP 2>/dev/null || true"
    CMD_POST_TOOL_USE="paplay --volume=$VOLUME $SOUND_POST_TOOL_USE 2>/dev/null || true"
    CMD_PERMISSION_REQUEST="paplay --volume=$VOLUME $SOUND_PERMISSION_REQUEST 2>/dev/null || true"
    ;;
  Darwin)
    PLAYER="afplay"
    SOUND_STOP="/System/Library/Sounds/Glass.aiff"
    SOUND_POST_TOOL_USE="/System/Library/Sounds/Tink.aiff"
    SOUND_PERMISSION_REQUEST="/System/Library/Sounds/Blow.aiff"
    CMD_STOP="afplay $SOUND_STOP 2>/dev/null || true"
    CMD_POST_TOOL_USE="afplay $SOUND_POST_TOOL_USE 2>/dev/null || true"
    CMD_PERMISSION_REQUEST="afplay $SOUND_PERMISSION_REQUEST 2>/dev/null || true"
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

if [ ! -d "$HOME/.claude" ]; then
  echo "Error: ~/.claude not found. Is Claude Code installed?" >&2
  exit 1
fi

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
  --arg cmd_post_tool_use "$CMD_POST_TOOL_USE" \
  --arg cmd_permission_request "$CMD_PERMISSION_REQUEST" \
  '
  .hooks.Stop = (
    [{"matcher": "", "hooks": [{"type": "command", "command": $cmd_stop}]}]
    + ((.hooks.Stop // []) | map(select(.hooks[0].command != $cmd_stop)))
  ) |
  .hooks.PostToolUse = (
    [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": $cmd_post_tool_use}]}]
    + ((.hooks.PostToolUse // []) | map(select(.hooks[0].command != $cmd_post_tool_use)))
  ) |
  .hooks.PermissionRequest = (
    [{"matcher": "", "hooks": [{"type": "command", "command": $cmd_permission_request}]}]
    + ((.hooks.PermissionRequest // []) | map(select(.hooks[0].command != $cmd_permission_request)))
  )
')"

echo "$MERGED" > "$SETTINGS"
echo "Hooks installed in $SETTINGS"
echo "Done. (Re)start Claude Code to enable sound notifications."
