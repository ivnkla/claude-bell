#!/usr/bin/env bash
set -euo pipefail

SETTINGS="${SETTINGS:-$HOME/.claude/settings.json}"
BACKUP="$SETTINGS.bak"

if [ ! -f "$BACKUP" ]; then
  echo "Error: no backup found at $BACKUP" >&2
  exit 1
fi

cp "$BACKUP" "$SETTINGS"
echo "Restored $SETTINGS from backup."
echo "Restart Claude Code to apply changes."
