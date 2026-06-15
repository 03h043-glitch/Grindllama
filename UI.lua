local GrindLlama = _G.GrindLlama
if not GrindLlama then
    return
end

local UI = {}
GrindLlama.UI = UI

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local PANEL_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 0,
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local CARD_BACKDROP = {
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

local function ApplyPanelBackdrop(frame, r, g, b, a)
    if frame.SetBackdrop then
        frame:SetBackdrop(PANEL_BACKDROP)
        frame:SetBackdropColor(r, g, b, a)
        frame:SetBackdropBorderColor(0.92, 0.72, 0.38, 0.9)
    end
end

local function ApplyCardBackdrop(frame, selected)
    if frame.SetBackdrop then
        frame:SetBackdrop(CARD_BACKDROP)
        if selected then
            frame:SetBackdropColor(0.18, 0.13, 0.07, 0.94)
            frame:SetBackdropBorderColor(0.95, 0.78, 0.38, 0.9)
        else
            frame:SetBackdropColor(0.07, 0.06, 0.05, 0.88)
            frame:SetBackdropBorderColor(0.34, 0.26, 0.16, 0.95)
        end
    end
end

local function SetTextColorByQuality(fontString, value)
    value = value or 3
    if value >= 5 then
        fontString:SetTextColor(0.38, 0.95, 0.48)
    elseif value >= 4 then
        fontString:SetTextColor(0.62, 0.86, 1.0)
    elseif value >= 3 then
        fontString:SetTextColor(1.0, 0.86, 0.45)
    else
        fontString:SetTextColor(0.78, 0.72, 0.66)
    end
end

local function StatusColor(result)
    if not result then
        return 0.6, 0.6, 0.6
    end
    if result.status == "Ideal" then
        return 0.34, 0.9, 0.48
    end
    if result.status == "Viable" then
        return 0.95, 0.78, 0.32
    end
    if result.location and (GrindLlama.playerLevel or 1) < (result.location.minLevel or 1) then
        return 0.65, 0.78, 1.0
    end
    return 0.95, 0.48, 0.35
end

local function Join(values, fallback)
    if type(values) ~= "table" or #values == 0 then
        return fallback or ""
    end
    return table.concat(values, ", ")
end

local function AddText(parts, label, value)
    if value and value ~= "" then
        table.insert(parts, label .. ": " .. value)
    end
end

local function LevelText(location)
    return "Level " .. tostring(location.minLevel or "?") .. "-" .. tostring(location.maxLevel or "?")
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
        return "Route details TBD."
    end

    return table.concat(parts, " ")
end

local function StatText(label, value)
    value = value or 0
    local filled = string.rep("*", value)
    local empty = string.rep("-", math.max(5 - value, 0))
    return label .. " " .. filled .. empty
end

function UI:Initialize()
    if self.initialized then
        return
    end

    self.cards = {}
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
    frame:SetSize(460, 600)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyPanelBackdrop(frame, 0.045, 0.037, 0.028, 0.97)

    frame:SetScript("OnDragStart", function(panel)
        if not GrindLlama.db.ui.locked then
            panel:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(panel)
        panel:StopMovingOrSizing()
        UI:SavePosition()
    end)

    local header = frame:CreateTexture(nil, "ARTWORK")
    header:SetColorTexture(0.22, 0.12, 0.04, 0.92)
    header:SetPoint("TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", -4, -4)
    header:SetHeight(70)

    local accent = frame:CreateTexture(nil, "OVERLAY")
    accent:SetColorTexture(0.95, 0.64, 0.20, 0.95)
    accent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    accent:SetHeight(2)

    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\Icons\\Ability_Hunter_AspectOfTheCheetah")
    icon:SetSize(42, 42)
    icon:SetPoint("TOPLEFT", 18, -16)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1)
    title:SetText("GrindLlama")
    title:SetTextColor(1.0, 0.86, 0.42)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    subtitle:SetText("Classic grinding routes by level and faction")
    subtitle:SetTextColor(0.86, 0.78, 0.66)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -8, -10)
    closeButton:SetScript("OnClick", function()
        UI:Hide()
    end)

    self.context = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.context:SetPoint("TOPLEFT", 18, -84)
    self.context:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    self.context:SetJustifyH("LEFT")
    self.context:SetTextColor(0.9, 0.84, 0.74)

    self.lockButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.lockButton:SetSize(66, 22)
    self.lockButton:SetPoint("TOPRIGHT", -18, -80)
    self.lockButton:SetScript("OnClick", function()
        UI:ToggleLock()
    end)

    local minusButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    minusButton:SetSize(24, 22)
    minusButton:SetPoint("TOPRIGHT", self.lockButton, "BOTTOMRIGHT", -138, -8)
    minusButton:SetText("-")
    minusButton:SetScript("OnClick", function()
        GrindLlama:SetLevelWindow((GrindLlama.db.levelWindow or 6) - 1)
    end)

    self.windowText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.windowText:SetSize(108, 22)
    self.windowText:SetPoint("LEFT", minusButton, "RIGHT", 7, 0)
    self.windowText:SetJustifyH("CENTER")
    self.windowText:SetTextColor(0.82, 0.76, 0.66)

    local plusButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    plusButton:SetSize(24, 22)
    plusButton:SetPoint("LEFT", self.windowText, "RIGHT", 7, 0)
    plusButton:SetText("+")
    plusButton:SetScript("OnClick", function()
        GrindLlama:SetLevelWindow((GrindLlama.db.levelWindow or 6) + 1)
    end)

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(72, 22)
    refreshButton:SetPoint("RIGHT", self.lockButton, "LEFT", -8, 0)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        GrindLlama:Refresh()
    end)

    self.detail = NewPanel(nil, frame)
    self.detail:SetPoint("TOPLEFT", 18, -126)
    self.detail:SetPoint("TOPRIGHT", -18, -126)
    self.detail:SetHeight(142)
    ApplyPanelBackdrop(self.detail, 0.08, 0.065, 0.045, 0.94)

    self.detailBar = self.detail:CreateTexture(nil, "OVERLAY")
    self.detailBar:SetPoint("TOPLEFT", 0, 0)
    self.detailBar:SetPoint("BOTTOMLEFT", 0, 0)
    self.detailBar:SetWidth(5)
    self.detailBar:SetColorTexture(0.9, 0.74, 0.32, 1)

    self.detailLabel = self.detail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.detailLabel:SetPoint("TOPLEFT", 16, -12)
    self.detailLabel:SetText("RECOMMENDED NOW")
    self.detailLabel:SetTextColor(0.95, 0.72, 0.34)

    self.detailTitle = self.detail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.detailTitle:SetPoint("TOPLEFT", self.detailLabel, "BOTTOMLEFT", 0, -6)
    self.detailTitle:SetPoint("RIGHT", self.detail, "RIGHT", -18, 0)
    self.detailTitle:SetJustifyH("LEFT")

    self.detailMeta = self.detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.detailMeta:SetPoint("TOPLEFT", self.detailTitle, "BOTTOMLEFT", 0, -6)
    self.detailMeta:SetPoint("RIGHT", self.detail, "RIGHT", -18, 0)
    self.detailMeta:SetJustifyH("LEFT")
    self.detailMeta:SetTextColor(0.86, 0.79, 0.68)

    self.detailStats = self.detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.detailStats:SetPoint("TOPLEFT", self.detailMeta, "BOTTOMLEFT", 0, -6)
    self.detailStats:SetPoint("RIGHT", self.detail, "RIGHT", -18, 0)
    self.detailStats:SetJustifyH("LEFT")

    self.detailNotes = self.detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.detailNotes:SetPoint("TOPLEFT", self.detailStats, "BOTTOMLEFT", 0, -8)
    self.detailNotes:SetPoint("RIGHT", self.detail, "RIGHT", -18, 0)
    self.detailNotes:SetJustifyH("LEFT")
    self.detailNotes:SetTextColor(0.78, 0.73, 0.66)

    local listLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    listLabel:SetPoint("TOPLEFT", 18, -282)
    listLabel:SetText("BEST MATCHES")
    listLabel:SetTextColor(0.95, 0.72, 0.34)

    for index = 1, 5 do
        self.cards[index] = self:CreateCard(index)
    end

    self.frame = frame
    self:UpdateLockText()
