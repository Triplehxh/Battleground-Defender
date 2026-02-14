-------------------------------------------------------
-- Battleground Defender v8.0 (Reforged) - SAFE VERSION
-- Author: Triplehxh-Blackhand
-- UPDATED: Safe Button Send / Raid/Say logic
-------------------------------------------------------

local addonName, ns = ...

-- [1] LIBRARIES
local function GetLSM() 
    if not LibStub then return nil end
    return LibStub("LibSharedMedia-3.0", true) 
end

local DEFAULT_SOUND_ID = 8959 
local fontList = { ["Default"] = "Fonts\\FRIZQT__.TTF" }

-- [2] LOCALIZATION & TRANSLATION
local locale = GetLocale()
local L = {
    ["INC"] = "INC", ["HELP"] = "HELP", ["EFC"] = "EFC", ["SAFE"] = "SAFE",
    ["SET_TITLE"] = "BD Settings", ["AUTO_OPEN"] = "Auto Open (BG)", 
    ["LOCK"] = "Lock Frame", ["TEST_MODE"] = "Test Mode", 
    ["SMART_CAST"] = "Smart Cast (1-Click)", ["USE_RW"] = "Use RaidWarning (RW)",
    ["ENABLE_SOUND"] = "Enable Sound", ["FORCE_EN"] = "Always English Output",
    ["AUTO_EVENTS"] = "Auto Events",
    ["SHOW_MINIMAP"] = "Show Minimap Icon",
    ["FONT_SIZE"] = "Font Size", ["BG_ALPHA"] = "BG Transparency", 
    ["BORDER_ALPHA"] = "Border Transparency", ["SPACING"] = "Button Spacing",
    ["FONT_BTN"] = "Font", ["SOUND_BTN"] = "Sound",
    ["INC_MSG"] = "Inc", ["SAFE_MSG"] = "Safe / Clear", ["HELP_MSG"] = "Need Help @", 
    ["EFC_MSG"] = "EFC @", ["DEFAULT"] = "Default"
}

if locale == "deDE" then
    L["SET_TITLE"] = "BD Einstellungen"; L["AUTO_OPEN"] = "Auto Öffnen (BG)"; 
    L["LOCK"] = "Fixieren"; L["SMART_CAST"] = "Smart Cast (1-Klick)";
    L["USE_RW"] = "Nutze RaidWarning (RW)"; L["FORCE_EN"] = "Immer Englisch";
    L["SAFE_MSG"] = "Sicher / Frei"; L["HELP_MSG"] = "Hilfe benötigt @";
    L["TEST_MODE"] = "Test Modus"; L["ENABLE_SOUND"] = "Ton an";
    L["AUTO_EVENTS"] = "Auto-Meldung"; L["SHOW_MINIMAP"] = "Minimap Icon"
end

-- PRIORITY TRANSLATION (Fixed Order)
local replacements = {
    { "Friedhof der Sturmlanzen", "Stormpike Graveyard" },
    { "Friedhof der Frostwölfe", "Frostwolf Graveyard" },
    { "Sturmlanzen", "Stormpike" },
    { "Frostwölfe", "Frostwolf" },
    { "Friedhof", "Graveyard" }, 
    { "friedhof", "Graveyard" },
    { "Festung", "Keep" },
    { "Sägewerk", "Lumber Mill" }, { "Schmiede", "Blacksmith" }, { "Ställe", "Stables" }, { "Goldmine", "Gold Mine" }, { "Hof", "Farm" },
    { "Wasserwerk", "Waterworks" }, { "Leuchtturm", "Lighthouse" }, { "Minen", "Mines" }, { "Ruinen", "Ruins" }, { "Schrein", "Shrine" },
    { "Steinbruch", "Quarry" }, { "Marktplatz", "Market" },
    { "Turm", "Tower" }, { "turm", "Tower" },
    { "Bunker", "Bunker" }, { "bunker", "Bunker" },
    { "Hütte", "Hut" }, { "Bau", "Den" },
    { "Eisschwingen", "Icewing" }, { "Steinbruch", "Stonehearth" }, { "Eisblut", "Iceblood" }, 
    { "Frostwolf", "Frostwolf" }, { "Dun Baldar", "Dun Baldar" }, { "Verbandsplatz", "Aid Station" },
    { "Sanitäter", "Relief Hut" },
    { "Die Tiefenwindschlucht", "Deepwind Gorge" }, { "Tiefenwindschlucht", "Deepwind Gorge" }
}

