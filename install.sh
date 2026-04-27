#!/bin/bash
# install.sh — one-command setup for macOS widget backup

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.user.widget-backup.plist"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"

echo "Installing macOS widget backup..."

chmod +x "$SCRIPT_DIR/backup-widgets.sh" "$SCRIPT_DIR/restore-widgets.sh"

# Create log directory before launchd needs it, then run first backup
mkdir -p "$HOME/Backups/widgets"
echo ""
echo "Running first backup..."
bash "$SCRIPT_DIR/backup-widgets.sh"

echo ""
echo "Installing launchd job (daily 9 AM)..."
cp "$SCRIPT_DIR/$PLIST_NAME" "$LAUNCH_AGENTS/"
launchctl load "$LAUNCH_AGENTS/$PLIST_NAME"

echo ""
echo "Done. Backups will run daily at 9 AM."
echo "Snapshots: ~/Backups/widgets/"
echo "To restore: bash \"$SCRIPT_DIR/restore-widgets.sh\""
