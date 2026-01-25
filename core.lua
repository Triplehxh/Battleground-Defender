-------------------------------------------------------
-- Battleground Defender v3.7
-- Author: Triplehxh-Blackhand
-- Fully featured with Minimap, Compartment, and Auto-Events
-------------------------------------------------------

local addonName, ns = ...

-- [1] LIBRARIES & MEDIA
local function GetLSM() return LibStub and LibStub("LibSharedMedia-3.0", true) end
local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local iconLib = LibStub and LibStub("LibDBIcon-1.0", true)

local DEFAULT_SOUND_ID = 8959 
local fontList = { ["Default"] = "Fonts\\FRIZQT__.TTF" }

-- [2] LOCALIZATION
local locale = GetLocale()
local L = {
    ["INC"] = "INC", ["HELP"] = "HELP", ["EFC"] = "EFC", ["SAFE"] = "SAFE",
    ["SET_TITLE"] = "BD Settings", ["AUTO_OPEN"] = "Auto Open (BG)", 
    ["LOCK"] = "Lock Frame", ["TEST_MODE"] = "Test Mode (SAY)", 
    ["SMART_CAST"] = "Smart Cast (1-Click)", ["USE_RW"] = "Use RaidWarning (RW)",
    ["ENABLE_SOUND"] = "Enable Sound", ["FORCE_EN"] = "Always English Output",
    ["AUTO_EVENTS"] = "Auto Report Events (Flag/Base)",
    ["SHOW_MINIMAP"] = "Show Minimap Icon",
    ["FONT_SIZE"] = "Font Size", ["BG_ALPHA"] = "BG Transparency", 
    ["BORDER_ALPHA"] = "Border Transparency", ["SPACING"] = "Button Spacing",
    ["FONT_BTN"] = "Font", ["SOUND_BTN"] = "Sound",
    ["INC_MSG"] = "Inc", ["SAFE_MSG"] = "Safe / Clear", ["HELP_MSG"] = "Need Help @", 
    ["EFC_MSG"] = "EFC @", ["DEFAULT"] = "Default"
}

if locale == "deDE" then
    L["SET_TITLE"] = "BD Einstellungen"; L["AUTO_OPEN"] = "Auto Öffnen (BG)"; 
    L["LOCK"] = "Fixieren (Lock)"; L["SMART_CAST"] = "Smart Cast (1-Klick)";
    L["FORCE_EN"] = "Immer Englisch"; L["FONT_SIZE"] = "Größe"; L["BG_ALPHA"] = "Hintergrund";
    L["BORDER_ALPHA"] = "Rand"; L["SAFE_MSG"] = "Sicher / Frei"; 
    L["HELP_MSG"] = "Hilfe benötigt @"; L["DEFAULT"] = "Standard";
    L["TEST_MODE"] = "Test Modus (SAY)"; L["ENABLE_SOUND"] = "Ton einschalten";
    L["AUTO_EVENTS"] = "Auto-Meldung (Flagge/Basis)";
    L["SHOW_MINIMAP"] = "Minimap Icon anzeigen"
end

local mapTrans = {
    ["Sägewerk"] = "Lumber Mill", ["Schmiede"] = "Blacksmith", ["Ställe"] = "Stables", ["Goldmine"] = "Gold Mine", ["Hof"] = "Farm",
    ["Wasserwerk"] = "Waterworks", ["Leuchtturm"] = "Lighthouse", ["Minen"] = "Mines", ["Ruinen"] = "Ruins", ["Schrein"] = "Shrine",
    ["Steinbruch"] = "Quarry", ["Marktplatz"] = "Market", ["Friedhof"] = "Graveyard", ["Festung"] = "Keep"
}

-- [3] DEFAULTS
local defaults = {
    fontSize = 12, fontName = "Default", soundName = "Default",
    soundEnabled = true, autoShow = true, locked = true, 
    isTestMode = false, forceEnglish = true, smartCast = true, useRW = true,
    autoEvents = true,
    minimap = { hide = false },
    bgAlpha = 0, borderAlpha = 0, buttonSpacing = 0,
    posINC = "BOTTOM", posHELP = "BOTTOM", posEFC = "BOTTOM", posSAFE = "BOTTOM",
    point = "CENTER", relativePoint = "CENTER", xOfs = 0, yOfs = 0
}

