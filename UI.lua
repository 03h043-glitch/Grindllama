local GrindLlama = _G.GrindLlama
if not GrindLlama then
    return
end

local UI = {}
GrindLlama.UI = UI

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local PANEL_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

local ROW_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

local function NewPanel(name, parent)
    return CreateFrame("Frame", name, parent, BACKDROP_TEMPLATE)
end

local function ApplyPanelBackdrop(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop(PANEL_BACKDROP)
        frame:SetBackdropColor(0.035, 0.035, 0.032, 0.94)
        frame:SetBackdropBorderColor(0.24, 0.22, 0.18, 0.95)
    end
end

local function ApplyRowBackdrop(row, hovered)
    if row.SetBackdrop then
        row:SetBackdrop(ROW_BACKDROP)
        if hovered then
            row:SetBackdropColor(0.12, 0.105, 0.08, 0.98)
            row:SetBackdropBorderColor(0.82, 0.66, 0.34, 0.95)
        else
            row:SetBackdropColor(0.055, 0.052, 0.047, 0.82)
            row:SetBackdropBorderColor(0.16, 0.15, 0.13, 0.9)
        end
    end
end

local function Join(values, fallback)
    if type(values) ~= "table" or #values == 0 then
        return fallback or ""
    end
    return table.concat(values, ", ")
end

local function AddLine(parts, label, value)
    if value and value ~= "" then
        table.insert(parts, label .. ": " .. value)
    end
end

local function AddTooltipLine(value, r, g, b)
    if GameTooltip and value and value ~= "" then
        GameTooltip:AddLine(value, r or 0.86, g or 0.82, b or 0.74, true)
    end
end

local function AddTooltipPair(label, value)
    if GameTooltip and value and value ~= "" then
        GameTooltip:AddDoubleLine(label, tostring(value), 0.72, 0.70, 0.64, 1.0, 0.92, 0.62)
    end
end

local function MobName(location)
    if location.mobTypes and location.mobTypes[1] and location.mobTypes[1] ~= "" then
        return location.mobTypes[1]
    end
    return location.name or "Unknown mob"
end

local function MobLevelText(location)
    if location.mobLevelRange and location.mobLevelRange ~= "" then
        return location.mobLevelRange
    end
    return tostring(location.minLevel or "?") .. "-" .. tostring(location.maxLevel or "?")
end

local function OffsetText(offset)
    offset = offset or 0
    if offset > 0 then
        return "+" .. tostring(offset)
    end
    return tostring(offset)
end

local function ScoreText(result)
    return tostring(math.floor((result.score or 0) + 0.5))
end

local function ScoreColor(result)
    local score = result and result.score or 0
    if score >= 130 then
        return 0.38, 0.92, 0.52
    end
    if score >= 105 then
        return 0.95, 0.80, 0.38
    end
    if score >= 80 then
        return 0.82, 0.76, 0.66
    end
    return 0.92, 0.48, 0.38
end

local function RouteText(location)
    if location.route and location.route ~= "" then
        return location.route
    end

    local parts = {}
    if location.farmStyle and location.farmStyle ~= "" then
        table.insert(parts, location.farmStyle .. " route.")
    end
    if location.subzone and location.zone then
        table.insert(parts, "Farm around " .. location.subzone .. " in " .. location.zone .. ".")
    end
    if location.mobTypes and #location.mobTypes > 0 then
        table.insert(parts, "Focus mobs: " .. Join(location.mobTypes, "TBD") .. ".")
    end

    if #parts == 0 then
        return ""
    end

    return table.concat(parts, " ")
end

function UI:Initialize()
    if self.initialized then
        return
    end

    self.rows = {}
    self:CreateMainFrame()
    self:CreateMinimapButton()
    self:RestorePosition()
    self.initialized = true

    if GrindLlama.db.ui.shown then
        self:Show()
    else
        self:Hide()
    end
end

function UI:CreateMainFrame()
    local frame = NewPanel("GrindLlamaFrame", UIParent)
    frame:SetSize(382, 306)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyPanelBackdrop(frame)

    frame:SetScript("OnDragStart", function(panel)
        if not GrindLlama.db.ui.locked then
            panel:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(panel)
        panel:StopMovingOrSizing()
        UI:SavePosition()
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("GrindLlama")
    title:SetTextColor(1.0, 0.86, 0.48)

    self.context = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.context:SetPoint("LEFT", title, "RIGHT", 10, 0)
    self.context:SetPoint("RIGHT", frame, "RIGHT", -76, 0)
    self.context:SetJustifyH("LEFT")
    self.context:SetTextColor(0.74, 0.72, 0.66)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetSize(24, 24)
    closeButton:SetPoint("TOPRIGHT", -6, -6)
    closeButton:SetScript("OnClick", function()
        UI:Hide()
    end)

    self.lockButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.lockButton:SetSize(26, 20)
    self.lockButton:SetPoint("RIGHT", closeButton, "LEFT", -4, 0)
    self.lockButton:SetScript("OnClick", function()
        UI:ToggleLock()
    end)
    self.lockButton:SetScript("OnEnter", function(owner)
        if GameTooltip then
            GameTooltip:SetOwner(owner, "ANCHOR_TOP")
            GameTooltip:AddLine("Drag Lock")
            GameTooltip:AddLine("Locks or unlocks the GrindLlama window.", 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    self.lockButton:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    local controls = NewPanel(nil, frame)
    controls:SetPoint("TOPLEFT", 8, -36)
    controls:SetPoint("TOPRIGHT", -8, -36)
    controls:SetHeight(32)
    if controls.SetBackdrop then
        controls:SetBackdrop(ROW_BACKDROP)
        controls:SetBackdropColor(0.045, 0.044, 0.04, 0.88)
        controls:SetBackdropBorderColor(0.12, 0.11, 0.10, 0.9)
    end

    local minusButton = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    minusButton:SetSize(24, 20)
    minusButton:SetPoint("LEFT", 8, 0)
    minusButton:SetText("-")
    minusButton:SetScript("OnClick", function()
        GrindLlama:AdjustMobLevelOffset(-1)
    end)

    self.targetText = controls:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.targetText:SetSize(116, 20)
    self.targetText:SetPoint("LEFT", minusButton, "RIGHT", 6, 0)
    self.targetText:SetJustifyH("CENTER")
    self.targetText:SetTextColor(0.88, 0.83, 0.72)

    local plusButton = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    plusButton:SetSize(24, 20)
    plusButton:SetPoint("LEFT", self.targetText, "RIGHT", 6, 0)
    plusButton:SetText("+")
    plusButton:SetScript("OnClick", function()
        GrindLlama:AdjustMobLevelOffset(1)
    end)

    local refreshButton = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    refreshButton:SetSize(62, 20)
    refreshButton:SetPoint("RIGHT", -8, 0)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        GrindLlama:Refresh()
    end)

    self.rangeText = controls:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.rangeText:SetPoint("RIGHT", refreshButton, "LEFT", -10, 0)
    self.rangeText:SetTextColor(0.62, 0.60, 0.54)

    local header = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    header:SetPoint("TOPLEFT", 13, -79)
    header:SetText("Mob")

    local zoneHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    zoneHeader:SetPoint("TOPLEFT", 136, -79)
    zoneHeader:SetText("Zone")

    local levelHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    levelHeader:SetPoint("TOPLEFT", 250, -79)
    levelHeader:SetText("Lvl")

    local scoreHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    scoreHeader:SetPoint("TOPRIGHT", -14, -79)
    scoreHeader:SetText("Score")

    for index = 1, 8 do
        self.rows[index] = self:CreateRow(index)
    end

    self.frame = frame
    self:UpdateLockText()
end

function UI:CreateRow(index)
    local row = CreateFrame("Button", nil, self.frame, BACKDROP_TEMPLATE)
    row:SetSize(358, 24)
    row:SetPoint("TOPLEFT", 12, -96 - ((index - 1) * 25))
    row:RegisterForClicks("LeftButtonUp")
    ApplyRowBackdrop(row, false)

    row.mob = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.mob:SetPoint("LEFT", 8, 0)
    row.mob:SetSize(116, 16)
    row.mob:SetJustifyH("LEFT")
    row.mob:SetTextColor(0.92, 0.88, 0.78)

    row.zone = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.zone:SetPoint("LEFT", row.mob, "RIGHT", 8, 0)
    row.zone:SetSize(108, 16)
    row.zone:SetJustifyH("LEFT")
    row.zone:SetTextColor(0.72, 0.76, 0.80)

    row.levels = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.levels:SetPoint("LEFT", row.zone, "RIGHT", 8, 0)
    row.levels:SetSize(48, 16)
    row.levels:SetJustifyH("LEFT")
    row.levels:SetTextColor(0.82, 0.78, 0.68)

    row.score = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.score:SetPoint("RIGHT", -8, 0)
    row.score:SetSize(38, 16)
    row.score:SetJustifyH("RIGHT")

    row:SetScript("OnEnter", function(button)
        ApplyRowBackdrop(button, true)
        UI:ShowTooltip(button, button.result)
    end)

    row:SetScript("OnLeave", function(button)
        ApplyRowBackdrop(button, false)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    row:SetScript("OnClick", function(button)
        UI:ShowTooltip(button, button.result)
    end)

    return row
end

function UI:CreateMinimapButton()
    if not Minimap then
        return
    end

    local button = CreateFrame("Button", "GrindLlamaMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 4, -4)
    button:SetFrameStrata("MEDIUM")
    button:SetNormalTexture("Interface\\Icons\\Ability_Hunter_AspectOfTheCheetah")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", -11, 11)

    button:SetScript("OnClick", function()
        UI:Toggle()
    end)

    button:SetScript("OnEnter", function(owner)
        if GameTooltip then
            GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
            GameTooltip:AddLine("GrindLlama")
            GameTooltip:AddLine("Click to toggle the grind list.", 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    self.minimapButton = button
end

function UI:Refresh()
    if not self.initialized then
        return
    end

    local level = GrindLlama.playerLevel or GrindLlama:GetPlayerLevel()
    local faction = GrindLlama.playerFaction or GrindLlama:GetPlayerFaction()
    local suggestions = GrindLlama:GetSuggestions(level, faction, 8)
    local count = #(_G.GrindLlama_Locations or {})
    local offset = GrindLlama.db.mobLevelOffset or 0
    local targetMobLevel = GrindLlama:GetTargetMobLevel(level)
    local window = GrindLlama.db.mobLevelWindow or 2

    self.context:SetText("Level " .. level .. " " .. faction .. " / " .. count .. " routes")
    self.targetText:SetText("Mob " .. OffsetText(offset) .. " -> " .. targetMobLevel)
    self.rangeText:SetText("range " .. window)
    self:UpdateLockText()

    for index, row in ipairs(self.rows) do
        self:RefreshRow(row, suggestions[index])
    end
end

function UI:RefreshRow(row, result)
    row.result = result

    if not result then
        row:Hide()
        return
    end

    local location = result.location
    local r, g, b = ScoreColor(result)

    row:Show()
    row.mob:SetText(MobName(location))
    row.zone:SetText(location.zone or "Unknown")
    row.levels:SetText(MobLevelText(location))
    row.score:SetText(ScoreText(result))
    row.score:SetTextColor(r, g, b)
    ApplyRowBackdrop(row, false)
end

function UI:ShowTooltip(owner, result)
    if not GameTooltip or not result then
        return
    end

    local location = result.location
    local detailParts = {}
    local ratingParts = {}

    AddLine(detailParts, "Area", location.subzone or location.name)
    AddLine(detailParts, "Coords", location.coordinates)
    AddLine(detailParts, "Spawn", location.spawnType)
    AddLine(detailParts, "Style", location.farmStyle)
    AddLine(detailParts, "Faction", location.faction)
    AddLine(ratingParts, "XP", location.xp)
    AddLine(ratingParts, "Density", location.density)
    AddLine(ratingParts, "Gold", location.gold)
    AddLine(ratingParts, "Danger", location.danger)
    AddLine(ratingParts, "Competition", location.competition)

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(MobName(location), 1.0, 0.86, 0.45)
    GameTooltip:AddLine((location.zone or "Unknown zone") .. " - mobs " .. MobLevelText(location), 0.82, 0.82, 0.76)
    AddTooltipPair("Score", ScoreText(result))
    AddTooltipPair("Target mob", tostring(result.targetMobLevel or "?") .. " (" .. tostring(result.status or "match") .. ")")
    if location.priorityScore and location.priorityScore > 0 then
        AddTooltipPair("Priority", location.priorityScore)
    end
    AddTooltipLine(table.concat(detailParts, "  "))
    AddTooltipLine(table.concat(ratingParts, "  "), 0.72, 0.82, 0.70)
    AddTooltipLine("Mobs: " .. Join(location.mobTypes, "TBD"), 0.88, 0.84, 0.75)
    local loot = Join(location.loot, "")
    local professions = Join(location.professions, "")
    if loot ~= "" then
        AddTooltipLine("Drops: " .. loot, 0.78, 0.82, 0.72)
    end
    if professions ~= "" then
        AddTooltipLine("Professions: " .. professions, 0.72, 0.80, 0.88)
    end
    AddTooltipLine("Risks: " .. (location.risks or ""), 0.9, 0.70, 0.62)
    AddTooltipLine(RouteText(location), 0.82, 0.78, 0.70)
    AddTooltipLine(location.notes, 0.76, 0.74, 0.68)
    GameTooltip:Show()
end

function UI:Show()
    if not self.frame then
        return
    end
    self.frame:Show()
    GrindLlama.db.ui.shown = true
    self:Refresh()
end

function UI:Hide()
    if not self.frame then
        return
    end
    self.frame:Hide()
    GrindLlama.db.ui.shown = false
end

function UI:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function UI:SavePosition()
    if not self.frame then
        return
    end

    local point, _, relativePoint, x, y = self.frame:GetPoint(1)
    GrindLlama.db.ui.point = point or "CENTER"
    GrindLlama.db.ui.relativePoint = relativePoint or "CENTER"
    GrindLlama.db.ui.x = x or 0
    GrindLlama.db.ui.y = y or 0
end

function UI:RestorePosition()
    if not self.frame then
        return
    end

    local ui = GrindLlama.db.ui
    self.frame:ClearAllPoints()
    self.frame:SetPoint(ui.point or "CENTER", UIParent, ui.relativePoint or "CENTER", ui.x or 0, ui.y or 0)
end

function UI:ResetPosition()
    GrindLlama.db.ui.point = "CENTER"
    GrindLlama.db.ui.relativePoint = "CENTER"
    GrindLlama.db.ui.x = 0
    GrindLlama.db.ui.y = 0
    self:RestorePosition()
end

function UI:ToggleLock()
    GrindLlama.db.ui.locked = not GrindLlama.db.ui.locked
    self:UpdateLockText()
end

function UI:UpdateLockText()
    if not self.lockButton then
        return
    end
    if GrindLlama.db.ui.locked then
        self.lockButton:SetText("U")
    else
        self.lockButton:SetText("L")
    end
end
