#!/bin/bash
# backup-widgets.sh — macOS Sonoma desktop widget backup
# Place this at: ~/scripts/backup-widgets.sh
# Make executable: chmod +x ~/scripts/backup-widgets.sh

BACKUP_DIR="$HOME/Backups/widgets"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"
KEEP_BACKUPS=7   # Number of daily backups to retain

mkdir -p "$BACKUP_PATH"

log() { echo "[$(date '+%H:%M:%S')] $1"; }

log "Starting widget backup → $BACKUP_PATH"

# 1. Desktop widget layout (chronod daemon — manages Sonoma desktop widgets)
if defaults export com.apple.chronod "$BACKUP_PATH/com.apple.chronod.plist" 2>/dev/null; then
    log "  ✓ Desktop widget layout (com.apple.chronod)"
else
    log "  – com.apple.chronod not found (no desktop widgets configured yet?)"
fi

# 2. WidgetKit framework preferences
if defaults export com.apple.widgetkit "$BACKUP_PATH/com.apple.widgetkit.plist" 2>/dev/null; then
    log "  ✓ WidgetKit preferences"
else
    log "  – com.apple.widgetkit not found"
fi

# 3. Notification Center / widget registry
if [ -d "$HOME/Library/Application Support/NotificationCenter" ]; then
    cp -r "$HOME/Library/Application Support/NotificationCenter" "$BACKUP_PATH/"
    log "  ✓ NotificationCenter data"
fi

# 4. Chronod app container (stores widget state per-app)
if [ -d "$HOME/Library/Containers/com.apple.chronod" ]; then
    cp -r "$HOME/Library/Containers/com.apple.chronod" "$BACKUP_PATH/"
    log "  ✓ Chronod container"
fi

# 5. Any extra widget-related plists in ~/Library/Preferences
for plist in "$HOME/Library/Preferences"/com.apple.widget*.plist; do
    [ -f "$plist" ] || continue
    name=$(basename "$plist" .plist)
    cp "$plist" "$BACKUP_PATH/${name}.plist"
    log "  ✓ $name"
done

log "Backup complete."

# --- Rolling cleanup: keep only the last $KEEP_BACKUPS snapshots ---
TOTAL=$(ls -1d "$BACKUP_DIR"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_* 2>/dev/null | wc -l | tr -d ' ')
DELETE_COUNT=$(( TOTAL - KEEP_BACKUPS ))
if [ "$DELETE_COUNT" -gt 0 ]; then
    OLD=()
    while IFS= read -r line; do OLD+=("$line"); done < <(ls -1d "$BACKUP_DIR"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_* 2>/dev/null | sort | head -n "$DELETE_COUNT")
    for old in "${OLD[@]}"; do
        rm -rf "$old"
        log "  Removed old backup: $(basename "$old")"
    done
fi

log "Done. Retained last $KEEP_BACKUPS backups."