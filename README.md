# GrindLlama

GrindLlama is a World of Warcraft Classic addon that suggests open-world grinding locations from structured route data. It auto-ranks spots from the player's current level and faction, then shows the best matches in a movable in-game panel.

## Current Features

- Auto-detects player level and faction.
- Ranks routes by level fit, faction, XP quality, density, travel time, danger, competition, and current zone.
- Displays the top recommendation plus a ranked shortlist.
- Includes a minimap toggle button and slash commands.
- Stores window position, lock state, visibility, and level search range in saved variables.
- Ships with seed Classic route data so the addon is usable before the spreadsheet import is added.

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

The planned workflow is:

1. Maintain route rows in the spreadsheet using the schema in `docs/spreadsheet-schema.md`.
2. Export the sheet as CSV when route data changes.
3. Convert CSV rows into `GrindLlama_Locations` Lua entries.
4. Package the updated addon folder.

The sample data in `Data/GrindLocations.lua` follows the intended structure and can be replaced by generated spreadsheet output later.

## Addon Folder Layout

- `GrindLlama.toc` loads the addon files.
- `Data/GrindLocations.lua` contains route data.
- `Core.lua` handles player detection, scoring, slash commands, and saved variables.
- `UI.lua` builds the in-game panel and minimap toggle.
- `docs/spreadsheet-schema.md` documents the spreadsheet columns expected later.
- `templates/grind_locations_template.csv` gives a starter CSV format.