local actionButtons, numButtons, lastMsgTime = {}, {}, 0
local currentCount = "1"

-- [4] MAIN INTERFACE (Responsive Elastic Frame)
local frame = CreateFrame("Frame", "BattlegroundDefenderFrame", UIParent, "BackdropTemplate")
frame:SetSize(1, 1); frame:SetPoint("CENTER"); frame:EnableMouse(true); frame:SetMovable(true); 
frame:SetResizable(true); frame:SetClampedToScreen(true); frame:Hide(); frame:SetUserPlaced(true)

frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) if BattlegroundDefenderDB and not BattlegroundDefenderDB.locked then self:StartMoving() end end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if BattlegroundDefenderDB then
        local p, _, rp, x, y = self:GetPoint()
        BattlegroundDefenderDB.point, BattlegroundDefenderDB.relativePoint, BattlegroundDefenderDB.xOfs, BattlegroundDefenderDB.yOfs = p, rp, x, y
    end
end)

frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { 4, 4, 4, 4 } })

local coreGroup = CreateFrame("Frame", nil, frame)
local containers = { TOP = CreateFrame("Frame", nil, frame), BOTTOM = CreateFrame("Frame", nil, frame), LEFT = CreateFrame("Frame", nil, frame), RIGHT = CreateFrame("Frame", nil, frame) }

local resizeBtn = CreateFrame("Button", nil, frame)
resizeBtn:SetSize(20, 20); resizeBtn:SetPoint("BOTTOMRIGHT")
resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeBtn:SetScript("OnMouseDown", function() if not BattlegroundDefenderDB.locked then frame:StartSizing("BOTTOMRIGHT") end end)
resizeBtn:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); ns.UpdateLayout() end)

-- [5] LAYOUT ENGINE
ns.UpdateLayout = function()
    local db = BattlegroundDefenderDB; if not db then return end
    frame:SetBackdropColor(0, 0, 0, db.bgAlpha); frame:SetBackdropBorderColor(1, 1, 1, db.borderAlpha)
    if db.locked then resizeBtn:Hide() else resizeBtn:Show() end

    local LSM = GetLSM()
    local fontPath = (LSM and LSM:Fetch("font", db.fontName)) or fontList["Default"]
    local pad = db.buttonSpacing or 0

    -- Numbers Core
    local tw, th = 0, 0
    for i, btn in ipairs(numButtons) do
        local fs = btn:GetFontString(); if fs then fs:SetFont(fontPath, db.fontSize, "OUTLINE") end
        btn:SetSize((fs and fs:GetStringWidth() or 20) + 20, db.fontSize + 12)
        btn:ClearAllPoints()
        if i == 1 then btn:SetPoint("LEFT", coreGroup, "LEFT", 0, 0) else btn:SetPoint("LEFT", numButtons[i-1], "RIGHT", pad, 0) end
        tw = tw + btn:GetWidth() + (i > 1 and pad or 0); th = btn:GetHeight()
        local nt = btn:GetNormalTexture(); if nt then nt:SetVertexColor(1, 1, 0.6) end
    end
    coreGroup:SetSize(tw, th); coreGroup:SetPoint("CENTER", frame, "CENTER", 0, 0)

    -- Actions Snap
    local keys = {"INC", "HELP", "EFC", "SAFE"}
    local sideGroups = { TOP = {}, BOTTOM = {}, LEFT = {}, RIGHT = {} }
    for _, key in ipairs(keys) do
        local btn = actionButtons[key]
        if btn then table.insert(sideGroups[db["pos"..key] or "BOTTOM"], btn) end
    end

    local minX, maxX, minY, maxY = coreGroup:GetLeft(), coreGroup:GetRight(), coreGroup:GetBottom(), coreGroup:GetTop()
    for side, btns in pairs(sideGroups) do
        local c = containers[side]; c:ClearAllPoints()
        if side == "TOP" then c:SetPoint("BOTTOM", coreGroup, "TOP", 0, pad)
        elseif side == "BOTTOM" then c:SetPoint("TOP", coreGroup, "BOTTOM", 0, -pad)
        elseif side == "LEFT" then c:SetPoint("RIGHT", coreGroup, "LEFT", -pad, 0)
        else c:SetPoint("LEFT", coreGroup, "RIGHT", pad, 0) end
        local cw, ch = 0, 0
        for i, btn in ipairs(btns) do
            local fs = btn:GetFontString(); if fs then fs:SetFont(fontPath, db.fontSize, "OUTLINE") end
            btn:SetSize((fs and fs:GetStringWidth() or 40) + 24, db.fontSize + 14)
            btn:ClearAllPoints()
            if side == "TOP" or side == "BOTTOM" then
                if i == 1 then btn:SetPoint("LEFT", c, "LEFT", 0, 0) else btn:SetPoint("LEFT", btns[i-1], "RIGHT", pad, 0) end
                cw = cw + btn:GetWidth() + (i > 1 and pad or 0); ch = btn:GetHeight()
            else
                if i == 1 then btn:SetPoint("TOP", c, "TOP", 0, 0) else btn:SetPoint("TOP", btns[i-1], "BOTTOM", -pad, 0) end
                ch = ch + btn:GetHeight() + (i > 1 and pad or 0); cw = btn:GetWidth()
            end
        end
        c:SetSize(cw, ch)
        if #btns > 0 and c:GetLeft() then
            minX = math.min(minX or 9999, c:GetLeft()); maxX = math.max(maxX or 0, c:GetRight())
            minY = math.min(minY or 9999, c:GetBottom()); maxY = math.max(maxY or 0, c:GetTop())
        end
    end
    if minX and maxX and minY and maxY then frame:SetSize((maxX - minX) + 20, (maxY - minY) + 24) end

    -- Minimap Toggle
    if iconLib then
        if db.minimap.hide then iconLib:Hide(addonName) else iconLib:Show(addonName) end
    end