end

function UI:CreateCard(index)
    local card = CreateFrame("Button", nil, self.frame, BACKDROP_TEMPLATE)
    card:SetSize(424, 52)
    card:SetPoint("TOPLEFT", 18, -304 - ((index - 1) * 58))
    card:RegisterForClicks("LeftButtonUp")
    ApplyCardBackdrop(card, false)

    card.bar = card:CreateTexture(nil, "OVERLAY")
    card.bar:SetPoint("TOPLEFT", 0, 0)
    card.bar:SetPoint("BOTTOMLEFT", 0, 0)
    card.bar:SetWidth(4)
    card.bar:SetColorTexture(0.7, 0.7, 0.7, 1)

    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.title:SetPoint("TOPLEFT", 14, -8)
    card.title:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    card.title:SetJustifyH("LEFT")

    card.meta = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.meta:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -4)
    card.meta:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    card.meta:SetJustifyH("LEFT")
    card.meta:SetTextColor(0.82, 0.77, 0.68)

    card.score = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.score:SetPoint("TOPRIGHT", -12, -8)
    card.score:SetJustifyH("RIGHT")

    card:SetScript("OnClick", function(button)
        UI:SelectResult(button.result)
    end)

    card:SetScript("OnEnter", function(button)
        if button.result ~= UI.selectedResult then
            ApplyCardBackdrop(button, true)
        end
    end)

    card:SetScript("OnLeave", function(button)
        ApplyCardBackdrop(button, button.result == UI.selectedResult)
    end)

    return card
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
            GameTooltip:AddLine("Click to toggle grinding suggestions.", 1, 1, 1)
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
    local suggestions = GrindLlama:GetSuggestions(level, faction, 5)
    local count = #(_G.GrindLlama_Locations or {})

    self.context:SetText("Level " .. level .. " " .. faction .. " - " .. count .. " routes loaded")
    self.windowText:SetText("Range +/-" .. tostring(GrindLlama.db.levelWindow or 6))
    self:UpdateLockText()

    for index, card in ipairs(self.cards) do
        self:RefreshCard(card, suggestions[index])
    end

    if suggestions[1] and (not self.selectedResult or not self.selectedResult.location) then
        self.selectedResult = suggestions[1]
    end

    if self.selectedResult then
        local stillVisible = false
        for _, result in ipairs(suggestions) do
            if result.location.id == self.selectedResult.location.id then
                self.selectedResult = result
                stillVisible = true
                break
            end
        end
        if not stillVisible then
            self.selectedResult = suggestions[1]
        end
    else
        self.selectedResult = suggestions[1]
    end

    self:RefreshSelection()
    self:ShowDetail(self.selectedResult)
