local addonName = ...
local UFL = {}
_G.UnitFramesLite = UFL

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- Defaults
local defaults = {
    player = {
        x = -220, y = -160,
        font = "Friz Quadrata TT",
        fontSize = 14,
        nameAlign = "LEFT",
        hpAlign = "RIGHT",
        nameColor = {1, 1, 1, 1},
        hpColor = {1, 1, 1, 1},
        barBG = {0, 0, 0, 0.35},
        gradientStart = {0.2, 0.8, 0.2, 1},
        gradientEnd   = {0.1, 0.4, 0.1, 1},
        gradientDir   = "HORIZONTAL",
        statusbarTexture = "Blizzard",
    },
    target = {
        x = 220, y = -160,
        font = "Friz Quadrata TT",
        fontSize = 14,
        nameAlign = "LEFT",
        hpAlign = "RIGHT",
        nameColor = {1, 1, 1, 1},
        hpColor = {1, 1, 1, 1},
        barBG = {0, 0, 0, 0.35},
        gradientStart = {0.8, 0.2, 0.2, 1},
        gradientEnd   = {0.4, 0.1, 0.1, 1},
        gradientDir   = "HORIZONTAL",
        statusbarTexture = "Blizzard",
    },
}

local frames = {}

-- Shallow copy defaults into DB
local function CopyDefaults(src, dest)
    if type(dest) ~= "table" then dest = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = CopyDefaults(v, dest[k])
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
    return dest
end

local function GetDB(unit)
    UnitFramesLiteDB = UnitFramesLiteDB or {}
    UnitFramesLiteDB[unit] = CopyDefaults(defaults[unit], UnitFramesLiteDB[unit] or {})
    return UnitFramesLiteDB[unit]
end

-- Alignment helper
local function SetTextAlignment(fontString, align)
    align = align or "CENTER"
    fontString:ClearAllPoints()
    if align == "LEFT" then
        fontString:SetPoint("LEFT", fontString:GetParent(), "LEFT", 4, 0)
        fontString:SetJustifyH("LEFT")
    elseif align == "RIGHT" then
        fontString:SetPoint("RIGHT", fontString:GetParent(), "RIGHT", -4, 0)
        fontString:SetJustifyH("RIGHT")
    else
        fontString:SetPoint("CENTER", fontString:GetParent(), "CENTER", 0, 0)
        fontString:SetJustifyH("CENTER")
    end
end

-- Main update function
function UnitFramesLite_UpdateFrame(unit)
    local frame = frames[unit]
    if not frame then return end

    local db = GetDB(unit)

    -- Position
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)

    -- Background
    local br, bg, bb, ba = unpack(db.barBG or defaults[unit].barBG)
    frame.bg:SetColorTexture(br, bg, bb, ba)

    -- Texture
    local texPath
    if LSM and db.statusbarTexture then
        texPath = LSM:Fetch("statusbar", db.statusbarTexture) or "Interface\\TARGETINGFRAME\\UI-StatusBar"
    else
        texPath = "Interface\\TARGETINGFRAME\\UI-StatusBar"
    end
    frame.hp:SetTexture(texPath)

    -- Gradient
    local dir = db.gradientDir or "HORIZONTAL"
    local sr, sg, sb, sa = unpack(db.gradientStart or defaults[unit].gradientStart)
    local er, eg, eb, ea = unpack(db.gradientEnd   or defaults[unit].gradientEnd)
    frame.hp:SetGradient(dir, CreateColor(sr, sg, sb, sa), CreateColor(er, eg, eb, ea))

    -- Font
    local fontPath
    if LSM and db.font then
        fontPath = LSM:Fetch("font", db.font) or STANDARD_TEXT_FONT
    else
        fontPath = STANDARD_TEXT_FONT
    end
    local size = db.fontSize or 14
    frame.text:SetFont(fontPath, size, "OUTLINE")

    -- Text colours
    local nr, ng, nb, na = unpack(db.nameColor or defaults[unit].nameColor)
    local hr, hg, hb, ha = unpack(db.hpColor   or defaults[unit].hpColor)

    -- We’ll colour the whole string with HP colour for now; you can later split name/HP if you want.
    frame.text:SetTextColor(hr, hg, hb, ha)

    -- Alignment
    SetTextAlignment(frame.text, db.nameAlign or "CENTER")

    -- Force an event update
    if frame.OnUFLUpdate then
        frame:OnUFLUpdate()
    end
end

-- Position setter used by options
function UnitFramesLite_SetPosition(unit, x, y)
    local db = GetDB(unit)
    db.x, db.y = x, y
    UnitFramesLite_UpdateFrame(unit)
end

-- Options helpers
function UnitFramesLite_GetDB(unit)
    return GetDB(unit)
end

-- Ensure minimal options panel exists for Interface Options
local function CreateOptionsPanel()
    if not UnitFramesLiteOptions then
        local panel = CreateFrame("Frame", "UnitFramesLiteOptions", UIParent, "BackdropTemplate")
        panel:SetSize(620, 360)
        panel:SetPoint("CENTER")
        panel:SetBackdrop({bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = {left=8,right=8,top=8,bottom=8}})
        panel:SetBackdropColor(0,0,0,0.8)
        panel:SetMovable(true)
        panel:EnableMouse(true)
        panel:RegisterForDrag("LeftButton")
        panel:SetScript("OnDragStart", panel.StartMoving)
        panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOP", panel, "TOP", 0, -16)
        title:SetText("UnitFramesLite")

        local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -48)
        desc:SetWidth(588)
        desc:SetText("Use Interface Options -> AddOns -> UnitFramesLite for full settings. This window is a fallback.")

        local close = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        close:SetSize(100, 24)
        close:SetPoint("BOTTOM", panel, "BOTTOM", 0, 16)
        close:SetText("Close")
        close:SetScript("OnClick", function() panel:Hide() end)

        panel:SetFrameStrata("DIALOG")
        panel:SetClampedToScreen(true)
        panel:Hide()
        InterfaceOptions_AddCategory(panel)
        UnitFramesLiteOptions = panel
    end
