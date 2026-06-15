-- Auto-generated from vanilla_wow_classic_grinding_locations_expanded_addon_db.xlsx sheet 'Addon_DB'.
-- Update the workbook, then rerun tools\Convert-GrindLocationsFromXlsx.ps1.
local function SplitList(value)
    local result = {}
    if not value or value == "" then
        return result
    end
    for item in string.gmatch(value, "([^;]+)") do
        table.insert(result, item)
    end
    return result
end

local function SplitFields(line)
    local result = {}
    for value in string.gmatch(line .. "|", "([^|]*)|") do
        table.insert(result, value)
    end
    return result
end

local function FactionName(value)
    if value == "A" then
        return "Alliance"
    elseif value == "H" then
        return "Horde"
    end
    return "Both"
end

GrindLlama_Locations = GrindLlama_Locations or {}

function GrindLlama_LoadRouteData(rawData)
    for line in string.gmatch(rawData, "[^\r\n]+") do
        local row = SplitFields(line)
        table.insert(GrindLlama_Locations, {
            id = row[1], name = row[6], zone = row[5], subzone = row[6],
            minLevel = tonumber(row[2]), maxLevel = tonumber(row[3]), idealMin = tonumber(row[2]), idealMax = tonumber(row[3]), faction = FactionName(row[4]),
            mobTypes = SplitList(row[7]), mobLevelRange = row[8],
            density = tonumber(row[9]), danger = tonumber(row[10]), travel = tonumber(row[11]), xp = tonumber(row[12]), gold = tonumber(row[13]),
            competition = tonumber(row[14]), priorityScore = tonumber(row[15]),
            coordinates = row[16], spawnType = row[17], farmStyle = row[18],
            loot = SplitList(row[19]), professions = SplitList(row[20]), risks = row[21], notes = row[22], tags = SplitList(row[23])
        })
    end
end