end

-- [6] COMPARTMENT & MINIMAP LOGIC
function BattlegroundDefender_OnCompartmentClick()
    if BDConfigFrame:IsShown() then BDConfigFrame:Hide() else BDConfigFrame:Show() end
end

local function RegisterMinimap()
    if not LDB or not iconLib then return end
    local BD_LDB = LDB:NewDataObject(addonName, {
        type = "launcher",
        text = "Battleground Defender",
        icon = "Interface\\AddOns\\BattlegroundDefender\\icon",
        OnClick = function(_, button)
            if button == "RightButton" then 
                BattlegroundDefender_OnCompartmentClick()
            else
                if frame:IsShown() then frame:Hide() else frame:Show() end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cff00ffffBattleground Defender|r")
            tooltip:AddLine("|cffaaaaaaLeft-Click:|r Toggle Interface")
            tooltip:AddLine("|cffaaaaaaRight-Click:|r Open Settings")
        end,
    })
    iconLib:Register(addonName, BD_LDB, BattlegroundDefenderDB.minimap)
end

-- [7] AUDIO & REPORTING
local function PlayAlertSound()
    local db = BattlegroundDefenderDB; if not db.soundEnabled then return end
    if db.soundName == "Default" then PlaySound(DEFAULT_SOUND_ID, "Master")
    else local LSM = GetLSM(); local p = LSM and LSM:Fetch("sound", db.soundName); if p then PlaySoundFile(p, "Master") else PlaySound(DEFAULT_SOUND_ID, "Master") end end
end

