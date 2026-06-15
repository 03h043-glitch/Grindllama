# GrindLlama Spreadsheet Schema

Use one row per grinding route. Keep column names stable so the sheet can be converted into `Data/GrindLocations.lua` later.

## Required Columns

| Column | Example | Notes |
| --- | --- | --- |
| `id` | `tanaris-wastewander-40-45` | Stable lowercase identifier. Use letters, numbers, and hyphens. |
| `name` | `Wastewander Bandit Camps` | Display name shown in the addon. |
| `zone` | `Tanaris` | In-game zone name. |
| `subzone` | `Waterspring Field` | Local area or route label. |
| `mapID` | `1446` | Optional but useful for future map features. |
| `coordinates` | `62, 37` | Main route start or center point. |
| `minLevel` | `40` | Lowest recommended player level. |
| `maxLevel` | `45` | Highest useful player level. |
| `idealMin` | `42` | Start of the strongest level range. |
| `idealMax` | `44` | End of the strongest level range. |
| `faction` | `Both` | Use `Alliance`, `Horde`, or `Both`. |
| `mobTypes` | `Wastewander Bandit;Wastewander Thief` | Semicolon-separated mob names. |
| `density` | `5` | 1 low to 5 high. |
| `danger` | `4` | 1 safe to 5 dangerous. |
| `travel` | `3` | 1 easy to reach to 5 remote. |
| `xp` | `5` | 1 weak to 5 excellent. |
| `gold` | `4` | 1 weak to 5 excellent. |
| `competition` | `4` | 1 quiet to 5 crowded. |
| `loot` | `Silk Cloth;Mageweave Cloth;Coins` | Semicolon-separated notable loot. |
| `professions` | `First Aid` | Semicolon-separated profession value. |
| `route` | `Clear one camp at a time...` | Short route instructions. |
| `notes` | `High-value humanoid grinding...` | Short practical note. |

## Scoring Notes

The addon gives the most weight to level fit, then XP, density, danger, travel, gold, competition, faction fit, and current-zone match. Keep rating scales consistent across rows so the ranking feels predictable.

## Runtime Constraint

The game client loads Lua files listed in `GrindLlama.toc`. It will not load a spreadsheet file directly, so the final import step must produce valid Lua table entries.