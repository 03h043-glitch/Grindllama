local addonName = ...

local GrindLlama = _G.GrindLlama or {}
_G.GrindLlama = GrindLlama

GrindLlama.name = addonName or "GrindLlama"
GrindLlama.version = "0.1.0"

local DEFAULTS = {
    levelWindow = 6,
    mobLevelOffset = 0,
    mobLevelWindow = 2,
    ui = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        shown = true,
        locked = false,
        minimapShown = true
    }
}

local function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function Lower(value)
    if value == nil then
        return ""
    end
    return string.lower(tostring(value))
end

function GrindLlama:Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd36bGrindLlama|r: " .. tostring(message))
    end
end

function GrindLlama:GetPlayerLevel()
    local level = 1
    if UnitLevel then
        level = UnitLevel("player") or 1
    end
    if level < 1 then
        level = 1
    end
    return level
end

function GrindLlama:GetPlayerFaction()
    local faction
    if UnitFactionGroup then
        faction = UnitFactionGroup("player")
    end
    if faction == "Alliance" or faction == "Horde" then
        return faction
    end
    return "Both"
end

function GrindLlama:RefreshPlayer()
    self.playerLevel = self:GetPlayerLevel()
    self.playerFaction = self:GetPlayerFaction()
end

function GrindLlama:NormalizeFaction(faction)
    if faction == "Alliance" or faction == "Horde" or faction == "Both" then
        return faction
    end
    if faction == "Neutral" then
        return "Both"
    end
    return "Both"
end

function GrindLlama:IsFactionMatch(location, faction)
    local locationFaction = self:NormalizeFaction(location.faction)
    local playerFaction = self:NormalizeFaction(faction)
    return locationFaction == "Both" or playerFaction == "Both" or locationFaction == playerFaction
end

function GrindLlama:GetLevelDistance(location, level)
    local minLevel = location.minLevel or 1
    local maxLevel = location.maxLevel or minLevel

    if level < minLevel then
        return minLevel - level
    end
    if level > maxLevel then
        return level - maxLevel
    end
    return 0
end

function GrindLlama:GetMobLevelRange(location)
    if location.mobMinLevel and location.mobMaxLevel then
        return location.mobMinLevel, location.mobMaxLevel
    end

    local text = location.mobLevelRange or ""
    local minLevel, maxLevel = string.match(text, "(%d+)%s*%-%s*(%d+)")
    if not minLevel then
        minLevel = string.match(text, "(%d+)")
        maxLevel = minLevel
    end

    minLevel = tonumber(minLevel) or location.minLevel or 1
    maxLevel = tonumber(maxLevel) or minLevel

    if minLevel > maxLevel then
        minLevel, maxLevel = maxLevel, minLevel
    end

    location.mobMinLevel = minLevel
    location.mobMaxLevel = maxLevel
    return minLevel, maxLevel
end

function GrindLlama:GetTargetMobLevel(level)
    level = level or self.playerLevel or self:GetPlayerLevel()
    local offset = (self.db and self.db.mobLevelOffset) or DEFAULTS.mobLevelOffset
    return Clamp(level + offset, 1, 63)
end

function GrindLlama:GetMobLevelDistance(location, targetMobLevel)
    local minLevel, maxLevel = self:GetMobLevelRange(location)

    if targetMobLevel < minLevel then
        return minLevel - targetMobLevel
    end
    if targetMobLevel > maxLevel then
        return targetMobLevel - maxLevel
    end
    return 0
end

function GrindLlama:GetMobLevelStatus(location, targetMobLevel)
    local minLevel, maxLevel = self:GetMobLevelRange(location)

    if targetMobLevel >= minLevel and targetMobLevel <= maxLevel then
        return "Target"
    end
    if targetMobLevel < minLevel then
        return "Low"
    end
    return "High"
end

function GrindLlama:GetLevelStatus(location, level)
    local minLevel = location.minLevel or 1
    local maxLevel = location.maxLevel or minLevel
    local idealMin = location.idealMin or minLevel
    local idealMax = location.idealMax or maxLevel

    if level >= idealMin and level <= idealMax then
        return "Ideal"
    end
    if level >= minLevel and level <= maxLevel then
        return "Viable"
    end
    if level < minLevel then
        local delta = minLevel - level
        if delta == 1 then
            return "1 level early"
        end
        return delta .. " levels early"
    end

    local delta = level - maxLevel
    if delta == 1 then
        return "1 level late"
    end
    return delta .. " levels late"
end

function GrindLlama:ScoreLocation(location, level, faction)
    local levelDistance = self:GetLevelDistance(location, level)
    local targetMobLevel = self:GetTargetMobLevel(level)
    local mobDistance = self:GetMobLevelDistance(location, targetMobLevel)
    local status = self:GetMobLevelStatus(location, targetMobLevel)
    local score = 100 - (mobDistance * 24) - (levelDistance * 8)

    if mobDistance == 0 then
        score = score + 24
    elseif mobDistance <= ((self.db and self.db.mobLevelWindow) or DEFAULTS.mobLevelWindow) then
        score = score + 8
    end

    score = score + ((location.xp or 3) * 5)
    score = score + ((location.density or 3) * 4)
    score = score + ((location.gold or 1) * 2)
    if location.priorityScore then
        score = score + (math.min(location.priorityScore, 100) / 4)
    end
    score = score - ((location.danger or 3) * 3)
    score = score - ((location.travel or 3) * 2)
    score = score - (math.max((location.competition or 3) - 3, 0) * 2)

    if self:NormalizeFaction(location.faction) == self:NormalizeFaction(faction) then
        score = score + 3
    end

    if GetCurrentZoneText then
        local currentZone = Lower(GetCurrentZoneText())
        if currentZone ~= "" and currentZone == Lower(location.zone) then
            score = score + 8
        end
    end

    return score, status, levelDistance, mobDistance, targetMobLevel
