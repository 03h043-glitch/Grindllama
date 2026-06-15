local addonName = ...

local GrindLlama = _G.GrindLlama or {}
_G.GrindLlama = GrindLlama

GrindLlama.name = addonName or "GrindLlama"
GrindLlama.version = "0.1.0"

local DEFAULTS = {
    levelWindow = 6,
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
    local distance = self:GetLevelDistance(location, level)
    local status = self:GetLevelStatus(location, level)
    local score = 100 - (distance * 18)

    if status == "Ideal" then
        score = score + 18
    elseif status == "Viable" then
        score = score + 10
    end

    score = score + ((location.xp or 3) * 5)
    score = score + ((location.density or 3) * 4)
    score = score + ((location.gold or 1) * 2)
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

    return score, status, distance
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
    local window = (self.db and self.db.levelWindow) or DEFAULTS.levelWindow
    local near = {}
    local fallback = {}

    for _, location in ipairs(locations) do
        if self:IsFactionMatch(location, faction) then
            local score, status, distance = self:ScoreLocation(location, level, faction)
            local result = {
                location = location,
                score = score,
                status = status,
                distance = distance
            }

            if distance <= window then
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
    window = tonumber(window) or DEFAULTS.levelWindow
    self.db.levelWindow = Clamp(math.floor(window), 0, 20)
    self:Refresh()
end

function GrindLlama:Refresh()
    self:RefreshPlayer()
    self:GetSuggestions(self.playerLevel, self.playerFaction, 5)

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
        self:Print("Level search window set to +/-" .. self.db.levelWindow .. ".")
        return
    end

    self:Print("Commands: /gll, /gll show, /gll hide, /gll lock, /gll reset, /gll window 6")
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