local function BD_RefreshButtonMacro(btn, msg)

    local slash

    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        slash = "/i"

    elseif IsInRaid() then

        if BattlegroundDefenderDB.useRW
        and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then

            slash = "/rw"
        else
            slash = "/raid"
        end

    elseif IsInGroup() then
        slash = "/party"

    else
        slash = "/say"
    end

    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", slash .. " " .. msg)

end
-- [3] DEFAULTS
local defaults = {
    fontSize = 12, fontName = "Default", soundName = "Default",
    soundEnabled = true, autoShow = true, locked = true, 
    isTestMode = true, forceEnglish = true, smartCast = true, useRW = true,
    autoEvents = true, 
    minimapPos = 45, minimapHide = false, 
    bgAlpha = 0.5, borderAlpha = 1, buttonSpacing = 2,
    posINC = "BOTTOM", posHELP = "BOTTOM", posEFC = "BOTTOM", posSAFE = "BOTTOM",
    point = "CENTER", relativePoint = "CENTER", xOfs = 0, yOfs = 0
}

local actionButtons, numButtons = {}, {}
local currentCount = "1"

-- [4] LOGIC ENGINE (FIXED SAFE CHAT SENDING)
-- [4] LOGIC ENGINE (SAFE COMBAT-FRIENDLY)
local function GetSendChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    else
        return "SAY"
    end
end

-- Gepufferte letzte Positionsbeschreibung (Subzone / Minimap-Text)
local BD_LastLocText = "Unknown"

local function BD_UpdateLocation()
    local rawLoc = GetMinimapZoneText() or GetZoneText() or "Unknown"
    local loc = rawLoc

    if BattlegroundDefenderDB and BattlegroundDefenderDB.forceEnglish then
        for _, pair in ipairs(replacements) do
            local de, en = pair[1], pair[2]
            if loc:find(de) then
                loc = loc:gsub(de, en)
                if #de > 4 then break end
            end
        end
    end

    BD_LastLocText = loc
end

local function BuildMessage(cmdType, cmdValue)
    if not BattlegroundDefenderDB then return "" end
    local db = BattlegroundDefenderDB
        -- Verwende gepufferte letzte Position; Fallback falls noch nie gesetzt
    local loc = BD_LastLocText or GetMinimapZoneText() or GetZoneText() or "Unknown"


    if cmdType == "NUM" then
        if not db.smartCast then return "" end
        local val = (cmdValue == "5") and "5+" or cmdValue
        return val .. " " .. (db.forceEnglish and "Inc" or L["INC_MSG"]) .. " " .. loc
    elseif cmdType == "INC" then
        return currentCount .. " " .. (db.forceEnglish and "Inc" or L["INC_MSG"]) .. " " .. loc
    elseif cmdType == "SAFE" then
        return (db.forceEnglish and "Safe / Clear" or L["SAFE_MSG"]) .. " " .. loc
    elseif cmdType == "HELP" then
        return (db.forceEnglish and "Need Help @" or L["HELP_MSG"]) .. " " .. loc
    elseif cmdType == "EFC" then
        return (db.forceEnglish and "EFC @" or L["EFC_MSG"]) .. " " .. loc
    end
    return ""
end

local function ExecuteBDLogic(cmdType, cmdValue)
    -- ALLES auf statische Makros → diese Funktion wird nie mehr aufgerufen!
    print("|cff00ff00[BD]|r ExecuteBDLogic deprecated - use buttons!")
    return
end

-- Slash Command (NICHT MEHR BENUTZEN - verursacht ADDON_ACTION_FORBIDDEN)
--[[
SLASH_BDRUN1 = "/bd_run"
SlashCmdList["BDRUN"] = function(msg) ... end
--]]