end

local function SortByScore(left, right)
    if left.score == right.score then
        return (left.location.minLevel or 1) < (right.location.minLevel or 1)
    end
    return left.score > right.score
end

function GrindLlama:GetSuggestions(level, faction, limit)
    level = level or self.playerLevel or self:GetPlayerLevel()
    faction = faction or self.playerFaction or self:GetPlayerFaction()
    limit = limit or 5

    local locations = _G.GrindLlama_Locations or {}
    local window = (self.db and self.db.mobLevelWindow) or DEFAULTS.mobLevelWindow
    local near = {}
    local fallback = {}

    for _, location in ipairs(locations) do
        if self:IsFactionMatch(location, faction) then
            local score, status, distance, mobDistance, targetMobLevel = self:ScoreLocation(location, level, faction)
            local result = {
                location = location,
                score = score,
                status = status,
                distance = distance,
                mobDistance = mobDistance,
                targetMobLevel = targetMobLevel
            }

            if mobDistance <= window then
                table.insert(near, result)
            else
                table.insert(fallback, result)
            end
        end
    end

    table.sort(near, SortByScore)
    table.sort(fallback, SortByScore)

    local fallbackIndex = 1
    while #near < limit and fallback[fallbackIndex] do
        table.insert(near, fallback[fallbackIndex])
        fallbackIndex = fallbackIndex + 1
    end

    local results = {}
    for index = 1, math.min(limit, #near) do
        results[index] = near[index]
    end

    self.lastSuggestions = results
    return results
end

function GrindLlama:SetLevelWindow(window)
    self:SetMobLevelWindow(window)
end

function GrindLlama:SetMobLevelWindow(window)
    window = tonumber(window) or DEFAULTS.mobLevelWindow
    self.db.mobLevelWindow = Clamp(math.floor(window), 0, 10)
    self:Refresh()
end

function GrindLlama:SetMobLevelOffset(offset)
    offset = tonumber(offset) or DEFAULTS.mobLevelOffset
    self.db.mobLevelOffset = Clamp(math.floor(offset), -10, 10)
    self:Refresh()
end

function GrindLlama:AdjustMobLevelOffset(delta)
    self:SetMobLevelOffset(((self.db and self.db.mobLevelOffset) or DEFAULTS.mobLevelOffset) + (tonumber(delta) or 0))
end

function GrindLlama:Refresh()
    self:RefreshPlayer()
    self:GetSuggestions(self.playerLevel, self.playerFaction, 8)

    if self.UI and self.UI.Refresh then
        self.UI:Refresh()
    end
end

function GrindLlama:HandleSlash(message)
    local command = Lower(message)

    if command == "" or command == "toggle" then
        if self.UI and self.UI.Toggle then
            self.UI:Toggle()
        end
        return
    end

    if command == "show" then
        if self.UI and self.UI.Show then
            self.UI:Show()
        end
        return
    end

    if command == "hide" then
        if self.UI and self.UI.Hide then
            self.UI:Hide()
        end
        return
    end

    if command == "lock" then
        if self.UI and self.UI.ToggleLock then
            self.UI:ToggleLock()
        end
        return
    end

    if command == "reset" then
        if self.UI and self.UI.ResetPosition then
            self.UI:ResetPosition()
            self:Print("Window position reset.")
        end
        return
    end

    local window = string.match(command, "^window%s+(%d+)$")
    if window then
        self:SetLevelWindow(tonumber(window))
        self:Print("Mob-level tolerance set to +/-" .. self.db.mobLevelWindow .. ".")
        return
    end

    local mobOffset = string.match(command, "^mob%s+([%+%-]?%d+)$") or string.match(command, "^mobs%s+([%+%-]?%d+)$")
    if mobOffset then
        self:SetMobLevelOffset(tonumber(mobOffset))
        self:Print("Target mob level set to player " .. string.format("%+d", self.db.mobLevelOffset) .. ".")
        return
    end

    self:Print("Commands: /gll, /gll show, /gll hide, /gll lock, /gll reset, /gll mob +1, /gll window 2")
end

function GrindLlama:OnAddonLoaded()
    GrindLlamaDB = GrindLlamaDB or {}
    CopyDefaults(DEFAULTS, GrindLlamaDB)
    self.db = GrindLlamaDB
    self.loaded = true

    if self.UI and self.UI.Initialize then
        self.UI:Initialize()
    end

    self:Refresh()
    self:Print("Ready. Type /gll to toggle grinding suggestions.")
end

SLASH_GRINDLLAMA1 = "/grindllama"
SLASH_GRINDLLAMA2 = "/gll"
SlashCmdList.GRINDLLAMA = function(message)
    GrindLlama:HandleSlash(message)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName ~= GrindLlama.name then
            return
        end

        GrindLlama:OnAddonLoaded()
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
        eventFrame:RegisterEvent("ZONE_CHANGED")
        eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        return
    end

    if GrindLlama.loaded then
        GrindLlama:Refresh()
    end
end)
