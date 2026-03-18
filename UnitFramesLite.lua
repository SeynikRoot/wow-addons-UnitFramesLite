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
        hpColor = {1, 1, 1, 1},
        barBG = {0, 0, 0, 0.35},
        useSolidColor = false,
        solidColor = {0.2, 0.8, 0.2, 1},
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
        hpColor = {1, 1, 1, 1},
        barBG = {0, 0, 0, 0.35},
        useSolidColor = false,
        solidColor = {0.8, 0.2, 0.2, 1},
        gradientStart = {0.8, 0.2, 0.2, 1},
        gradientEnd   = {0.4, 0.1, 0.1, 1},
        gradientDir   = "HORIZONTAL",
        statusbarTexture = "Blizzard",
    },
}

local frames = {}

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

local function SetTextAlignment(fontString, align)
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

function UnitFramesLite_UpdateFrame(unit)
    local frame = frames[unit]
    if not frame then return end

    local db = GetDB(unit)

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)

    -- Background panel
    local br, bg, bb, ba = unpack(db.barBG)
    frame.bg:SetColorTexture(br, bg, bb, ba)

    -- Health bar colour: solid or gradient
    if db.useSolidColor then
        local sr, sg, sb, sa = unpack(db.solidColor)
        frame.hp:SetColorTexture(sr, sg, sb, sa)
    else
        local texPath = "Interface\\TARGETINGFRAME\\UI-StatusBar"
        if LSM and db.statusbarTexture then
            texPath = LSM:Fetch("statusbar", db.statusbarTexture) or texPath
        end
        frame.hp:SetTexture(texPath)
        local dir = db.gradientDir or "HORIZONTAL"
        local sr, sg, sb, sa = unpack(db.gradientStart)
        local er, eg, eb, ea = unpack(db.gradientEnd)
        frame.hp:SetGradient(dir, CreateColor(sr, sg, sb, sa), CreateColor(er, eg, eb, ea))
    end

    -- Font
    local fontPath = STANDARD_TEXT_FONT
    if LSM and db.font then
        fontPath = LSM:Fetch("font", db.font) or fontPath
    end
    frame.text:SetFont(fontPath, db.fontSize or 14, "OUTLINE")

    local hr, hg, hb, ha = unpack(db.hpColor)
    frame.text:SetTextColor(hr, hg, hb, ha)

    SetTextAlignment(frame.text, db.nameAlign or "CENTER")

    if frame.OnUFLUpdate then
        frame:OnUFLUpdate()
    end
end

function UnitFramesLite_SetPosition(unit, x, y)
    local db = GetDB(unit)
    db.x, db.y = x, y
    UnitFramesLite_UpdateFrame(unit)
end

function UnitFramesLite_GetDB(unit)
    return GetDB(unit)
end

-- Slash commands
SLASH_UNITFRAMESLITE1 = "/ufl"
SLASH_UNITFRAMESLITE2 = "/unitframeslite"
SlashCmdList["UNITFRAMESLITE"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
    if cmd == "" or cmd == "options" or cmd == "opt" then
        if UnitFramesLite_ShowOptions then
            UnitFramesLite_ShowOptions()
        else
            print("UnitFramesLite: options not ready yet.")
        end
        return
    end
    if cmd == "reset" then
        UnitFramesLiteDB = {}
        UnitFramesLiteDB.player = CopyDefaults(defaults.player, {})
        UnitFramesLiteDB.target = CopyDefaults(defaults.target, {})
        UnitFramesLite_UpdateFrame("player")
        UnitFramesLite_UpdateFrame("target")
        print("UnitFramesLite: settings reset to defaults.")
        return
    end
    print("UnitFramesLite commands:")
    print("  /ufl options  - open options panel")
    print("  /ufl reset    - reset all settings to defaults")
end

-- Status flag helpers
local CLASSIFICATION_LABELS = {
    worldboss = " [Boss]",
    rareelite = " [Rare Elite]",
    elite     = " [Elite]",
    rare      = " [Rare]",
}

local function BuildStatusText(unit)
    local parts = {}
    if unit == "target" then
        local label = CLASSIFICATION_LABELS[UnitClassification(unit)]
        if label then parts[#parts + 1] = label end
    end
    if UnitIsGhost(unit) then
        parts[#parts + 1] = " [Ghost]"
    elseif UnitIsDead(unit) then
        parts[#parts + 1] = " [Dead]"
    elseif UnitAffectingCombat(unit) then
        parts[#parts + 1] = " [Combat]"
    end
    return table.concat(parts)
end

-- Frame setup (no fade animations — they caused continuous flashing)
local function SetupFrame(frame, unit)
    if not frame then return end
    frames[unit] = frame

    RegisterStateDriver(frame, "visibility", "show")

    -- Events
    frame:RegisterUnitEvent("UNIT_HEALTH",      unit)
    frame:RegisterUnitEvent("UNIT_MAXHEALTH",   unit)
    frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_FLAGS",       unit)
    if unit == "target" then
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end

    frame.OnUFLUpdate = function()
        local hp     = UnitHealth(unit)
        local maxhp  = UnitHealthMax(unit)
        local name   = UnitName(unit) or unit
        local isDead = UnitIsDead(unit)
        local status = BuildStatusText(unit)

        if isDead or maxhp == 0 then
            frame.text:SetText(name .. status)
        else
            frame.text:SetText(string.format("%s%s  %d / %d", name, status, hp, maxhp))
        end

        local pct = (maxhp > 0 and not isDead) and (hp / maxhp) or 0
        frame.hp:SetWidth(math.max(1, frame:GetWidth() * pct))
    end

    frame:SetScript("OnEvent", function(self, event, ...)
        self:OnUFLUpdate()
    end)
end

-- Addon lifecycle
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        UnitFramesLiteDB = UnitFramesLiteDB or {}
        UnitFramesLiteDB.player = CopyDefaults(defaults.player, UnitFramesLiteDB.player or {})
        UnitFramesLiteDB.target = CopyDefaults(defaults.target, UnitFramesLiteDB.target or {})
        -- CreateOptionsPanel is defined in UnitFramesLite_Options.lua
        local ok, err = pcall(CreateOptionsPanel)
        if not ok then
            print("|cffff4444UnitFramesLite|r: options panel error: " .. tostring(err))
        end
    elseif event == "PLAYER_LOGIN" then
        SetupFrame(UFL_PlayerFrame, "player")
        SetupFrame(UFL_TargetFrame, "target")
        UnitFramesLite_UpdateFrame("player")
        UnitFramesLite_UpdateFrame("target")
    end
end)
