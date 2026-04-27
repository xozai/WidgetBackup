# macOS Widget Backup

Automated backup and restore for macOS Sonoma desktop widgets. Runs daily via `launchd` and keeps a rolling 7-day history in `~/Backups/widgets/`.

## What gets backed up

macOS Sonoma stores widget configuration across several locations. The backup script captures all of them:

| What | Where |
|------|-------|
| Desktop widget layout & positions | `com.apple.chronod` preference |
| WidgetKit framework settings | `com.apple.widgetkit` preference |
| Widget registry | `~/Library/Application Support/NotificationCenter/` |
| Chronod app container | `~/Library/Containers/com.apple.chronod/` |
| Any additional `com.apple.widget*` plists | `~/Library/Preferences/` |

## Files

| File | Purpose |
|------|---------|
| `backup-widgets.sh` | Creates a timestamped snapshot and rotates old backups |
| `restore-widgets.sh` | Interactive restore — pick a snapshot, restores all files |
| `com.user.widget-backup.plist` | launchd job that runs the backup daily at 9 AM |

## Requirements

- macOS 14 Sonoma or later
- No third-party dependencies — uses only built-in macOS tools (`defaults`, `launchctl`, `bash`)

## Installation

**1. Make the scripts executable:**

```bash
chmod +x "/Users/jleos/Library/Mobile Documents/com~apple~ScriptEditor2/Documents/Backup Widgets/backup-widgets.sh"
chmod +x "/Users/jleos/Library/Mobile Documents/com~apple~ScriptEditor2/Documents/Backup Widgets/restore-widgets.sh"
```

**2. Install and activate the launchd scheduler:**

```bash
cp "/Users/jleos/Library/Mobile Documents/com~apple~ScriptEditor2/Documents/Backup Widgets/com.user.widget-backup.plist" \
   ~/Library/LaunchAgents/

launchctl load ~/Library/LaunchAgents/com.user.widget-backup.plist
```

**3. Run your first backup to verify everything works:**

```bash
bash "/Users/jleos/Library/Mobile Documents/com~apple~ScriptEditor2/Documents/Backup Widgets/backup-widgets.sh"
```

You should see output like:
```
[09:00:00] Starting widget backup → /Users/jleos/Backups/widgets/20260426_090000
[09:00:00]   ✓ Desktop widget layout (com.apple.chronod)
[09:00:00]   ✓ WidgetKit preferences
[09:00:00]   ✓ com.apple.widgets
[09:00:00] Backup complete.
[09:00:00] Done. Retained last 7 backups.
```

## Configuration

Both configurable values are at the top of `backup-widgets.sh`:

```bash
BACKUP_DIR="$HOME/Backups/widgets"   # Where snapshots are stored
KEEP_BACKUPS=7                        # How many daily backups to retain
```

To change the backup time, edit `com.user.widget-backup.plist` and update the `Hour` and `Minute` keys, then reload:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.widget-backup.plist
cp "/Users/jleos/Library/Mobile Documents/com~apple~ScriptEditor2/Documents/Backup Widgets/com.user.widget-backup.plist" \
   ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.widget-backup.plist
```

## Restoring

Run the restore script from Terminal:

```bash
bash "/Users/jleos/Library/Mobile Documents/com~apple~ScriptEditor2/Documents/Backup Widgets/restore-widgets.sh"
```

It will present a numbered list of available snapshots (newest first), ask for confirmation, stop the `chronod` daemon, restore all files, and prompt you to log out and back in to apply the changes.

## Logs

Backup output is written to:

- `~/Backups/widgets/widget-backup.log` — standard output
- `~/Backups/widgets/widget-backup-error.log` — errors

## Uninstalling

```bash
launchctl unload ~/Library/LaunchAgents/com.user.widget-backup.plist
rm ~/Library/LaunchAgents/com.user.widget-backup.plist
```

The backup history in `~/Backups/widgets/` can be deleted manually if no longer needed.

## Notes

Apple does not officially document the internal widget storage format, and it may change across macOS updates. If a restore doesn't fully take effect after a major OS upgrade, a full Time Machine restore is the most reliable fallback. This tool is designed to complement Time Machine with lightweight, targeted, widget-only daily snapshots.