-- [5] MAIN INTERFACE
local frame = CreateFrame("Frame", "BattlegroundDefenderFrame", UIParent, "BackdropTemplate")
frame:SetSize(1, 1); frame:SetPoint("CENTER"); frame:EnableMouse(true); frame:SetMovable(true); 
frame:SetResizable(true); frame:SetClampedToScreen(true); frame:Hide(); frame:SetUserPlaced(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) if BattlegroundDefenderDB and not BattlegroundDefenderDB.locked and not InCombatLockdown() then self:StartMoving() end end)
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

-- [6] LAYOUT & ATTRIBUTES
-- We no longer update attributes in a loop because they are static now!
ns.UpdateLayout = function()
    if InCombatLockdown() then return end
    local db = BattlegroundDefenderDB; if not db then return end
    
    print("BD: UpdateLayout läuft, DB:", db and "OK" or "NULL")
    print("BD: BD_LastLocText =", BD_LastLocText)
    
    frame:SetBackdropColor(0, 0, 0, db.bgAlpha)
    frame:SetBackdropBorderColor(1, 1, 1, db.borderAlpha)
    local LSM = GetLSM()
    local fontPath = (LSM and LSM:Fetch("font", db.fontName)) or fontList["Default"]
    local pad = db.buttonSpacing or 0
    local tw, th = 0, 0
    
    -- NUM Buttons (1-5+)
    for i, btn in ipairs(numButtons) do
        local fs = btn:GetFontString()
        if fs then fs:SetFont(fontPath, db.fontSize, "OUTLINE") end
        btn:SetSize((fs and fs:GetStringWidth() or 20) + 20, db.fontSize + 12)
        btn:ClearAllPoints()
        if i == 1 then 
            btn:SetPoint("LEFT", coreGroup, "LEFT", 0, 0) 
        else 
            btn:SetPoint("LEFT", numButtons[i-1], "RIGHT", pad, 0) 
        end
        tw = tw + btn:GetWidth() + (i > 1 and pad or 0)
        th = btn:GetHeight()
        
        -- NUM Macro setzen
        local val = (i == 5) and "5+" or tostring(i)
        local msg = val .. " Inc " .. BD_LastLocText

        print("BD: NUM", val, "Macro:", "/i " .. msg)
    end
    coreGroup:SetSize(tw, th)
    coreGroup:SetPoint("CENTER", frame, "CENTER", 0, 0)
    
    -- Action Buttons
    local keys = {"INC", "HELP", "EFC", "SAFE"}
    local sideGroups = { TOP = {}, BOTTOM = {}, LEFT = {}, RIGHT = {} }
    
    for _, key in ipairs(keys) do
        local btn = actionButtons[key]
        if btn then
            table.insert(sideGroups[db["pos"..key] or "BOTTOM"], btn)
            
            local fs = btn:GetFontString()
            if fs then fs:SetFont(fontPath, db.fontSize, "OUTLINE") end
            btn:SetSize((fs and fs:GetStringWidth() or 40) + 24, db.fontSize + 14)
            
            -- Action Macro setzen
            local msg = ""
            if key == "INC" then 
                msg = currentCount .. " Inc " .. BD_LastLocText
            elseif key == "SAFE" then 
                msg = "Safe " .. BD_LastLocText
            elseif key == "HELP" then 
                msg = "Help @" .. BD_LastLocText
            elseif key == "EFC" then 
                msg = "EFC @" .. BD_LastLocText 
            end

            print("BD: " .. key .. " Macro:", "/i " .. msg)
        end
    end
    
    -- Container Layout (Buttons positionieren)
    local minX, maxX, minY, maxY = coreGroup:GetLeft(), coreGroup:GetRight(), coreGroup:GetBottom(), coreGroup:GetTop()
    for side, btns in pairs(sideGroups) do
        local c = containers[side]
        c:ClearAllPoints()
        if side == "TOP" then 
            c:SetPoint("BOTTOM", coreGroup, "TOP", 0, pad)
        elseif side == "BOTTOM" then 
            c:SetPoint("TOP", coreGroup, "BOTTOM", 0, -pad)
        elseif side == "LEFT" then 
            c:SetPoint("RIGHT", coreGroup, "LEFT", -pad, 0)
        else 
            c:SetPoint("LEFT", coreGroup, "RIGHT", pad, 0) 
        end
        
        local cw, ch = 0, 0
        for i, btn in ipairs(btns) do
            btn:ClearAllPoints()
            if side == "TOP" or side == "BOTTOM" then
                if i == 1 then 
                    btn:SetPoint("LEFT", c, "LEFT", 0, 0) 
                else 
                    btn:SetPoint("LEFT", btns[i-1], "RIGHT", pad, 0) 
                end
                cw = cw + btn:GetWidth() + (i > 1 and pad or 0)
                ch = btn:GetHeight()
            else
                if i == 1 then 
                    btn:SetPoint("TOP", c, "TOP", 0, 0) 
                else 
                    btn:SetPoint("TOP", btns[i-1], "BOTTOM", -pad, 0) 
                end
                ch = ch + btn:GetHeight() + (i > 1 and pad or 0)
                cw = btn:GetWidth()
            end
        end
        c:SetSize(cw or 1, ch or 1)
        if #btns > 0 then
            minX = math.min(minX or 9999, c:GetLeft())
            maxX = math.max(maxX or 0, c:GetRight())
            minY = math.min(minY or 9999, c:GetBottom())
            maxY = math.max(maxY or 0, c:GetTop())
        end
    end
    if minX and maxX and minY and maxY then 
        frame:SetSize((maxX - minX) + 20, (maxY - minY) + 24) 
    end