end

function UI:RefreshCard(card, result)
    card.result = result

    if not result then
        card:Hide()
        return
    end

    local location = result.location
    local r, g, b = StatusColor(result)

    card:Show()
    card.bar:SetColorTexture(r, g, b, 1)
    card.title:SetText(location.name)
    if location.priorityScore then
        card.score:SetText(result.status .. " " .. location.priorityScore)
    else
        card.score:SetText(result.status)
    end
    card.score:SetTextColor(r, g, b)
    local cardMeta = LevelText(location) .. " - " .. location.zone
    if location.spawnType then
        cardMeta = cardMeta .. " - " .. location.spawnType
    elseif location.coordinates then
        cardMeta = cardMeta .. " - " .. location.coordinates
    end
    card.meta:SetText(cardMeta)
    ApplyCardBackdrop(card, result == self.selectedResult)
end

function UI:RefreshSelection()
    for _, card in ipairs(self.cards) do
        ApplyCardBackdrop(card, card.result == self.selectedResult)
    end
end

function UI:SelectResult(result)
    if not result then
        return
    end
    self.selectedResult = result
    self:RefreshSelection()
    self:ShowDetail(result)
end

function UI:ShowDetail(result)
    if not result then
        self.detailTitle:SetText("No matching routes loaded")
        self.detailMeta:SetText("Add route rows to Data\\GrindLocations.lua.")
        self.detailStats:SetText("")
        self.detailNotes:SetText("")
        return
    end

    local location = result.location
    local r, g, b = StatusColor(result)
    local metaParts = {}
    local statParts = {}
    local noteParts = {}

    AddText(metaParts, "Mob levels", location.mobLevelRange)
    AddText(metaParts, "Spawn", location.spawnType)
    AddText(metaParts, "Coords", location.coordinates)
    AddText(noteParts, "Mobs", Join(location.mobTypes, "TBD"))
    AddText(noteParts, "Tags", Join(location.tags, ""))
    AddText(noteParts, "Risks", location.risks)

    if location.priorityScore then
        table.insert(statParts, "Priority " .. location.priorityScore)
    end
    table.insert(statParts, StatText("XP", location.xp))
    table.insert(statParts, StatText("Density", location.density))
    table.insert(statParts, StatText("Gold", location.gold))
    table.insert(statParts, StatText("Danger", location.danger))

    self.detailBar:SetColorTexture(r, g, b, 1)
    self.detailTitle:SetText(location.name)
    self.detailTitle:SetTextColor(1.0, 0.88, 0.44)
    self.detailMeta:SetText(LevelText(location) .. " - " .. location.zone .. " / " .. (location.subzone or "Open world") .. " - " .. table.concat(metaParts, " - "))
    self.detailStats:SetText(table.concat(statParts, "   "))
    SetTextColorByQuality(self.detailStats, location.xp)
    self.detailNotes:SetText(table.concat(noteParts, " - ") .. " Route: " .. RouteText(location) .. " " .. (location.notes or ""))
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
        self.lockButton:SetText("Unlock")
    else
        self.lockButton:SetText("Lock")
    end
end
