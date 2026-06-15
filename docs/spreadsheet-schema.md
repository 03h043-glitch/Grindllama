# GrindLlama Spreadsheet Schema

Use one row per grinding route. Keep column names stable so `tools/Convert-GrindLocationsFromXlsx.ps1` can convert the workbook's `Addon_DB` sheet into `Data/GrindLocations.lua` and numbered `Data/GrindLocations_*.lua` shards.

The workbook is the full source of truth. The generated Lua files embed the compact list fields plus the hover-detail fields the addon needs at runtime: route ID, level range, faction fit, zone, area, coordinates, mob group, mob level range, spawn type, farm style, drops, profession synergy, risks, notes, tags, derived ratings, and priority score. Source/audit columns stay in the workbook and can still influence derived ratings during conversion.

## Required Columns

| Column | Example | Notes |
| --- | --- | --- |
| `GrindID` | `VG145` | Stable route identifier from the workbook. |
| `MinLevel` | `40` | Lowest recommended player level. |
| `MaxLevel` | `45` | Highest useful player level. |
| `FactionFit` | `Both factions` | Human-readable faction fit. |
| `AllianceViable` | `Y` | `Y` when Alliance characters can use the route. |
| `HordeViable` | `Y` | `Y` when Horde characters can use the route. |
| `Zone` | `Tanaris` | In-game zone name. |
| `Area` | `Waterspring Field` | Local area or route label. |
| `ApproxCoords` | `62, 37` | Optional route start or center point. |
| `MobGroup` | `Wastewander Bandits, Wastewander Thieves` | Comma/semicolon-separated mob groups. |
| `MobLevelRange` | `40-45` | Display text for mob levels. |
| `SpawnType` | `Dense humanoid camp` | Display text for spawn behavior. |
| `SpawnWeight` | `4` | Source weighting used when priority score is absent. |
| `FarmStyle` | `Single-target` | Short route style shown in notes. |
| `Density` | `High` | Numeric or text density; converted to a 1-5 rating. |
| `DropsMentioned` | `Silk Cloth, Mageweave Cloth, Coins` | Comma/semicolon-separated notable loot. |
| `ProfessionSynergy` | `First Aid, Tailoring` | Comma/semicolon-separated profession value. |
| `Risks` | `Stealth mobs and caster chains` | Used for notes and a derived danger rating. |
| `Notes` | `High-value humanoid grinding...` | Short practical note. |
| `PriorityScore` | `87` | Spreadsheet priority; affects addon ranking. |
| `SourceKey` | `Wowhead_Leveling` | Short source label retained in the workbook for audit. |
| `SourceURL` | `https://...` | Source URL retained in the workbook for audit. |
| `Confidence` | `Medium` | Data confidence label retained in the workbook for audit. |
| `VanillaOnly` | `Y` | `Y` for routes valid for Vanilla/Classic Era. |
| `Tags` | `CLOTH, SKINNING` | Comma/semicolon-separated tags. |

## Scoring Notes

The addon gives the most weight to the user's target mob level, then route level fit, XP, density, danger, travel, gold, competition, spreadsheet priority, faction fit, and current-zone match. Keep rating scales consistent across rows so the ranking feels predictable.

## Runtime Constraint

The game client loads Lua files listed in `GrindLlama.toc`. It will not load a spreadsheet file directly, so the final import step must produce valid Lua loader and shard files.
