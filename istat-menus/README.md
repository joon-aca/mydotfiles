# iStat Menus Configuration

This directory contains iStat Menus settings and preferences.

## Files

- `iStat Menus Settings.ismp` - Complete iStat Menus configuration including widgets, themes, and monitoring preferences

## What is iStat Menus?

iStat Menus is a macOS menu bar system monitor that displays:
- CPU usage and performance
- Memory usage
- Network activity
- Disk usage and activity
- Battery information
- Temperature sensors
- Date/time customization
- Weather

## How to Import Settings

1. Open **iStat Menus** app
2. Go to **iStat Menus** → **Settings** (or press ⌘,)
3. Click the **Settings** tab at the top
4. Click **Import Settings...**
5. Select `iStat Menus Settings.ismp` from this directory
6. Click **Open**
7. Confirm the import

## How to Export Updated Settings

When you customize your iStat Menus and want to save the configuration:

1. Open iStat Menus Settings (⌘,)
2. Go to the **Settings** tab
3. Click **Export Settings...**
4. Save to this directory as `iStat Menus Settings.ismp` (overwrite existing)
5. Commit changes to git

## What's Included

The .ismp file typically includes:
- All widget configurations (CPU, memory, network, etc.)
- Menu bar layout and order
- Color themes and styling
- Update intervals for each monitor
- Notification settings
- Graph preferences
- Historical data retention settings

## Notes

- iStat Menus is a paid application (not included in Brewfile)
- Settings are tied to your iStat Menus version
- Some settings may require the same or newer version to import