local function SendMsg(msg)
    local db = BattlegroundDefenderDB
    if db.isTestMode then SendChatMessage("[TEST] " .. msg, "SAY") else 
        local c = (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT") or (IsInRaid() and "RAID") or "PARTY"
        if c == "INSTANCE_CHAT" and db.useRW and IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then c = "RAID_WARNING" end
        SendChatMessage(msg, c)
    end
end

local function SendReport(rawLoc, prefix)
    if GetTime() - lastMsgTime < 1 then return end
    lastMsgTime = GetTime(); PlayAlertSound()
    local db = BattlegroundDefenderDB
    local loc = db.forceEnglish and (mapTrans[rawLoc] or rawLoc) or rawLoc
    local fPrefix = prefix or currentCount
    local incW = db.forceEnglish and "Inc" or L["INC_MSG"]
    if prefix == L["SAFE_MSG"] then fPrefix = db.forceEnglish and "Safe" or L["SAFE_MSG"]; incW = "" end
    if prefix == L["HELP_MSG"] then fPrefix = db.forceEnglish and "Need Help @" or L["HELP_MSG"]; incW = "" end
    if prefix == L["EFC_MSG"] then fPrefix = db.forceEnglish and "EFC @" or L["EFC_MSG"]; incW = "" end
    SendMsg(fPrefix .. " " .. incW .. " " .. loc)
end

-- [8] AUTO EVENTS
local function OnBGMessage(msg)
    if not BattlegroundDefenderDB or not BattlegroundDefenderDB.autoEvents then return end
    local pName = UnitName("player")
    if msg:find(pName) then
        if msg:find("picked up") or msg:find("aufgehoben") then SendMsg(">>> I HAVE THE FLAG / ORB! <<<")
        elseif msg:find("captured") or msg:find("eingenommen") then SendMsg(">>> Base Captured by me! <<<")
        elseif msg:find("defended") or msg:find("verteidigt") then SendMsg(">>> Base Defended by me! <<<")
        elseif msg:find("dropped") or msg:find("fallen gelassen") then SendMsg(">>> I DROPPED THE FLAG! <<<") end
    end
end

-- [9] BUTTON FACTORY
local function CreateActionBtn(key, text, color, parent, func)
    local btn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    btn:SetText(text); btn:SetMovable(true); btn:RegisterForDrag("LeftButton")
    local r, g, b = 1, 1, 1
    if color == "red" then r,g,b = 1,0.5,0.5 elseif color == "green" then r,g,b = 0.5,1,0.5 elseif color == "blue" then r,g,b = 0.6,0.8,1 elseif color == "yellow" then r,g,b = 1,1,0.6 elseif color == "orange" then r,g,b = 1,0.7,0.2 end
    btn:SetScript("OnUpdate", function(self) local t = self:GetNormalTexture(); if t then t:SetVertexColor(r, g, b) end end)
    btn:SetScript("OnDragStart", function(self) if not BattlegroundDefenderDB.locked then self:StartMoving() end end)
    btn:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing(); local cx, cy = self:GetCenter(); local fx, fy = coreGroup:GetCenter()
        if cx and fx then BattlegroundDefenderDB["pos"..key] = (math.abs(cx - fx) > math.abs(cy - fy)) and (((cx - fx) > 0) and "RIGHT" or "LEFT") or (((cy - fy) > 0) and "TOP" or "BOTTOM") end
        ns.UpdateLayout()
    end)
    btn:SetScript("OnClick", func); actionButtons[key] = btn; return btn
end

for i = 1, 4 do 
    local btn = CreateFrame("Button", nil, coreGroup, "GameMenuButtonTemplate")
    btn:SetText(tostring(i)); btn:SetScript("OnClick", function() currentCount = tostring(i); if BattlegroundDefenderDB.smartCast then SendReport(GetSubZoneText()~="" and GetSubZoneText() or GetZoneText()) end end)
    table.insert(numButtons, btn)
end
local btn5 = CreateFrame("Button", nil, coreGroup, "GameMenuButtonTemplate")
btn5:SetText("5+"); btn5:SetScript("OnClick", function() currentCount = "5+"; if BattlegroundDefenderDB.smartCast then SendReport(GetSubZoneText()~="" and GetSubZoneText() or GetZoneText()) end end)
table.insert(numButtons, btn5)

CreateActionBtn("INC", L["INC"], "red", containers.BOTTOM, function() SendReport(GetSubZoneText()~="" and GetSubZoneText() or GetZoneText()) end)
CreateActionBtn("HELP", L["HELP"], "blue", containers.BOTTOM, function() SendReport(GetSubZoneText()~="" and GetSubZoneText() or GetZoneText(), L["HELP_MSG"]) end)
CreateActionBtn("EFC", L["EFC"], "orange", containers.BOTTOM, function() SendReport(GetSubZoneText()~="" and GetSubZoneText() or GetZoneText(), L["EFC_MSG"]) end)
CreateActionBtn("SAFE", L["SAFE"], "green", containers.BOTTOM, function() SendReport(GetSubZoneText()~="" and GetSubZoneText() or GetZoneText(), L["SAFE_MSG"]) end)

