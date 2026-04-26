#!/bin/bash
# restore-widgets.sh — macOS Sonoma desktop widget restore
# Place this at: ~/scripts/restore-widgets.sh
# Make executable: chmod +x ~/scripts/restore-widgets.sh
# Run manually: bash ~/scripts/restore-widgets.sh

BACKUP_DIR="$HOME/Backups/widgets"

echo "=============================="
echo " macOS Widget Restore Tool"
echo "=============================="
echo ""

# List available backups newest-first
mapfile -t BACKUPS < <(ls -1d "$BACKUP_DIR"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_* 2>/dev/null | sort -r)

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo "No backups found in $BACKUP_DIR"
    exit 1
fi

echo "Available backups (newest first):"
echo ""
for i in "${!BACKUPS[@]}"; do
    folder=$(basename "${BACKUPS[$i]}")
    # Format: 20241023_143000 → 2024-10-23 14:30:00
    pretty=$(echo "$folder" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3  \4:\5:\6/')
    printf "  [%d] %s\n" "$((i+1))" "$pretty"
done

echo ""
read -r -p "Enter number to restore (or q to quit): " CHOICE

[[ "$CHOICE" == "q" || "$CHOICE" == "Q" ]] && { echo "Cancelled."; exit 0; }

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#BACKUPS[@]} ]; then
    echo "Invalid choice. Exiting."
    exit 1
fi

RESTORE_PATH="${BACKUPS[$((CHOICE-1))]}"
echo ""
echo "Selected: $(basename "$RESTORE_PATH")"
echo ""
echo "⚠️  This will overwrite your current widget configuration."
read -r -p "Continue? (y/N): " CONFIRM

[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && { echo "Cancelled."; exit 0; }

echo ""
echo "Stopping widget daemon (chronod)..."
killall chronod 2>/dev/null
sleep 2

# Restore chronod plist
if [ -f "$RESTORE_PATH/com.apple.chronod.plist" ]; then
    defaults import com.apple.chronod "$RESTORE_PATH/com.apple.chronod.plist"
    echo "  ✓ Desktop widget layout restored"
fi

# Restore widgetkit plist
if [ -f "$RESTORE_PATH/com.apple.widgetkit.plist" ]; then
    defaults import com.apple.widgetkit "$RESTORE_PATH/com.apple.widgetkit.plist"
    echo "  ✓ WidgetKit preferences restored"
fi

# Restore any extra widget plists
for plist in "$RESTORE_PATH"/com.apple.widget*.plist; do
    [ -f "$plist" ] || continue
    name=$(basename "$plist" .plist)
    # Skip the ones already handled above
    [[ "$name" == "com.apple.chronod" || "$name" == "com.apple.widgetkit" ]] && continue
    defaults import "$name" "$plist"
    echo "  ✓ $name restored"
done

# Restore NotificationCenter
if [ -d "$RESTORE_PATH/NotificationCenter" ]; then
    rm -rf "$HOME/Library/Application Support/NotificationCenter"
    cp -r "$RESTORE_PATH/NotificationCenter" "$HOME/Library/Application Support/"
    echo "  ✓ NotificationCenter data restored"
fi

# Restore Chronod container
if [ -d "$RESTORE_PATH/com.apple.chronod" ]; then
    rm -rf "$HOME/Library/Containers/com.apple.chronod"
    cp -r "$RESTORE_PATH/com.apple.chronod" "$HOME/Library/Containers/"
    echo "  ✓ Chronod container restored"
fi

echo ""
echo "✅ Restore complete."
echo "   Log out and log back in (or restart) for all changes to take effect."