end

local function CreateSecureButton(name, parent, text, prefix)

    local btn = CreateFrame(
        "Button",
        name,
        parent,
        "SecureActionButtonTemplate"
    )

    btn:SetSize(80, 25)

    ------------------------------------------------
    -- Visual Style (separate, safe)
    ------------------------------------------------
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetHighlightFontObject("GameFontHighlight")
    btn:SetText(text)

    ------------------------------------------------
    -- CRITICAL FIX
    ------------------------------------------------
    btn:RegisterForClicks("AnyUp", "AnyDown")

    ------------------------------------------------
    -- PreClick builds macro
    ------------------------------------------------
	btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetScript("PreClick", function(self)

        local location = GetSubZoneText()

        if location == "" then
            location = GetZoneText()
        end

        local message = BuildMessage(prefix, location)

        local slash = GetChatSlashCommand()

        if slash then

            local macro = slash .. " " .. message

            self:SetAttribute("type", "macro")
            self:SetAttribute("macrotext", macro)

            print("|cff00ff00BD: Executing macro:|r", macro)

        else

            print("|cffff0000BD: No group channel available.|r")

        end

    end)

    return btn

end


-- [7] SECURE BUTTON FACTORY
local function CreateActionBtn(key, text, color, parent, isNum)
    local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate, UIPanelButtonTemplate")
    btn:SetText(text)
    btn:RegisterForClicks("AnyUp")
    
    local r, g, b = 1,1,1
    if color=="red" then r,g,b=1,0.5,0.5 elseif color=="green" then r,g,b=0.5,1,0.5 elseif color=="blue" then r,g,b=0.6,0.8,1 elseif color=="yellow" then r,g,b=1,1,0.6 elseif color=="orange" then r,g,b=1,0.7,0.2 end
    local fs = btn:GetFontString()
if fs then fs:SetTextColor(r,g,b) end

    -- Sound nur (KEIN SendChatMessage!)
	btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetScript("PreClick", function(self)

    local msg = ""

    if isNum then

        currentCount = text   -- ✅ FIX: update count
        msg = text .. " Inc " .. BD_LastLocText

    else

        if key == "INC" then
            msg = currentCount .. " Inc " .. BD_LastLocText

        elseif key == "SAFE" then
            msg = "Safe " .. BD_LastLocText

        elseif key == "HELP" then
            msg = "Help @" .. BD_LastLocText

        elseif key == "EFC" then
            msg = "EFC @" .. BD_LastLocText
        end

    end

    BD_RefreshButtonMacro(self, msg)

end)



    if isNum then table.insert(numButtons,btn) else actionButtons[key]=btn end
    return btn