end

local function ShowOptions()
    CreateOptionsPanel()
    print("UnitFramesLite: ShowOptions called. UnitFramesLiteOptions=", UnitFramesLiteOptions, "InterfaceOptionsFrame_OpenToCategory=", InterfaceOptionsFrame_OpenToCategory)

    if not IsAddOnLoaded("Blizzard_InterfaceOptions") then
        LoadAddOn("Blizzard_InterfaceOptions")
    end

    if UnitFramesLiteOptions then
        UnitFramesLiteOptions:Show()
        print("UnitFramesLite: UnitFramesLiteOptions shown.")
    end

    if InterfaceOptionsFrame_OpenToCategory then
        if UnitFramesLiteOptions then
            InterfaceOptionsFrame_OpenToCategory(UnitFramesLiteOptions)
            InterfaceOptionsFrame_OpenToCategory(UnitFramesLiteOptions)
            print("UnitFramesLite: OpenToCategory(UnitFramesLiteOptions)")
        else
            InterfaceOptionsFrame_OpenToCategory("UnitFramesLite")
            InterfaceOptionsFrame_OpenToCategory("UnitFramesLite")
            print("UnitFramesLite: OpenToCategory('UnitFramesLite')")
        end
    else
        print("UnitFramesLite: InterfaceOptionsFrame_OpenToCategory is nil.")
    end

    if InterfaceOptionsFrame then
        InterfaceOptionsFrame:Show()
        print("UnitFramesLite: InterfaceOptionsFrame shown.")
    end

    if UnitFramesLiteOptions and UnitFramesLiteOptions:IsShown() then
        print("UnitFramesLite: options panel visible.")
        return true
    end

    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
        print("UnitFramesLite: Interface Options shown.")
        return true
    end

    print("UnitFramesLite: options panel still hidden; showing fallback panel.")
    if UnitFramesLiteOptions then
        UnitFramesLiteOptions:Show()
        return true
    end

    return false
end

SlashCmdList["UNITFRAMESLITE"] = function(msg)
    local command = (msg or ""):lower():gsub("^%s*(.-)%s*$", "%1")
    if command == "" or command == "options" or command == "opt" then
        if not ShowOptions() then
            print("UnitFramesLite: options panel opened. If not visible, open Interface Options and click AddOns > UnitFramesLite.")
        end
        return
    end
    if command == "reset" then
        UnitFramesLiteDB = {}
        for _, unit in ipairs({"player", "target"}) do
            CopyDefaults(defaults[unit], UnitFramesLiteDB[unit] or {})
        end
        UnitFramesLite_UpdateFrame("player")
        UnitFramesLite_UpdateFrame("target")
        print("UnitFramesLite: settings reset to defaults.")
        return
    end

    print("UnitFramesLite commands:")
    print("/ufl options")
    print("/ufl reset")
end
SLASH_UNITFRAMESLITE1 = "/ufl"
SLASH_UNITFRAMESLITE2 = "/unitframeslite"

-- Frame setup
local function SetupFrame(frame, unit)
    if not frame then
        return
    end
    frames[unit] = frame
    -- Visibility rules
    -- show always for easier testing; change to conditional visibility as needed
    RegisterStateDriver(frame, "visibility", "show")

    -- Fade animation
    local fade = frame:CreateAnimationGroup()
    local fadeOut = fade:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.25)

    local fadeIn = fade:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.25)

    fade:SetScript("OnFinished", function()
        if frame:IsShown() then
            frame:SetAlpha(1)
        else
            frame:SetAlpha(0)
        end
    end)

    hooksecurefunc(frame, "Show", function()
        fadeIn:Play()
    end)

    hooksecurefunc(frame, "Hide", function()
        fadeOut:Play()
    end)

    -- Events
    frame:RegisterUnitEvent("UNIT_HEALTH", unit)
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)

    frame.OnUFLUpdate = function()
        local hp = UnitHealth(unit)
        local maxhp = UnitHealthMax(unit)
        local name = UnitName(unit) or unit

        frame.text:SetText(string.format("%s - %d / %d", name, hp, maxhp))

        local pct = maxhp > 0 and hp / maxhp or 0
        frame.hp:SetWidth(frame:GetWidth() * pct)
    end

    frame:SetScript("OnEvent", frame.OnUFLUpdate)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Ensure DB exists
        UnitFramesLiteDB = UnitFramesLiteDB or {}
        CopyDefaults(defaults.player, UnitFramesLiteDB.player or {})
        CopyDefaults(defaults.target, UnitFramesLiteDB.target or {})
        CreateOptionsPanel()
        print("UnitFramesLite: loaded and options panel created")
    elseif event == "PLAYER_LOGIN" then
        SetupFrame(UFL_PlayerFrame, "player")
        SetupFrame(UFL_TargetFrame, "target")
        UnitFramesLite_UpdateFrame("player")
        UnitFramesLite_UpdateFrame("target")
    end
end)