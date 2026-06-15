# GrindLlama

GrindLlama is a World of Warcraft Classic addon that suggests open-world grinding locations from structured route data. It auto-ranks spots from the player's current level, faction, and preferred mob level, then shows the best matches in a small movable list.

## Current Features

- Auto-detects player level and faction.
- Ranks routes by desired mob level, faction, XP quality, density, travel time, danger, competition, spreadsheet priority, and current zone.
- Shows one minimal list window with only mob name, zone, mob level range, and score visible for each row.
- Shows farm details in a tooltip when hovering over a row.
- Lets the user adjust the target mob level relative to their own level.
- Includes a minimap toggle button and slash commands.
- Stores window position, lock state, visibility, target mob offset, and mob-level tolerance in saved variables.
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
- `/gll mob +1` targets mobs one level above the player.
- `/gll mob -2` targets mobs two levels below the player.
- `/gll window 2` changes the mob-level tolerance to plus or minus 2 levels.

## Spreadsheet Data Workflow

WoW addons cannot read `.xlsx` or Google Sheets directly at runtime. The spreadsheet needs to be exported and converted into Lua data in `Data/GrindLocations.lua` and the numbered `Data/GrindLocations_*.lua` shards.

Current workflow:

1. Maintain route rows in the workbook's `Addon_DB` sheet.
2. Commit the updated workbook to the repo.
3. Regenerate addon data:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Convert-GrindLocationsFromXlsx.ps1 -WorkbookPath .\vanilla_wow_classic_grinding_locations_expanded_addon_db.xlsx -SheetName Addon_DB -OutputPath .\Data\GrindLocations.lua
```

The generated data currently contains 178 routes from the workbook. It embeds the list fields and hover-detail fields the addon needs at runtime; the workbook remains the full source for audit/source notes and spreadsheet-only columns.

## Addon Folder Layout

- `GrindLlama.toc` loads the addon files.
- `Data/GrindLocations.lua` contains the generated route loader.
- `Data/GrindLocations_*.lua` contains generated route data shards.
- `Core.lua` handles player detection, scoring, slash commands, and saved variables.
- `UI.lua` builds the in-game panel and minimap toggle.
- `tools/Convert-GrindLocationsFromXlsx.ps1` converts the workbook `Addon_DB` sheet into Lua data.
- `docs/spreadsheet-schema.md` documents the workbook columns used by the converter.
- `templates/grind_locations_template.csv` gives a starter CSV format.