end


-- Zahlen-Buttons 1–5+
for i = 1, 4 do CreateActionBtn("N"..i, tostring(i), "yellow", coreGroup, true) end
CreateActionBtn("N5", "5+", "yellow", coreGroup, true)

-- Action-Buttons INC, HELP, EFC, SAFE
CreateActionBtn("INC", L["INC"], "red", containers.BOTTOM)
CreateActionBtn("HELP", L["HELP"], "blue", containers.BOTTOM)
CreateActionBtn("EFC", L["EFC"], "orange", containers.BOTTOM)
CreateActionBtn("SAFE", L["SAFE"], "green", containers.BOTTOM)

-- [8] NATIVE MINIMAP BUTTON
local mini = CreateFrame("Button", "BD_NativeMinimapButton", Minimap)
mini:SetSize(32, 32)
mini:SetFrameLevel(9) 
mini:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local mIcon = mini:CreateTexture(nil, "BACKGROUND")
mIcon:SetTexture("Interface\\AddOns\\BattlegroundDefender\\icon")
mIcon:SetSize(20, 20)
mIcon:SetPoint("CENTER", 0, 0)
local mBorder = mini:CreateTexture(nil, "OVERLAY")
mBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mBorder:SetSize(52, 52)
mBorder:SetPoint("TOPLEFT", 0, 0)

local function UpdateMiniPos()
    if not BattlegroundDefenderDB then return end
    if BattlegroundDefenderDB.minimapHide then 
        mini:Hide() 
    else 
        mini:Show() 
        local angle = BattlegroundDefenderDB.minimapPos or 45
        local r = 80
        local x = r * math.cos(math.rad(angle))
        local y = r * math.sin(math.rad(angle))
        mini:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
end

mini:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mini:SetScript("OnClick", function(self, btn) 
    if btn == "RightButton" then 
        if BDConfigFrame:IsShown() then BDConfigFrame:Hide() else BDConfigFrame:Show() end 
    else 
        if frame:IsShown() then frame:Hide() else frame:Show() end 
    end 
end)
mini:SetMovable(true)
mini:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        BattlegroundDefenderDB.minimapPos = angle
        UpdateMiniPos()
    end)
end)
mini:SetScript("OnDragStop", function(self)
    self:UnlockHighlight()
    self:SetScript("OnUpdate", nil)
end)
mini:SetScript("OnEnter", function(self) 
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Battleground Defender")
    GameTooltip:AddLine("|cffeda55fLinks:|r Fenster An/Aus")
    GameTooltip:AddLine("|cffeda55fRechts:|r Einstellungen")
    GameTooltip:AddLine("|cffeda55fZiehen:|r Verschieben")
    GameTooltip:Show() 
end)
mini:SetScript("OnLeave", GameTooltip_Hide)

local function SafeAutoSend(msg, chan)
    if InCombatLockdown() then
        -- Delay until combat ends
        C_Timer.After(0.5, function()
            if not InCombatLockdown() then
                SendChatMessage(msg, chan)
            end
        end)
    else
        SendChatMessage(msg, chan)
    end
end

-- [9] AUTO EVENTS
local function OnBGMessage(msg)
    if not BattlegroundDefenderDB or not BattlegroundDefenderDB.autoEvents then return end
    local pName = UnitName("player")
    if msg:find(pName) then
        local chan = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "SAY"
        if msg:find("picked up") or msg:find("aufgehoben") then
            SafeAutoSend(">>> I HAVE THE FLAG / ORB! <<<", chan)
        elseif msg:find("captured") or msg:find("eingenommen") then
            SafeAutoSend(">>> Base Captured by me! <<<", chan)
        elseif msg:find("defended") or msg:find("verteidigt") then
            SafeAutoSend(">>> Base Defended by me! <<<", chan)
        elseif msg:find("dropped") or msg:find("fallen gelassen") then
            SafeAutoSend(">>> I DROPPED THE FLAG! <<<", chan)
        end
    end
