# GrindLlama

GrindLlama is a World of Warcraft Classic addon that suggests open-world grinding locations from structured route data. It auto-ranks spots from the player's current level and faction, then shows the best matches in a movable in-game panel.

## Current Features

- Auto-detects player level and faction.
- Ranks routes by level fit, faction, XP quality, density, travel time, danger, competition, and current zone.
- Displays the top recommendation plus a ranked shortlist.
- Includes a minimap toggle button and slash commands.
- Stores window position, lock state, visibility, and level search range in saved variables.
- Ships with generated Classic route data from `vanilla_wow_classic_grinding_locations_expanded_addon_db.xlsx`.

## Installation

1. Copy this repository folder into `World of Warcraft\_classic_era_\Interface\AddOns\GrindLlama`.
2. Restart the game or run `/reload`.
3. Open the addon with `/gll` or the minimap button.

If your client marks the addon as out of date, enable "Load out of date AddOns" on the character AddOns screen.

## Commands

- `/gll` or `/grindllama` toggles the panel.
- `/gll show` opens the panel.
- `/gll hide` closes the panel.
- `/gll lock` locks or unlocks dragging.
- `/gll reset` resets the panel position.
- `/gll window 6` changes the suggestion range to plus or minus 6 levels.

## Spreadsheet Data Workflow

WoW addons cannot read `.xlsx` or Google Sheets directly at runtime. The spreadsheet needs to be exported and converted into Lua data in `Data/GrindLocations.lua`.

Current workflow:

1. Maintain route rows in the workbook's `Addon_DB` sheet.
2. Commit the updated workbook to the repo.
3. Regenerate addon data:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Convert-GrindLocationsFromXlsx.ps1 -WorkbookPath .\vanilla_wow_classic_grinding_locations_expanded_addon_db.xlsx -SheetName Addon_DB -OutputPath .\Data\GrindLocations.lua
```

The generated `Data/GrindLocations.lua` currently contains 178 routes from the workbook. It embeds the compact fields the addon needs at runtime; the workbook remains the full source for audit/source notes and richer spreadsheet-only columns.

## Addon Folder Layout

- `GrindLlama.toc` loads the addon files.
- `Data/GrindLocations.lua` contains route data.
- `Core.lua` handles player detection, scoring, slash commands, and saved variables.
- `UI.lua` builds the in-game panel and minimap toggle.
- `tools/Convert-GrindLocationsFromXlsx.ps1` converts the workbook `Addon_DB` sheet into Lua data.
- `docs/spreadsheet-schema.md` documents the workbook columns used by the converter.
- `templates/grind_locations_template.csv` gives a starter CSV format.