-- [10] SETTINGS UI
local cfg = CreateFrame("Frame", "BDConfigFrame", UIParent, "BackdropTemplate")
cfg:SetSize(280, 600); cfg:SetPoint("CENTER"); cfg:SetFrameStrata("DIALOG"); cfg:Hide(); cfg:SetMovable(true); cfg:EnableMouse(true)
cfg:RegisterForDrag("LeftButton"); cfg:SetScript("OnDragStart", cfg.StartMoving); cfg:SetScript("OnDragStop", cfg.StopMovingOrSizing); table.insert(UISpecialFrames, "BDConfigFrame")
cfg:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { 4, 4, 4, 4 } })
CreateFrame("Button", nil, cfg, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -5, -5)

local function CreateCheck(text, dbKey, y)
    local cb = CreateFrame("CheckButton", nil, cfg, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 10, y); cb.Text:SetText(text)
    cb:SetScript("OnShow", function(self) 
        if BattlegroundDefenderDB then 
            if dbKey == "minimap_show" then self:SetChecked(not BattlegroundDefenderDB.minimap.hide)
            else self:SetChecked(BattlegroundDefenderDB[dbKey]) end
        end 
    end)
    cb:SetScript("OnClick", function(self) 
        if dbKey == "minimap_show" then BattlegroundDefenderDB.minimap.hide = not self:GetChecked()
        else BattlegroundDefenderDB[dbKey] = self:GetChecked() end
        ns.UpdateLayout() 
    end)
end

CreateCheck(L["AUTO_OPEN"], "autoShow", -35); CreateCheck(L["LOCK"], "locked", -60)
CreateCheck(L["TEST_MODE"], "isTestMode", -85); CreateCheck(L["FORCE_EN"], "forceEnglish", -110)
CreateCheck(L["AUTO_EVENTS"], "autoEvents", -135); CreateCheck(L["ENABLE_SOUND"], "soundEnabled", -160)
CreateCheck(L["SHOW_MINIMAP"], "minimap_show", -185)

local function CreateSlider(text, dbKey, min, max, step, y)
    local s = CreateFrame("Slider", addonName..dbKey, cfg, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 20, y); s:SetWidth(240); s:SetMinMaxValues(min, max); s:SetValueStep(step); _G[s:GetName().."Text"]:SetText(text)
    s:SetScript("OnShow", function(self) if BattlegroundDefenderDB then self:SetValue(BattlegroundDefenderDB[dbKey]) end end)
    s:SetScript("OnValueChanged", function(self, v) if BattlegroundDefenderDB then BattlegroundDefenderDB[dbKey] = v; ns.UpdateLayout() end end)
end
CreateSlider(L["FONT_SIZE"], "fontSize", 8, 32, 1, -235); CreateSlider(L["BG_ALPHA"], "bgAlpha", 0, 1, 0.1, -285); CreateSlider(L["BORDER_ALPHA"], "borderAlpha", 0, 1, 0.1, -335); CreateSlider(L["SPACING"], "buttonSpacing", 0, 30, 1, -385)

local selFrame = CreateFrame("Frame", "BDSelectionFrame", UIParent, "BackdropTemplate")
selFrame:SetSize(350, 400); selFrame:SetPoint("CENTER"); selFrame:SetFrameStrata("TOOLTIP"); selFrame:Hide()
selFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { 4, 4, 4, 4 } })
local scroll = CreateFrame("ScrollFrame", "BDScrollFrame", selFrame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 10, -35); scroll:SetPoint("BOTTOMRIGHT", -30, 10)
local scrollChild = CreateFrame("Frame"); scroll:SetScrollChild(scrollChild); scrollChild:SetSize(310, 1)
CreateFrame("Button", nil, selFrame, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -5, -5)