end

-- [10] SETTINGS
local cfg = CreateFrame("Frame", "BDConfigFrame", UIParent, "BackdropTemplate")
cfg:SetSize(280, 600); cfg:SetPoint("CENTER"); cfg:SetFrameStrata("DIALOG"); cfg:Hide(); cfg:SetMovable(true); cfg:EnableMouse(true)
cfg:RegisterForDrag("LeftButton"); cfg:SetScript("OnDragStart", cfg.StartMoving); cfg:SetScript("OnDragStop", cfg.StopMovingOrSizing); table.insert(UISpecialFrames, "BDConfigFrame")
cfg:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { 4, 4, 4, 4 } })
CreateFrame("Button", nil, cfg, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -5, -5)

local function CreateCheck(text, dbKey, y)
    local cb = CreateFrame("CheckButton", nil, cfg, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 10, y); cb.Text:SetText(text)
    cb:SetScript("OnShow", function(self) if BattlegroundDefenderDB then if dbKey == "minimapHide" then self:SetChecked(not BattlegroundDefenderDB.minimapHide) else self:SetChecked(BattlegroundDefenderDB[dbKey]) end end end)
    cb:SetScript("OnClick", function(self) 
        if dbKey == "minimapHide" then BattlegroundDefenderDB.minimapHide = not self:GetChecked() else BattlegroundDefenderDB[dbKey] = self:GetChecked() end 
        UpdateMiniPos(); ns.UpdateLayout()
    end)
end
CreateCheck(L["AUTO_OPEN"], "autoShow", -35); CreateCheck(L["LOCK"], "locked", -60)
CreateCheck(L["TEST_MODE"], "isTestMode", -85); CreateCheck(L["FORCE_EN"], "forceEnglish", -110)
CreateCheck(L["AUTO_EVENTS"], "autoEvents", -135); CreateCheck(L["ENABLE_SOUND"], "soundEnabled", -160)
CreateCheck("Minimap Icon", "minimapHide", -185); CreateCheck(L["SMART_CAST"], "smartCast", -210)
CreateCheck(L["USE_RW"], "useRW", -235)

local function CreateSlider(text, dbKey, min, max, step, y)
    local s = CreateFrame("Slider", addonName..dbKey, cfg, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 20, y); s:SetWidth(240); s:SetMinMaxValues(min, max); s:SetValueStep(step); _G[s:GetName().."Text"]:SetText(text)
    s:SetScript("OnShow", function(self) if BattlegroundDefenderDB then self:SetValue(BattlegroundDefenderDB[dbKey]) end end)
    s:SetScript("OnValueChanged", function(self, v) if BattlegroundDefenderDB then BattlegroundDefenderDB[dbKey] = v; ns.UpdateLayout() end end)
end
CreateSlider(L["FONT_SIZE"], "fontSize", 8, 32, 1, -280); CreateSlider(L["BG_ALPHA"], "bgAlpha", 0, 1, 0.1, -320)
CreateSlider(L["BORDER_ALPHA"], "borderAlpha", 0, 1, 0.1, -360); CreateSlider(L["SPACING"], "buttonSpacing", 0, 30, 1, -400)

local function OpenSelection(mType, cb)
    local selFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    selFrame:SetSize(350, 400); selFrame:SetPoint("CENTER"); selFrame:SetFrameStrata("TOOLTIP")
    selFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { 4, 4, 4, 4 } })
    local scroll = CreateFrame("ScrollFrame", nil, selFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -35); scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local scrollChild = CreateFrame("Frame"); scroll:SetScrollChild(scrollChild); scrollChild:SetSize(310, 1)
    CreateFrame("Button", nil, selFrame, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -5, -5)
    
    local LSM = GetLSM()
    local list = {"Default"}
    if LSM then
        local lsmL = LSM:List(mType)
        if lsmL then for _, n in ipairs(lsmL) do if n ~= "Default" then table.insert(list, n) end end end
    end
    
    local y = 0
    for i, n in ipairs(list) do
        local b = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate"); b:SetSize(300, 20); b:SetPoint("TOPLEFT", 0, y); b:SetText(n)
        b:SetScript("OnClick", function() 
            cb(n)
            if mType == "sound" then
                 if n == "Default" then PlaySound(DEFAULT_SOUND_ID, "Master")
                 elseif LSM then
                    local p = LSM:Fetch("sound", n)
                    if p then PlaySoundFile(p, "Master") end
                 end
            end
            ns.UpdateLayout()
            selFrame:Hide() 
        end)
        y = y - 22
    end
    scrollChild:SetHeight(math.abs(y) + 20)
end

local fBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate"); fBtn:SetSize(200, 25); fBtn:SetPoint("TOP", 0, -440)
local sBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate"); sBtn:SetSize(200, 25); sBtn:SetPoint("TOP", 0, -475)
fBtn:SetScript("OnClick", function() OpenSelection("font", function(v) BattlegroundDefenderDB.fontName = v end) end)
sBtn:SetScript("OnClick", function() OpenSelection("sound", function(v) BattlegroundDefenderDB.soundName = v end) end)
cfg:SetScript("OnUpdate", function() if BattlegroundDefenderDB then fBtn:SetText(L["FONT_BTN"]..": "..BattlegroundDefenderDB.fontName); sBtn:SetText(L["SOUND_BTN"]..": "..BattlegroundDefenderDB.soundName) end end)

-- [11] SLASH & INIT
local optBtn = CreateFrame("Button", nil, frame)
optBtn:SetSize(20, 20); optBtn:SetPoint("TOPRIGHT", -5, -5); optBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
optBtn:SetScript("OnClick", function() if cfg:IsShown() then cfg:Hide() else cfg:Show() end end)

SLASH_BATTLEGROUNDDEFENDER1 = "/bd"; SlashCmdList["BATTLEGROUNDDEFENDER"] = function(msg)
    local cmd = msg:lower():trim()
    if cmd == "reset" then BattlegroundDefenderDB = nil; ReloadUI()
    elseif cmd == "check" then
        print("|cff00ff00[BD DIAGNOSE]|r v8.0 REFORGED")
        print("Zone:", GetMinimapZoneText())
        print("Mode: Static Macro + Slash Relay")
        print("------------------")
    elseif cmd == "open" or cmd == "" then if frame:IsShown() then frame:Hide() else frame:Show() end end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN"); ev:RegisterEvent("ZONE_CHANGED_NEW_AREA"); ev:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL"); ev:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE"); ev:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE"); ev:RegisterEvent("ZONE_CHANGED_INDOORS")

ev:SetScript("OnEvent", function(self, event, msg)
    if event == "PLAYER_LOGIN" then
        BattlegroundDefenderDB = BattlegroundDefenderDB or CopyTable(defaults)
        for k, v in pairs(defaults) do if BattlegroundDefenderDB[k] == nil then BattlegroundDefenderDB[k] = v end end
        if BattlegroundDefenderDB.point then
            frame:ClearAllPoints()
            frame:SetPoint(BattlegroundDefenderDB.point, UIParent, BattlegroundDefenderDB.relativePoint or "CENTER", BattlegroundDefenderDB.xOfs, BattlegroundDefenderDB.yOfs)
        end

        UpdateMiniPos()
        BD_UpdateLocation()         -- NEU: initiale Position setzen
        ns.UpdateLayout()

        local _, t = IsInInstance()
        if BattlegroundDefenderDB.autoShow and t == "pvp" then
            frame:Show()
        end

    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" then
    BD_UpdateLocation()
    if event == "ZONE_CHANGED_NEW_AREA" then
        local _, t = IsInInstance()
        if BattlegroundDefenderDB and BattlegroundDefenderDB.autoShow then
            if t == "pvp" then frame:Show() else frame:Hide() end
        end
    end

    elseif event:find("CHAT_MSG_BG_SYSTEM") then
        OnBGMessage(msg)
    end
end)