local function OpenSelection(mType, cb)
    selFrame:Show(); local list = {"Default"}
    local LSM = GetLSM()
    if LSM then local lsmL = LSM:List(mType); if lsmL then for _, n in ipairs(lsmL) do if n ~= "Default" then table.insert(list, n) end end end end
    for _, c in ipairs({scrollChild:GetChildren()}) do if c:IsObjectType("Button") then c:Hide() end end
    local y = 0
    for i, n in ipairs(list) do
        local b = _G["BDSelBtn"..i] or CreateFrame("Button", "BDSelBtn"..i, scrollChild, "UIPanelButtonTemplate")
        b:SetSize(300, 20); b:SetPoint("TOPLEFT", 0, y); b:SetText(n); b:Show()
        b:SetScript("OnClick", function() 
            cb(n); if mType == "sound" then if n == "Default" then PlaySound(DEFAULT_SOUND_ID, "Master") else local p = LSM:Fetch("sound", n); if p then PlaySoundFile(p, "Master") end end end
            ns.UpdateLayout(); selFrame:Hide() 
        end); y = y - 22
    end
    scrollChild:SetHeight(math.abs(y) + 20)
end

local fBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate"); fBtn:SetSize(200, 25); fBtn:SetPoint("TOP", 0, -435)
local sBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate"); sBtn:SetSize(200, 25); sBtn:SetPoint("TOP", 0, -470)
fBtn:SetScript("OnClick", function() OpenSelection("font", function(v) BattlegroundDefenderDB.fontName = v end) end)
sBtn:SetScript("OnClick", function() OpenSelection("sound", function(v) BattlegroundDefenderDB.soundName = v end) end)
cfg:SetScript("OnUpdate", function() if BattlegroundDefenderDB then fBtn:SetText(L["FONT_BTN"]..": "..BattlegroundDefenderDB.fontName); sBtn:SetText(L["SOUND_BTN"]..": "..BattlegroundDefenderDB.soundName) end end)

local optBtn = CreateFrame("Button", nil, frame); optBtn:SetSize(20, 20); optBtn:SetPoint("TOPRIGHT", -5, -5); optBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
optBtn:SetScript("OnClick", function() if cfg:IsShown() then cfg:Hide() else cfg:Show(); cfg:SetPoint("CENTER") end end)

-- [11] SLASH & INIT
local function ShowHelp()
    print("|cff00ffffBattleground Defender Help:|r")
    print(" /bd help - Shows this command list")
    print(" /bd open - Toggles the main interface")
    print(" /bd reset - Resets all settings to default")
end

SLASH_BATTLEGROUNDDEFENDER1 = "/bd"; SlashCmdList["BATTLEGROUNDDEFENDER"] = function(msg)
    local cmd = msg:lower():trim()
    if cmd == "reset" then BattlegroundDefenderDB = nil; ReloadUI()
    elseif cmd == "open" then if frame:IsShown() then frame:Hide() else frame:Show() end
    elseif cmd == "help" or cmd == "" then ShowHelp() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN"); ev:RegisterEvent("ZONE_CHANGED_NEW_AREA"); ev:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL"); ev:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE"); ev:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
ev:SetScript("OnEvent", function(self, event, msg)
    if event == "PLAYER_LOGIN" then
        BattlegroundDefenderDB = BattlegroundDefenderDB or CopyTable(defaults)
        for k, v in pairs(defaults) do if BattlegroundDefenderDB[k] == nil then BattlegroundDefenderDB[k] = v end end
        if BattlegroundDefenderDB.point then frame:ClearAllPoints(); frame:SetPoint(BattlegroundDefenderDB.point, UIParent, BattlegroundDefenderDB.relativePoint or "CENTER", BattlegroundDefenderDB.xOfs, BattlegroundDefenderDB.yOfs) end
        RegisterMinimap()
        ns.UpdateLayout()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        local _, t = IsInInstance(); if BattlegroundDefenderDB and BattlegroundDefenderDB.autoShow then if t == "pvp" then frame:Show() else frame:Hide() end end
    elseif event:find("CHAT_MSG_BG_SYSTEM") then OnBGMessage(msg) end
end)