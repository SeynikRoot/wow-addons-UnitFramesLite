local addonName = ...
local UFL = {}
_G.UnitFramesLite = UFL

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local ORB_MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

-- Defaults -------------------------------------------------------------------

local function MakeUnitDefaults(x, y, solidColor, gradStart, gradEnd, orbStart, orbEnd)
    return {
        x = x, y = y,
        font = "Friz Quadrata TT",
        nameAlign = "LEFT",
        hpColor = {1, 1, 1, 1},
        barBG = {0, 0, 0, 0.35},
        useSolidColor = false,
        solidColor    = solidColor,
        gradientStart = gradStart,
        gradientEnd   = gradEnd,
        gradientDir   = "HORIZONTAL",
        statusbarTexture = "Blizzard",
        enabled       = true,
        reverseFill   = false,
        portrait      = "Portrait Off",  -- legacy, kept for backwards compat
        portraitMode  = "None",           -- "None" | "2D" | "3D" | "Unit Type"
        portraitSide  = "Left",           -- "Left" | "Right"
        portraitClamp = true,             -- clamp to unit frame dimensions
        portraitW     = 35,               -- custom width when not clamped
        portraitH     = 35,               -- custom height when not clamped
        portraitX     = 0,               -- custom X offset when not clamped
        portraitY     = 0,               -- custom Y offset when not clamped
        locked        = false,
        frameWidth    = 160,
        frameHeight   = 35,
        hpBarHeight   = 0,
        showName      = true,
        showHPText    = true,
        showHPPct     = false,
        showLevel     = true,
        showPowerBar  = false,
        showPowerText = false,
        showResources        = true,
        useBlizzResource     = false,   -- true = control Blizzard class resource bar instead of UFL pips
        hideBlizzResourceBar = false,   -- true = suppress Blizzard bar via alpha regardless of source
        resourcePipWidth     = 18,
        resourcePipHeight    = 6,
        resourcePipGap       = 3,
        resourcePipShape     = "Rectangle",  -- "Rectangle" | "Circle" | "Diamond"
        resourceX            = 0,
        resourceY            = 0,
        resourceAlpha        = 1.0,
        resourceShowInCombat = false,   -- if true, only show in combat
        resourceShowWithTarget = false, -- if true, also show when target exists
        hpContent = "Cur / Max",  -- "Cur / Max" | "Current" | "Max"
        hpFormat  = "Full",       -- "Full" | "Short" (÷1000k)
        nameTextFontSize = 12, nameTextX = 0, nameTextY = 0,
        hpTextFontSize   = 11, hpTextX   = 0, hpTextY   = 0,
        levelTextFontSize= 11, levelTextX= 0, levelTextY= 0,
        -- Per-element text colors
        nameColor        = {1, 1, 1, 1},
        hpTextColor      = {1, 1, 1, 1},
        hpPctColor       = {1, 1, 1, 1},
        levelColor       = {1, 1, 1, 1},
        -- Per-element text alignments
        hpTextAlign      = "CENTER",
        levelTextAlign   = "CENTER",
        -- HP Percent (independent of HP text)
        hpPctShowSymbol  = true,
        hpPctFontSize    = 11, hpPctX = 0, hpPctY = -14,
        hpPctAlign       = "CENTER",
        loadMounted = false, loadInVehicle = false, loadResting  = false,
        loadStealthed = false, loadInCombat = false, loadOutOfCombat = false,
        loadSolo = false, loadInGroup = false, loadInInstance = false,
        syncAlpha = false, keepTextVisible = false,
        alphaAffects = "Everything",
        alphaCombat = 1.0, alphaOutCombat = 1.0,
        fadeNoTarget = false, fadeNoTargetAlpha = 0.4,
        barBorderEnabled = true, barBorderThickness = 1,
        barBorderColor = {0, 0, 0, 1},
        -- Orb
        sphereMode        = false,
        sphereSize        = 80,
        sphereFillDir     = "VERTICAL",
        orbGradientDir    = "VERTICAL",   -- gradient direction (independent of fill dir)
        orbUseSolidColor  = false,
        orbSolidColor     = orbStart,
        orbGradientStart  = orbStart,
        orbGradientEnd    = orbEnd,
        -- Orb inner border (ring between health orb and power ring)
        showOrbBorder      = false,
        orbBorderThickness = 4,
        orbBorderColor     = {0, 0, 0, 1},
        -- Power ring
        showOrbPower             = false,
        orbPowerRingThickness    = 8,
        orbPowerRingCCW          = false,
        orbPowerRingUseTypeColor = true,
        orbPowerRingColor        = {0, 0.5, 1, 1},
        orbPowerRingBgColor      = {0, 0, 0, 0.9},
    }
end

local function SetTextDefaults(d, nameX, nameY, nameAlign, hpX, hpY, hpAlign, lvlX, lvlY, lvlAlign)
    d.nameTextX = nameX; d.nameTextY = nameY; d.nameAlign = nameAlign
    d.hpTextX   = hpX;   d.hpTextY   = hpY;   d.hpTextAlign = hpAlign
    d.levelTextX= lvlX;  d.levelTextY= lvlY;  d.levelTextAlign = lvlAlign
    return d
end

local defaults = {
    player = SetTextDefaults(MakeUnitDefaults(-220, -160,
        {0.2,0.8,0.2,1}, {0.2,0.8,0.2,1}, {0.1,0.4,0.1,1},
        {0.2,0.5,0.9,1}, {0.05,0.15,0.6,1}),
        0, 15, "LEFT",    -- name: X=0, Y=15, LEFT
        70, -15, "CENTER", -- hp:   X=70, Y=-15, CENTER
        70, 15, "CENTER"), -- level: X=70, Y=15, CENTER
    target = SetTextDefaults(MakeUnitDefaults( 220, -160,
        {0.8,0.2,0.2,1}, {0.8,0.2,0.2,1}, {0.4,0.1,0.1,1},
        {0.9,0.3,0.1,1}, {0.5,0.1,0.05,1}),
        0, 15, "RIGHT",    -- name: X=0, Y=15, RIGHT (mirrored from player)
        -70, -15, "CENTER", -- hp:   X=-70 (mirrored), Y=-15, CENTER
        -70, 15, "CENTER"), -- level: X=-70 (mirrored), Y=15, CENTER
    focus  = SetTextDefaults(MakeUnitDefaults(   0, -220,
        {0.6,0.1,0.9,1}, {0.6,0.1,0.9,1}, {0.3,0.05,0.5,1},
        {0.5,0.1,0.9,1}, {0.25,0.05,0.45,1}),
        0, 15, "LEFT",    -- focus matches player
        70, -15, "CENTER",
        70, 15, "CENTER"),
    pet    = MakeUnitDefaults(-220, -240,
        {0.1,0.7,0.4,1}, {0.1,0.7,0.4,1}, {0.05,0.35,0.2,1},
        {0.1,0.7,0.4,1}, {0.05,0.35,0.2,1}),
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
    local def = defaults[unit] or defaults.player
    UnitFramesLiteDB[unit] = CopyDefaults(def, UnitFramesLiteDB[unit] or {})
    return UnitFramesLiteDB[unit]
end

-- Visibility -----------------------------------------------------------------

local function CheckLoadConditions(unit)
    local db = GetDB(unit)
    local anySet = db.loadMounted or db.loadInVehicle or db.loadResting or
                   db.loadStealthed or db.loadInCombat or db.loadOutOfCombat or
                   db.loadSolo or db.loadInGroup or db.loadInInstance
    if not anySet then return true end
    if db.loadMounted     and IsMounted()                       then return true end
    if db.loadInVehicle   and UnitInVehicle("player")           then return true end
    if db.loadResting     and IsResting()                       then return true end
    if db.loadStealthed   and IsStealthed()                     then return true end
    if db.loadInCombat    and UnitAffectingCombat("player")     then return true end
    if db.loadOutOfCombat and not UnitAffectingCombat("player") then return true end
    if db.loadSolo        and not IsInGroup()                   then return true end
    if db.loadInGroup     and IsInGroup()                       then return true end
    if db.loadInInstance  and IsInInstance()                    then return true end
    return false
end

function UnitFramesLite_UpdateVisibility(unit)
    local frame = frames[unit]
    if not frame then return end
    local db = GetDB(unit)
    if not db.enabled then frame:Hide(); return end
    -- Hide unit-specific frames when unit doesn't exist
    if unit ~= "player" and not UnitExists(unit) then frame:Hide(); return end
    frame:SetShown(CheckLoadConditions(unit))
end

-- Alpha ----------------------------------------------------------------------

function UnitFramesLite_UpdateAlpha(unit)
    local frame = frames[unit]
    if not frame then return end
    local db = GetDB(unit)

    local alphaDB = (unit == "target" and db.syncAlpha) and GetDB("player") or db
    local inCombat = UnitAffectingCombat("player")
    local alpha = inCombat and (alphaDB.alphaCombat or 1) or (alphaDB.alphaOutCombat or 1)

    if unit == "player" and db.fadeNoTarget and not UnitExists("target") then
        alpha = db.fadeNoTargetAlpha or 0.4
    end

    local textAlpha = db.keepTextVisible and 1 or alpha
    local affects   = alphaDB.alphaAffects or "Everything"

    if affects == "Foreground" then
        frame.hp:SetAlpha(alpha)
        if frame.power      then frame.power:SetAlpha(alpha) end
        frame.bg:SetAlpha(1)
        if frame.orbFill    then frame.orbFill:SetAlpha(alpha) end
        if frame.orbFill2   then frame.orbFill2:SetAlpha(alpha) end
    elseif affects == "Background" then
        frame.bg:SetAlpha(alpha)
        frame.hp:SetAlpha(1)
        if frame.power      then frame.power:SetAlpha(1) end
        if frame.orbFill    then frame.orbFill:SetAlpha(1) end
        if frame.orbFill2   then frame.orbFill2:SetAlpha(1) end
        if frame.orbBg      then frame.orbBg:SetAlpha(alpha) end
    else
        frame.hp:SetAlpha(alpha)
        if frame.power      then frame.power:SetAlpha(alpha) end
        frame.bg:SetAlpha(alpha)
        if frame.orbFill    then frame.orbFill:SetAlpha(alpha) end
        if frame.orbFill2   then frame.orbFill2:SetAlpha(alpha) end
        if frame.orbBg      then frame.orbBg:SetAlpha(alpha) end
    end

    if frame.powerRingFrame then frame.powerRingFrame:SetAlpha(alpha) end
    if frame.orbBorderFrame  then frame.orbBorderFrame:SetAlpha(alpha)  end

    -- Set alpha on the overlay frame AND directly on each FontString.
    -- The HIGH strata of textOverlay can cause alpha inheritance issues in WoW,
    -- so we belt-and-suspenders by setting both the frame and each text element.
    if frame.textOverlay then frame.textOverlay:SetAlpha(textAlpha) end
    if frame.nameText    then frame.nameText:SetAlpha(textAlpha)    end
    if frame.hpText      then frame.hpText:SetAlpha(textAlpha)      end
    if frame.hpPctText   then frame.hpPctText:SetAlpha(textAlpha)   end
    if frame.levelText   then frame.levelText:SetAlpha(textAlpha)   end
end

-- Health text ----------------------------------------------------------------
-- content: "Cur / Max" | "Current" | "Max"
-- format:  "Full" (raw integers) | "Short" (÷1000, "k" suffix)
--
-- pcall guards ALL arithmetic/format on secret health values (WoW 12.0+).
-- string.format("%d", secretNum) is safe and returns a secret string.
-- secretNum / 1000 is arithmetic and throws — caught by pcall, returns nil.
-- NEVER compare the return value to another string — only compare to nil.
local function GetHealthText(hp, maxhp, isDead, content, format)
    if isDead then return nil end
    local isShort = (format == "Short")
    local ok, text = pcall(function()
        if content == "Current" then
            if isShort then return string.format("%.0fk", hp / 1000)
            else             return string.format("%d", hp) end
        elseif content == "Max" then
            if isShort then return string.format("%.0fk", maxhp / 1000)
            else             return string.format("%d", maxhp) end
        else  -- "Cur / Max" (default)
            if isShort then return string.format("%.0fk / %.0fk", hp / 1000, maxhp / 1000)
            else             return string.format("%d / %d", hp, maxhp) end
        end
    end)
    return ok and text or nil
end

local function GetHPPercentText(isDead, showSymbol, unit)
    if isDead then return nil end
    local sym = (showSymbol ~= false) and "%" or ""
    -- Every health API returns secret numbers in 12.x — arithmetic and comparison
    -- all taint. string.format("%s") is the only safe extraction: it calls tostring
    -- internally and returns a plain string for secret numbers.
    -- We use string.find (returns plain number positions, never secret) to branch,
    -- and string.sub/gsub to extract the percentage digits without comparison.
    local ok, result = pcall(function()
        local pct = UnitHealthPercent(unit)
        -- %s on a secret number returns a plain string ("0.75", "1", "0", etc.)
        local s = string.format("%s", pct)
        -- Use string.find to check for a "." — returns plain numbers (positions) or nil.
        local dot = string.find(s, ".", 1, true)
        if not dot then
            -- No decimal: "0" or "1" — use %d formatting on a known-plain string
            -- to get "0" or "100" without any secret-number ops.
            local n = string.find(s, "^1")  -- plain number result, safe
            if n then return "100" .. sym end
            return "0" .. sym
        end
        -- Has decimal: "0.75", "0.08", etc. Extract digits after the dot.
        local frac = string.sub(s, dot + 1, dot + 2)  -- "75", "08"
        -- Strip a leading zero via gsub pattern (no comparison)
        frac = string.gsub(frac, "^0(%d)", "%1")       -- "08"->"8", "75"->"75"
        -- Handle empty result from gsub (shouldn't happen but be safe)
        frac = string.gsub(frac, "^$", "0")
        return frac .. sym
    end)
    return ok and result or nil
end

-- Font resolution helper -----------------------------------------------------
-- Resolves a per-element font key (e.g. "nameFont") with fallback to db.font.

local function ResolveFont(db, elemKey)
    local name = db[elemKey] or db.font
    if LSM and name then return LSM:Fetch("font", name) or STANDARD_TEXT_FONT end
    return STANDARD_TEXT_FONT
end

-- Text element helper --------------------------------------------------------

local function ApplyTextElement(fs, anchorFrame, fontPath, fontSize, color, x, y, justifyH)
    if not fs then return end
    fs:SetFont(fontPath, fontSize or 12, "OUTLINE")
    if color then fs:SetTextColor(color[1], color[2], color[3], color[4]) end
    fs:ClearAllPoints()
    fs:SetPoint("CENTER", anchorFrame, "CENTER", x or 0, y or 0)
    fs:SetWidth(anchorFrame:GetWidth() - 4)
    fs:SetJustifyH(justifyH or "CENTER")
end

-- Orb fill helper ------------------------------------------------------------
-- reversedGrad: used for the lower half of CENTRE mode — swaps gradient start/end
-- vertically so the orb centre is always gradientStart (bright) with no seam.

local function ApplyOrbFill(bar, db, circMask, reversedGrad)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    if db.orbUseSolidColor then
        local c = db.orbSolidColor or {0.1, 0.3, 0.9, 1}
        bar:SetStatusBarColor(c[1], c[2], c[3], c[4])
    else
        bar:SetStatusBarColor(1, 1, 1, 1)
        local gs   = db.orbGradientStart or {0.2, 0.5, 0.9, 1}
        local ge   = db.orbGradientEnd   or {0.05, 0.15, 0.6, 1}
        local gDir = db.orbGradientDir   or "VERTICAL"
        -- CENTRE gradient uses VERTICAL internally; the two-half split in
        -- UpdateFrame creates the radial effect. reversedGrad flips the lower half
        -- so both halves are bright at the orb centre with no visible seam.
        local effectiveDir = (gDir == "CENTRE") and "VERTICAL" or gDir
        local sbTex = bar:GetStatusBarTexture()
        if sbTex then
            if reversedGrad and effectiveDir == "VERTICAL" then
                sbTex:SetGradient(effectiveDir,
                    CreateColor(ge[1], ge[2], ge[3], ge[4]),
                    CreateColor(gs[1], gs[2], gs[3], gs[4]))
            else
                sbTex:SetGradient(effectiveDir,
                    CreateColor(gs[1], gs[2], gs[3], gs[4]),
                    CreateColor(ge[1], ge[2], ge[3], ge[4]))
            end
        end
    end
    local sbTex = bar:GetStatusBarTexture()
    if sbTex and circMask then sbTex:AddMaskTexture(circMask) end
end

-- Power ring fill helper -----------------------------------------------------

local POWER_COLORS = {}
local function SetPC(key, r, g, b)
    if key ~= nil then POWER_COLORS[key] = {r, g, b} end
end
SetPC(Enum.PowerType.Mana,        0.00, 0.00, 1.00)
SetPC(Enum.PowerType.Rage,        1.00, 0.00, 0.00)
SetPC(Enum.PowerType.Focus,       1.00, 0.50, 0.25)
SetPC(Enum.PowerType.Energy,      1.00, 1.00, 0.00)
SetPC(Enum.PowerType.ComboPoints, 1.00, 0.96, 0.41)
SetPC(Enum.PowerType.RunicPower,  0.00, 0.82, 1.00)
SetPC(Enum.PowerType.Fury,        0.79, 0.26, 0.99)
SetPC(Enum.PowerType.Pain,        1.00, 0.61, 0.00)
SetPC(Enum.PowerType.Essence,     0.31, 1.00, 0.74)

-- Secondary resource (class resource) power types and max counts
local CLASS_RESOURCES = {
    ROGUE       = { powerType = Enum.PowerType.ComboPoints, maxPips = 7 },
    DRUID       = { powerType = Enum.PowerType.ComboPoints, maxPips = 7 },
    PALADIN     = { powerType = Enum.PowerType.HolyPower,   maxPips = 5 },
    MONK        = { powerType = Enum.PowerType.Chi,         maxPips = 6 },
    WARLOCK     = { powerType = Enum.PowerType.SoulShards,  maxPips = 5 },
    DEATHKNIGHT = { powerType = nil, isRunes = true,        maxPips = 6 },
    MAGE        = { powerType = Enum.PowerType.ArcaneCharges, maxPips = 4 },
    EVOKER      = { powerType = Enum.PowerType.Essence,     maxPips = 6 },
}

local RESOURCE_COLORS = {
    [Enum.PowerType.ComboPoints]   = {1.00, 0.96, 0.41},
    [Enum.PowerType.HolyPower]     = {0.95, 0.90, 0.10},
    [Enum.PowerType.Chi]           = {0.71, 0.96, 0.71},
    [Enum.PowerType.SoulShards]    = {0.50, 0.32, 0.55},
    [Enum.PowerType.ArcaneCharges] = {0.40, 0.60, 1.00},
    [Enum.PowerType.Essence]       = {0.31, 1.00, 0.74},
    runes                          = {0.77, 0.12, 0.23},
}

local function GetPowerColor(unit)
    local pt = UnitPowerType(unit)
    return (pt and POWER_COLORS[pt]) or {0, 0, 1}
end

local function UpdatePowerColor(frame, unit)
    if not frame.power then return end
    local c = GetPowerColor(unit)
    frame.power:SetStatusBarColor(c[1], c[2], c[3], 1)
end

local function ApplyPowerRingColor(frame, unit)
    local db = GetDB(unit)
    local c
    if db.orbPowerRingUseTypeColor then
        c = GetPowerColor(unit)
    else
        c = db.orbPowerRingColor or {0, 0.5, 1, 1}
    end
    local fa = (db.orbPowerRingColor and db.orbPowerRingColor[4]) or 1
    if frame.powerRingFillR then frame.powerRingFillR:SetStatusBarColor(c[1], c[2], c[3], fa) end
    if frame.powerRingFillL then frame.powerRingFillL:SetStatusBarColor(c[1], c[2], c[3], fa) end
end

-- Resource pips (class resources: combo points, holy power, etc.) ------------

local resourceFrame = nil   -- created once on PLAYER_LOGIN
local resourcePips  = {}
local resourceClass = nil
local UpdateResourcePips  -- forward declaration so SetupResourcePips can call it

local function GetPlayerClass()
    local _, cls = UnitClass("player")
    return cls
end

local function SetupResourcePips()
    local cls = GetPlayerClass()
    resourceClass = cls
    local cfg = CLASS_RESOURCES[cls]
    if not cfg then
        if resourceFrame then resourceFrame:Hide() end
        return
    end

    local playerFrame = frames["player"]
    if not playerFrame then return end

    local db = GetDB("player")
    local maxPips = cfg.maxPips

    if not resourceFrame then
        resourceFrame = CreateFrame("Frame", "UFL_ResourceFrame", UIParent)
        resourceFrame:SetMovable(true)
        resourceFrame:EnableMouse(false)
    end

    -- Build pips
    for i = 1, maxPips do
        if not resourcePips[i] then
            local pip = CreateFrame("StatusBar", nil, resourceFrame)
            pip:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            pip:SetMinMaxValues(0, 1)
            pip:SetValue(0)
            local bg = pip:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
            pip.bg = bg
            -- Shape mask (applied/removed in UpdateResourceLayout)
            local mask = pip:CreateMaskTexture()
            mask:SetAllPoints()
            pip.shapeMask = mask
            -- Pre-create BG mask too
            local bgMask = pip:CreateMaskTexture()
            bgMask:SetAllPoints()
            pip.bgMask = bgMask
            resourcePips[i] = pip
        end
    end
    -- Hide unused pips
    for i = maxPips + 1, #resourcePips do
        resourcePips[i]:Hide()
    end

    UnitFramesLite_UpdateResourceLayout()
    -- Immediately populate pip values so colours show on first frame after login/reload
    if UpdateResourcePips then UpdateResourcePips() end
end

function UnitFramesLite_UpdateResourceLayout()
    local playerFrame = frames["player"]
    if not playerFrame or not resourceFrame then return end
    local db = GetDB("player")
    local cls = resourceClass
    local cfg = cls and CLASS_RESOURCES[cls]
    if not cfg then resourceFrame:Hide(); return end

    if db.showResources == false then resourceFrame:Hide(); return end

    local maxPips = cfg.maxPips
    local pipW    = db.resourcePipWidth   or 18
    local pipH    = db.resourcePipHeight  or 6
    local pipGap  = db.resourcePipGap     or 3
    local totalW  = maxPips * pipW + (maxPips - 1) * pipGap
    resourceFrame:SetSize(totalW, pipH)

    -- Position: anchored to player frame, below it
    resourceFrame:ClearAllPoints()
    local rx = db.resourceX or 0
    local ry = db.resourceY or 0
    resourceFrame:SetPoint("TOP", playerFrame, "BOTTOM", rx, ry - 2)

    -- Colour
    local col
    if cfg.isRunes then
        col = RESOURCE_COLORS.runes
    else
        col = RESOURCE_COLORS[cfg.powerType] or {1, 1, 1}
    end

    local shape = db.resourcePipShape or "Rectangle"
    local maskTex
    if shape == "Circle" then
        maskTex = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
    elseif shape == "Diamond" then
        maskTex = "Interface\\MINIMAP\\UI-Minimap-Background"  -- square rotated via SetRotation below
    end

    for i = 1, maxPips do
        local pip = resourcePips[i]
        if pip then
            pip:SetSize(pipW, pipH)
            pip:ClearAllPoints()
            pip:SetPoint("LEFT", resourceFrame, "LEFT", (i-1) * (pipW + pipGap), 0)
            pip:SetStatusBarColor(col[1], col[2], col[3], 1)

            -- Apply shape mask to fill and background
            local fillTex = pip:GetStatusBarTexture()
            local mask    = pip.shapeMask
            local bgMask  = pip.bgMask
            if maskTex and fillTex and mask then
                mask:SetTexture(maskTex)
                mask:SetAllPoints(pip)
                fillTex:AddMaskTexture(mask)
            elseif fillTex and mask then
                -- Rectangle: remove any mask
                pcall(function() fillTex:RemoveMaskTexture(mask) end)
            end
            if maskTex and pip.bg and bgMask then
                bgMask:SetTexture(maskTex)
                bgMask:SetAllPoints(pip)
                pip.bg:AddMaskTexture(bgMask)
            elseif pip.bg and bgMask then
                pcall(function() pip.bg:RemoveMaskTexture(bgMask) end)
            end

            pip:Show()
        end
    end

    resourceFrame:Show()
end

local runeUpdateElapsed = 0
local RUNE_UPDATE_RATE  = 0.05

UpdateResourcePips = function()
    if not resourceFrame then return end
    local cls = resourceClass
    local cfg = cls and CLASS_RESOURCES[cls]
    if not cfg then return end

    local maxPips = cfg.maxPips

    if cfg.isRunes then
        -- Death Knight runes: use GetRuneCooldown
        for i = 1, 6 do
            local pip = resourcePips[i]
            if pip then
                local start, duration, ready = GetRuneCooldown(i)
                if ready then
                    pip:SetValue(1)
                    pip:SetAlpha(1)
                else
                    local now = GetTime()
                    local elapsed = now - (start or now)
                    local frac = duration and duration > 0 and (elapsed / duration) or 0
                    pip:SetValue(math.max(0, math.min(1, frac)))
                    pip:SetAlpha(0.4)
                end
            end
        end
    else
        -- All other class resources
        local cur = 0
        pcall(function() cur = UnitPower("player", cfg.powerType) end)
        local max = maxPips
        pcall(function()
            local m = UnitPowerMax("player", cfg.powerType)
            if m and m > 0 then max = m end
        end)
        -- Clamp max to configured maxPips
        max = math.min(max, maxPips)

        -- Use safe comparison for secret numbers: pip is active if its index <= cur
        -- We can't do `i <= cur` directly (secret number comparison error in 12.0+).
        -- Use pcall per pip.
        for i = 1, maxPips do
            local pip = resourcePips[i]
            if pip then
                if i > max then
                    pip:Hide()
                else
                    pip:Show()
                    local active = false
                    pcall(function() active = (cur >= i) end)
                    pip:SetValue(active and 1 or 0)
                    pip:SetAlpha(active and 1 or 0.35)
                end
            end
        end
    end
end

-- Hook OnUpdate on the event frame for rune smooth updates
local resourceOnUpdateRegistered = false
local function RegisterResourceOnUpdate(eventFrame)
    if resourceOnUpdateRegistered then return end
    resourceOnUpdateRegistered = true
    eventFrame:HookScript("OnUpdate", function(self, elapsed)
        if resourceClass == "DEATHKNIGHT" and resourceFrame and resourceFrame:IsShown() then
            runeUpdateElapsed = runeUpdateElapsed + elapsed
            if runeUpdateElapsed >= RUNE_UPDATE_RATE then
                runeUpdateElapsed = 0
                UpdateResourcePips()
            end
        end
    end)
end

-- Update frame layout --------------------------------------------------------

function UnitFramesLite_UpdateFrame(unit)
    local frame = frames[unit]
    if not frame then return end
    local db = GetDB(unit)

    local w = db.frameWidth  or 160
    local h = db.frameHeight or 35
    frame:SetSize(w, h)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)

    local br, bg, bb, ba = unpack(db.barBG)
    frame.bg:SetColorTexture(br, bg, bb, ba)

    local barH = (db.hpBarHeight and db.hpBarHeight > 0) and db.hpBarHeight or h

    if db.sphereMode then
        -- ── Orb / sphere mode ─────────────────────────────────────────────
        frame.hp:Hide()
        if frame.power then frame.power:Hide() end
        frame.bg:SetColorTexture(0, 0, 0, 0)
        if frame.portraitFrame then frame.portraitFrame:Hide() end

        local sz          = math.max(20, db.sphereSize or 80)
        local fillDir     = db.sphereFillDir  or "VERTICAL"
        local gradDir     = db.orbGradientDir or "VERTICAL"
        local orbFrame    = frame.orbFrame
        orbFrame:SetSize(sz, sz)
        orbFrame:ClearAllPoints()
        orbFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
        orbFrame:Show()

        -- Background circle
        local bc = db.barBG or {0, 0, 0, 0.9}
        frame.orbBg:SetColorTexture(bc[1], bc[2], bc[3], math.max(0.7, bc[4]))

        -- Fill bars
        -- When Gradient Direction is CENTRE the orb is split into lower and upper
        -- halves. Each half tracks health independently (scaled per-half via Update).
        -- The reversed gradient on the lower half ensures both halves meet at the
        -- orbGradientStart colour at the centre, creating a seamless radial glow.
        if gradDir == "CENTRE" then
            local halfSz = sz / 2
            -- Lower half (bottom of orb)
            frame.orbFill:ClearAllPoints()
            frame.orbFill:SetPoint("BOTTOMLEFT", orbFrame, "BOTTOMLEFT", 0, 0)
            frame.orbFill:SetSize(sz, halfSz)
            frame.orbFill:SetOrientation(fillDir)
            frame.orbFill:SetReverseFill(db.reverseFill or false)
            ApplyOrbFill(frame.orbFill, db, frame.orbCircleMask, true)   -- reversed gradient
            if frame.orbFill2 then
                -- Upper half (top of orb)
                frame.orbFill2:ClearAllPoints()
                frame.orbFill2:SetPoint("TOPLEFT", orbFrame, "TOPLEFT", 0, 0)
                frame.orbFill2:SetSize(sz, halfSz)
                frame.orbFill2:SetOrientation(fillDir)
                frame.orbFill2:SetReverseFill(db.reverseFill or false)
                ApplyOrbFill(frame.orbFill2, db, frame.orbCircleMask, false)  -- normal gradient
                frame.orbFill2:Show()
            end
        else
            frame.orbFill:ClearAllPoints()
            frame.orbFill:SetAllPoints(orbFrame)
            frame.orbFill:SetOrientation(fillDir)
            frame.orbFill:SetReverseFill(db.reverseFill or false)
            ApplyOrbFill(frame.orbFill, db, frame.orbCircleMask)
            if frame.orbFill2 then frame.orbFill2:Hide() end
        end

        -- Inner border (circular band just outside the health orb)
        if db.showOrbBorder and frame.orbBorderFrame then
            local bt = math.max(1, db.orbBorderThickness or 4)
            local borderSz = sz + bt * 2
            frame.orbBorderFrame:SetSize(borderSz, borderSz)
            frame.orbBorderFrame:ClearAllPoints()
            frame.orbBorderFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
            local bc = db.orbBorderColor or {0, 0, 0, 1}
            frame.orbBorderTex:SetColorTexture(bc[1], bc[2], bc[3], bc[4])
            frame.orbBorderFrame:Show()
        elseif frame.orbBorderFrame then
            frame.orbBorderFrame:Hide()
        end

        -- Power ring
        if db.showOrbPower and frame.powerRingFrame then
            local thick    = math.max(4, db.orbPowerRingThickness or 8)
            local ringSz   = sz + thick * 2
            local prf      = frame.powerRingFrame
            prf:SetSize(ringSz, ringSz)
            prf:ClearAllPoints()
            prf:SetPoint("CENTER", orbFrame, "CENTER", 0, 0)

            local rc = db.orbPowerRingBgColor or {0, 0, 0, 0.9}
            frame.powerRingBg:SetColorTexture(rc[1], rc[2], rc[3], rc[4])

            local function SetupRingBar(bar)
                bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
                local st = bar:GetStatusBarTexture()
                if st and frame.powerRingCircMask then st:AddMaskTexture(frame.powerRingCircMask) end
            end

            local ccw = db.orbPowerRingCCW or false
            local halfRing = ringSz / 2
            frame.powerRingFillL:ClearAllPoints()
            frame.powerRingFillL:SetPoint("TOPLEFT", prf, "TOPLEFT", 0, 0)
            frame.powerRingFillL:SetSize(halfRing, ringSz)
            frame.powerRingFillL:SetOrientation("VERTICAL")
            frame.powerRingFillL:SetReverseFill(not ccw)
            SetupRingBar(frame.powerRingFillL)
            frame.powerRingFillR:ClearAllPoints()
            frame.powerRingFillR:SetPoint("TOPRIGHT", prf, "TOPRIGHT", 0, 0)
            frame.powerRingFillR:SetSize(halfRing, ringSz)
            frame.powerRingFillR:SetOrientation("VERTICAL")
            frame.powerRingFillR:SetReverseFill(ccw)
            SetupRingBar(frame.powerRingFillR)

            ApplyPowerRingColor(frame, unit)
            prf:Show()
        else
            if frame.powerRingFrame then frame.powerRingFrame:Hide() end
        end

        -- Text (uses Text tab settings, positioned relative to orb centre)
        if frame.nameText then
            local c = db.nameColor or {1, 1, 1, 1}
            frame.nameText:SetFont(ResolveFont(db, "nameFont"), db.nameTextFontSize or 12, "OUTLINE")
            frame.nameText:SetTextColor(c[1], c[2], c[3], c[4])
            frame.nameText:ClearAllPoints()
            frame.nameText:SetPoint("CENTER", frame, "CENTER",
                db.nameTextX or 0, (db.nameTextY or 0) + sz / 2 + 8)
            frame.nameText:SetWidth(sz + 40)
            frame.nameText:SetJustifyH(db.nameAlign or "CENTER")
        end
        if frame.hpText then
            local c = db.hpTextColor or {1, 1, 1, 1}
            frame.hpText:SetFont(ResolveFont(db, "hpTextFont"), db.hpTextFontSize or 11, "OUTLINE")
            frame.hpText:SetTextColor(c[1], c[2], c[3], c[4])
            frame.hpText:ClearAllPoints()
            frame.hpText:SetPoint("CENTER", frame, "CENTER",
                db.hpTextX or 0, db.hpTextY or 0)
            frame.hpText:SetWidth(sz - 4)
            frame.hpText:SetJustifyH(db.hpTextAlign or "CENTER")
        end
        if frame.hpPctText then
            local c = db.hpPctColor or {1, 1, 1, 1}
            frame.hpPctText:SetFont(ResolveFont(db, "hpPctFont"), db.hpPctFontSize or 11, "OUTLINE")
            frame.hpPctText:SetTextColor(c[1], c[2], c[3], c[4])
            frame.hpPctText:ClearAllPoints()
            frame.hpPctText:SetPoint("CENTER", frame, "CENTER",
                db.hpPctX or 0, db.hpPctY or -14)
            frame.hpPctText:SetWidth(sz - 4)
            frame.hpPctText:SetJustifyH(db.hpPctAlign or "CENTER")
        end
        if frame.levelText then
            local c = db.levelColor or {1, 1, 1, 1}
            frame.levelText:SetFont(ResolveFont(db, "levelFont"), db.levelTextFontSize or 11, "OUTLINE")
            frame.levelText:SetTextColor(c[1], c[2], c[3], c[4])
            frame.levelText:ClearAllPoints()
            frame.levelText:SetPoint("CENTER", frame, "CENTER",
                db.levelTextX or 0, (db.levelTextY or 0) - sz / 2 - 8)
            frame.levelText:SetWidth(sz)
            frame.levelText:SetJustifyH(db.levelTextAlign or "CENTER")
        end

    else
        -- ── Bar mode ──────────────────────────────────────────────────────
        if frame.orbFrame        then frame.orbFrame:Hide()       end
        if frame.orbFill2        then frame.orbFill2:Hide()       end
        if frame.orbBorderFrame  then frame.orbBorderFrame:Hide() end
        if frame.powerRingFrame  then frame.powerRingFrame:Hide() end
        -- Portrait frame is hidden when sphere mode is active (handled in portrait block below)

        frame.hp:Show()
        frame.hp:SetWidth(w)

        if db.useSolidColor then
            local texPath = "Interface\\TARGETINGFRAME\\UI-StatusBar"
            if LSM and db.statusbarTexture then
                texPath = LSM:Fetch("statusbar", db.statusbarTexture) or texPath
            end
            frame.hp:SetStatusBarTexture(texPath)
            local sr, sg, sb, sa = unpack(db.solidColor)
            frame.hp:SetStatusBarColor(sr, sg, sb, sa)
        else
            frame.hp:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            frame.hp:SetStatusBarColor(1, 1, 1, 1)
            local dir = db.gradientDir or "HORIZONTAL"
            local sr, sg, sb, sa = unpack(db.gradientStart)
            local er, eg, eb, ea = unpack(db.gradientEnd)
            local sbTex = frame.hp:GetStatusBarTexture()
            if sbTex then
                sbTex:SetGradient(dir,
                    CreateColor(sr, sg, sb, sa), CreateColor(er, eg, eb, ea))
            end
        end
        frame.hp:SetReverseFill(db.reverseFill or false)

        if frame.power then
            frame.power:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            frame.power:SetWidth(w)
            if db.showPowerBar then
                local hpH = math.max(10, barH - 8)
                frame.hp:SetHeight(hpH)
                frame.power:SetHeight(8)
                frame.power:Show()
            else
                frame.hp:SetHeight(barH)
                frame.power:Hide()
            end
        else
            frame.hp:SetHeight(barH)
        end

        ApplyTextElement(frame.nameText,  frame, ResolveFont(db, "nameFont"),
            db.nameTextFontSize  or 12, db.nameColor    or {1,1,1,1},
            db.nameTextX  or 0, db.nameTextY  or 0, db.nameAlign        or "LEFT")
        ApplyTextElement(frame.hpText,    frame, ResolveFont(db, "hpTextFont"),
            db.hpTextFontSize    or 11, db.hpTextColor  or {1,1,1,1},
            db.hpTextX    or 0, db.hpTextY    or 0, db.hpTextAlign      or "CENTER")
        ApplyTextElement(frame.hpPctText, frame, ResolveFont(db, "hpPctFont"),
            db.hpPctFontSize     or 11, db.hpPctColor   or {1,1,1,1},
            db.hpPctX     or 0, db.hpPctY     or -14,   db.hpPctAlign   or "CENTER")
        ApplyTextElement(frame.levelText, frame, ResolveFont(db, "levelFont"),
            db.levelTextFontSize or 11, db.levelColor   or {1,1,1,1},
            db.levelTextX or 0, db.levelTextY or 0, db.levelTextAlign   or "CENTER")
    end

    -- Portrait (bar mode only) ------------------------------------------------
    if frame.portraitFrame then
        local pMode  = db.portraitMode or "None"
        local pSide  = db.portraitSide or "Left"
        local clamp  = db.portraitClamp ~= false

        if pMode == "None" or db.sphereMode then
            frame.portraitFrame:Hide()
        else
            local pf = frame.portraitFrame
            local pw, ph
            if clamp then
                -- Clamp: height = frame height, width = height (square)
                ph = h
                pw = h
            else
                pw = db.portraitW or h
                ph = db.portraitH or h
            end

            pf:SetSize(pw, ph)
            pf:ClearAllPoints()
            if clamp then
                -- Attach directly to the display frame edge
                if pSide == "Left" then
                    pf:SetPoint("RIGHT", frame, "LEFT", 0, 0)
                else
                    pf:SetPoint("LEFT",  frame, "RIGHT", 0, 0)
                end
            else
                -- Freely positioned relative to frame centre
                local px = db.portraitX or 0
                local py = db.portraitY or 0
                if pSide == "Left" then
                    pf:SetPoint("RIGHT", frame, "LEFT",  px, py)
                else
                    pf:SetPoint("LEFT",  frame, "RIGHT", px, py)
                end
            end

            -- Show correct sub-widget
            if pMode == "2D" then
                frame.portrait2D:Show()
                if frame.portrait3D then frame.portrait3D:Hide() end
                SetPortraitTexture(frame.portrait2D, unit)
            elseif pMode == "3D" then
                frame.portrait2D:Hide()
                if frame.portrait3D then
                    frame.portrait3D:Show()
                    frame.portrait3D:SetUnit(unit)
                end
            elseif pMode == "Unit Type" then
                frame.portrait2D:Hide()
                if frame.portrait3D then
                    frame.portrait3D:Show()
                    -- Use creature model for non-player-controlled units; player model otherwise
                    local isPlayer = UnitIsPlayer(unit)
                    if isPlayer then
                        frame.portrait3D:SetUnit(unit)
                    else
                        frame.portrait3D:SetCreature(UnitCreatureFamily(unit) or 0)
                        frame.portrait3D:SetUnit(unit)  -- fallback sets the model correctly
                    end
                end
            end

            pf:Show()
        end
    end

    -- Bar border: always shown in bar mode, hidden in sphere mode
    if frame.borderFrame then
        if not db.sphereMode then
            local t = math.max(1, db.barBorderThickness or 1)
            local c = db.barBorderColor or {0, 0, 0, 1}
            frame.borderFrame:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = t,
                insets   = {left=0, right=0, top=0, bottom=0},
            })
            frame.borderFrame:SetBackdropBorderColor(c[1], c[2], c[3], c[4])
            frame.borderFrame:Show()
        else
            frame.borderFrame:Hide()
        end
    end

    UnitFramesLite_UpdateVisibility(unit)
    UnitFramesLite_UpdateAlpha(unit)
    if frame.OnUFLUpdate then frame:OnUFLUpdate() end
    if unit == "player" then
        if UnitFramesLite_UpdateResourceLayout then UnitFramesLite_UpdateResourceLayout() end
        if UnitFramesLite_UpdateResourceVisibility then UnitFramesLite_UpdateResourceVisibility() end
    end
end

function UnitFramesLite_SetPosition(unit, x, y)
    local db = GetDB(unit)
    db.x, db.y = x, y
    UnitFramesLite_UpdateFrame(unit)
end

function UnitFramesLite_GetDB(unit) return GetDB(unit) end

-- Copy DB from src unit to dest unit, mirroring X positions if mirror=true
function UnitFramesLite_CopyUnit(srcUnit, destUnit, mirror)
    local src = GetDB(srcUnit)
    UnitFramesLiteDB[destUnit] = UnitFramesLiteDB[destUnit] or {}
    local dest = UnitFramesLiteDB[destUnit]
    local ox, oy = dest.x, dest.y
    -- Deep copy all settings
    for k, v in pairs(DeepCopyAllDB(src)) do dest[k] = v end
    -- Restore position (don't move the frame)
    dest.x = ox or dest.x
    dest.y = oy or dest.y
    -- Mirror X text offsets and portrait side if requested
    if mirror then
        dest.nameTextX  = -(dest.nameTextX  or 0)
        dest.hpTextX    = -(dest.hpTextX    or 0)
        dest.hpPctX     = -(dest.hpPctX     or 0)
        dest.levelTextX = -(dest.levelTextX or 0)
        -- Mirror name alignment: LEFT→RIGHT, RIGHT→LEFT
        if dest.nameAlign == "LEFT" then dest.nameAlign = "RIGHT"
        elseif dest.nameAlign == "RIGHT" then dest.nameAlign = "LEFT" end
        if dest.hpTextAlign == "LEFT" then dest.hpTextAlign = "RIGHT"
        elseif dest.hpTextAlign == "RIGHT" then dest.hpTextAlign = "LEFT" end
        if dest.levelTextAlign == "LEFT" then dest.levelTextAlign = "RIGHT"
        elseif dest.levelTextAlign == "RIGHT" then dest.levelTextAlign = "LEFT" end
        -- Mirror portrait: flip side and negate custom X offset
        if dest.portraitSide == "Left" then dest.portraitSide = "Right"
        elseif dest.portraitSide == "Right" then dest.portraitSide = "Left" end
        dest.portraitX = -(dest.portraitX or 0)
    end
    UnitFramesLite_UpdateFrame(destUnit)
end

-- Profiles -------------------------------------------------------------------

-- Deep copy all keys (including nested tables of any depth)
local function DeepCopyAllDB(src)
    if type(src) ~= "table" then return src end
    local t = {}
    for k, v in pairs(src) do t[k] = DeepCopyAllDB(v) end
    return t
end

local function GetProfiles()
    UnitFramesLiteDB.profiles = UnitFramesLiteDB.profiles or { active = "Default", list = {} }
    return UnitFramesLiteDB.profiles
end

-- Capture current per-unit settings into a snapshot table
local function SnapshotUnits()
    local snap = {}
    for unit in pairs(defaults) do
        snap[unit] = DeepCopyAllDB(UnitFramesLiteDB[unit] or {})
    end
    return snap
end

function UnitFramesLite_ProfileList()
    local p = GetProfiles(); local names = {}
    for name in pairs(p.list) do names[#names+1] = name end
    table.sort(names); return names
end

function UnitFramesLite_ProfileCreate(name)
    if not name or name == "" then return end
    local p = GetProfiles()
    p.list[name] = SnapshotUnits()
    p.active = name
end

function UnitFramesLite_ProfileSetDefault(name)
    local p = GetProfiles()
    if not p.list[name] then return end
    p.active = name
    -- Apply the saved profile to the live DB
    local snap = p.list[name]
    for unit in pairs(defaults) do
        if snap[unit] then
            UnitFramesLiteDB[unit] = DeepCopyAllDB(snap[unit])
            CopyDefaults(defaults[unit], UnitFramesLiteDB[unit])
            UnitFramesLite_UpdateFrame(unit)
        end
    end
end

function UnitFramesLite_ProfileCopyFrom(name)
    -- Same as SetDefault but without changing active profile name
    local p = GetProfiles()
    if not p.list[name] then return end
    local snap = p.list[name]
    for unit in pairs(defaults) do
        if snap[unit] then
            UnitFramesLiteDB[unit] = DeepCopyAllDB(snap[unit])
            CopyDefaults(defaults[unit], UnitFramesLiteDB[unit])
            UnitFramesLite_UpdateFrame(unit)
        end
    end
end

function UnitFramesLite_ProfileDelete(name)
    local p = GetProfiles()
    p.list[name] = nil
    if p.active == name then p.active = "Default" end
end

-- Blizzard frame visibility --------------------------------------------------

-- Per-class Blizzard resource bar frame names
local BLIZZ_RESOURCE_FRAME = {
    ROGUE       = "RogueComboPointBarFrame",
    DRUID       = "DruidComboPointBarFrame",
    WARLOCK     = "WarlockPowerFrame",
    MAGE        = "MageArcaneChargesFrame",
    MONK        = "MonkHarmonyBarFrame",
    PALADIN     = "PaladinPowerBarFrame",
    DEATHKNIGHT = "RuneFrame",
    EVOKER      = "EssencePlayerFrame",
}

-- Returns the Blizzard resource frame for the player's class, or nil
local function GetBlizzResourceFrame()
    local cls = GetPlayerClass()
    local name = cls and BLIZZ_RESOURCE_FRAME[cls]
    return name and _G[name]
end

-- Unified: applies show/hide/alpha/position to whichever resource bar is active.
-- Called on combat state changes, target changes, and when settings change.
function UnitFramesLite_UpdateResourceVisibility()
    local db = GetDB("player")
    local inCombat   = UnitAffectingCombat("player")
    local hasTarget  = UnitExists("target")

    -- Determine if we should show
    local shouldShow = true
    if db.showResources == false then
        shouldShow = false
    elseif db.resourceShowInCombat and not db.resourceShowWithTarget then
        -- in-combat only
        shouldShow = inCombat
    elseif db.resourceShowWithTarget and not db.resourceShowInCombat then
        -- target-only
        shouldShow = hasTarget
    elseif db.resourceShowInCombat and db.resourceShowWithTarget then
        -- either
        shouldShow = inCombat or hasTarget
    end
    -- always-show if neither flag set

    local alpha = db.resourceAlpha or 1.0

    local bf = GetBlizzResourceFrame()

    if db.useBlizzResource then
        -- Show Blizzard bar, hide UFL pips
        if bf then
            bf:SetAlpha(shouldShow and alpha or 0)
            -- Don't call Show/Hide on Blizzard frames — use alpha only to avoid taint
        end
        if resourceFrame then resourceFrame:SetAlpha(0) end
    else
        -- Show UFL pips, suppress Blizzard bar (via alpha)
        if bf then
            -- Suppress if user has ticked "hide Blizzard resource bar" OR we are using UFL pips
            bf:SetAlpha(0)
        end
        if resourceFrame then
            if shouldShow then
                resourceFrame:SetAlpha(alpha)
                UnitFramesLite_UpdateResourceLayout()
            else
                resourceFrame:SetAlpha(0)
            end
        end
    end

    -- Independent "just hide Blizzard resource bar" option (regardless of source)
    if db.hideBlizzResourceBar and bf then
        bf:SetAlpha(0)
    end
end

local BLIZZ_FRAMES = {
    hideBlizzPlayer = {"PlayerFrame"},
    hideBlizzTarget = {"TargetFrame"},
    hideBlizzFocus  = {"FocusFrame"},
    hideBlizzPet    = {"PetFrame"},
}

function UnitFramesLite_ApplyBlizzardFrames()
    local g = UnitFramesLiteDB and UnitFramesLiteDB.global
    if not g then return end
    for key, frameNames in pairs(BLIZZ_FRAMES) do
        local hide = g[key]
        if hide then
            for _, name in ipairs(frameNames) do
                local f = _G[name]
                if f then
                    f:UnregisterAllEvents()
                    f:Hide()
                end
            end
        end
        -- When hide=false we do nothing: calling Show() on a Blizzard frame
        -- that has been hidden mid-session triggers taint via UnitFrame update
        -- callbacks. A /reload is required to restore hidden Blizzard frames.
    end
end

-- Slash commands -------------------------------------------------------------

SLASH_UNITFRAMESLITE1 = "/ufl"
SLASH_UNITFRAMESLITE2 = "/unitframeslite"
SlashCmdList["UNITFRAMESLITE"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
    if cmd == "" or cmd == "options" or cmd == "opt" then
        if UnitFramesLite_ShowOptions then UnitFramesLite_ShowOptions()
        else print("UnitFramesLite: options not ready yet.") end
        return
    end
    if cmd == "reset" then
        UnitFramesLiteDB = {}
        for unit in pairs(defaults) do
            UnitFramesLiteDB[unit] = CopyDefaults(defaults[unit], {})
        end
        for unit in pairs(frames) do UnitFramesLite_UpdateFrame(unit) end
        print("UnitFramesLite: settings reset to defaults.")
        return
    end
    print("UnitFramesLite commands:  /ufl options  /ufl reset")
end

-- Status flags ---------------------------------------------------------------

local CLASSIFICATION_LABELS = {
    worldboss = " [Boss]", rareelite = " [Rare Elite]",
    elite = " [Elite]",    rare      = " [Rare]",
}

local function BuildStatusText(unit)
    local parts = {}
    if unit == "target" or unit == "focus" then
        local label = CLASSIFICATION_LABELS[UnitClassification(unit)]
        if label then parts[#parts+1] = label end
    end
    if UnitIsGhost(unit)             then parts[#parts+1] = " [Ghost]"
    elseif UnitIsDead(unit)          then parts[#parts+1] = " [Dead]"
    elseif UnitAffectingCombat(unit) then parts[#parts+1] = " [Combat]" end
    return table.concat(parts)
end

-- Frame setup ----------------------------------------------------------------

-- Dynamically creates a display frame with the same structure as the XML frames.
-- Used for focus and pet (which are not declared in XML).
local function CreateUFLDisplayFrame(frameName, defX, defY)
    if _G[frameName] then return _G[frameName] end   -- already exists (XML)
    local f = CreateFrame("Button", frameName, UIParent)
    f:SetSize(160, 35)
    f:SetPoint("CENTER", UIParent, "CENTER", defX, defY)
    f:Hide()
    local bg = f:CreateTexture(frameName.."BG", "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.35)
    f.bg = bg
    local hp = CreateFrame("StatusBar", frameName.."HP", f)
    hp:SetPoint("TOPLEFT", f, "TOPLEFT")
    hp:SetSize(160, 35)
    f.hp = hp
    local power = CreateFrame("StatusBar", frameName.."Power", f)
    power:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT")
    power:SetSize(160, 8)
    power:Hide()
    f.power = power
    _G[frameName] = f
    return f
end

local function SetupFrame(displayFrame, unit)
    if not displayFrame then return end
    frames[unit] = displayFrame

    displayFrame:SetMovable(true)
    displayFrame:EnableMouse(true)
    displayFrame:RegisterForDrag("LeftButton")
    displayFrame:SetScript("OnDragStart", function(self)
        if not GetDB(unit).locked then self:StartMoving() end
    end)
    displayFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = self:GetCenter()
        local px, py = UIParent:GetCenter()
        if cx and cy and px and py then
            local db = GetDB(unit)
            db.x = math.floor(cx - px + 0.5)
            db.y = math.floor(cy - py + 0.5)
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
        end
    end)

    if displayFrame.hp    then displayFrame.hp:SetFrameStrata("LOW")    end
    if displayFrame.power then displayFrame.power:SetFrameStrata("LOW") end

    local parentLevel = displayFrame:GetFrameLevel()
    local borderFrame = CreateFrame("Frame", nil, displayFrame, "BackdropTemplate")
    borderFrame:SetAllPoints()
    borderFrame:SetFrameLevel(parentLevel + 5)
    borderFrame:Hide()
    displayFrame.borderFrame = borderFrame

    local textOverlay = CreateFrame("Frame", nil, displayFrame)
    textOverlay:SetAllPoints()
    textOverlay:SetFrameStrata("HIGH")
    displayFrame.textOverlay = textOverlay

    displayFrame.nameText   = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displayFrame.hpText     = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displayFrame.hpPctText  = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displayFrame.levelText  = textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")

    displayFrame:HookScript("OnHide", function() textOverlay:Hide() end)
    displayFrame:HookScript("OnShow", function() textOverlay:Show() end)

    -- ── Portrait ──────────────────────────────────────────────────────────
    -- portraitFrame holds either a 2D texture or a 3D model.
    -- Parented to UIParent so it sits beside (not inside) the unit frame.
    local portraitFrame = CreateFrame("Frame", nil, UIParent)
    portraitFrame:Hide()
    portraitFrame:SetFrameLevel(displayFrame:GetFrameLevel() + 1)
    displayFrame.portraitFrame = portraitFrame

    -- 2D portrait texture (used for "2D" mode)
    local portrait2D = portraitFrame:CreateTexture(nil, "ARTWORK")
    portrait2D:SetAllPoints()
    displayFrame.portrait2D = portrait2D

    -- 3D portrait model (used for "3D" and "Unit Type" modes)
    local portrait3D = CreateFrame("PlayerModel", nil, portraitFrame)
    portrait3D:SetAllPoints()
    portrait3D:Hide()
    displayFrame.portrait3D = portrait3D

    -- ── Power ring (behind orb) ───────────────────────────────────────────
    local powerRingFrame = CreateFrame("Frame", nil, displayFrame)
    powerRingFrame:Hide()
    displayFrame.powerRingFrame = powerRingFrame

    local powerRingBg = powerRingFrame:CreateTexture(nil, "BACKGROUND")
    powerRingBg:SetAllPoints()
    displayFrame.powerRingBg = powerRingBg

    local powerRingCircMask = powerRingFrame:CreateMaskTexture()
    powerRingCircMask:SetTexture(ORB_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    powerRingCircMask:SetAllPoints()
    powerRingBg:AddMaskTexture(powerRingCircMask)
    displayFrame.powerRingCircMask = powerRingCircMask

    -- Radial sweep via Cooldown frame. SetCooldown(start, duration) is a C-function
    -- that accepts secret numbers directly as arguments — no Lua arithmetic needed.
    -- We pass: start = GetTime() - power,  duration = maxPower
    -- so elapsed/duration = power/maxPower = fill fraction.
    -- Right half: fills the 3-o'clock side of the ring (CW: second 50%; CCW: first 50%)
    local prFillR = CreateFrame("StatusBar", nil, powerRingFrame)
    prFillR:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    displayFrame.powerRingFillR = prFillR
    local prStR = prFillR:GetStatusBarTexture()
    if prStR then prStR:AddMaskTexture(powerRingCircMask) end

    -- Left half: fills the 9-o'clock side (CW: first 50%; CCW: second 50%)
    local prFillL = CreateFrame("StatusBar", nil, powerRingFrame)
    prFillL:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    displayFrame.powerRingFillL = prFillL
    local prStL = prFillL:GetStatusBarTexture()
    if prStL then prStL:AddMaskTexture(powerRingCircMask) end

    -- ── Orb inner border (between power ring fills and health orb) ───────
    local orbBorderFrame = CreateFrame("Frame", nil, displayFrame)
    orbBorderFrame:Hide()
    orbBorderFrame:SetFrameLevel(powerRingFrame:GetFrameLevel() + 2)
    displayFrame.orbBorderFrame = orbBorderFrame

    local orbBorderTex = orbBorderFrame:CreateTexture(nil, "BACKGROUND")
    orbBorderTex:SetAllPoints()
    orbBorderTex:SetColorTexture(0, 0, 0, 1)
    displayFrame.orbBorderTex = orbBorderTex

    local orbBorderMask = orbBorderFrame:CreateMaskTexture()
    orbBorderMask:SetTexture(ORB_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    orbBorderMask:SetAllPoints()
    orbBorderTex:AddMaskTexture(orbBorderMask)

    -- ── Orb (above power ring and inner border) ───────────────────────────
    local orbFrame = CreateFrame("Frame", nil, displayFrame)
    orbFrame:Hide()
    orbFrame:SetFrameLevel(powerRingFrame:GetFrameLevel() + 3)
    displayFrame.orbFrame = orbFrame

    local orbBg = orbFrame:CreateTexture(nil, "BACKGROUND")
    orbBg:SetAllPoints()
    displayFrame.orbBg = orbBg

    local orbCircleMask = orbFrame:CreateMaskTexture()
    orbCircleMask:SetTexture(ORB_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    orbCircleMask:SetAllPoints()
    orbBg:AddMaskTexture(orbCircleMask)
    displayFrame.orbCircleMask = orbCircleMask

    local orbFill = CreateFrame("StatusBar", nil, orbFrame)
    orbFill:SetAllPoints()
    orbFill:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    displayFrame.orbFill = orbFill
    local st = orbFill:GetStatusBarTexture()
    if st then st:AddMaskTexture(orbCircleMask) end

    local orbFill2 = CreateFrame("StatusBar", nil, orbFrame)
    orbFill2:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    orbFill2:Hide()
    displayFrame.orbFill2 = orbFill2
    local st2 = orbFill2:GetStatusBarTexture()
    if st2 then st2:AddMaskTexture(orbCircleMask) end

    -- ── Event listener ────────────────────────────────────────────────────
    local listener = CreateFrame("Frame")
    listener:RegisterUnitEvent("UNIT_HEALTH",          unit)
    listener:RegisterUnitEvent("UNIT_MAXHEALTH",       unit)
    listener:RegisterUnitEvent("UNIT_NAME_UPDATE",     unit)
    listener:RegisterUnitEvent("UNIT_FLAGS",           unit)
    listener:RegisterUnitEvent("UNIT_LEVEL",           unit)
    listener:RegisterUnitEvent("UNIT_POWER_UPDATE",    unit)
    listener:RegisterUnitEvent("UNIT_POWER_FREQUENT",  unit)
    listener:RegisterUnitEvent("UNIT_DISPLAYPOWER",    unit)
    listener:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", unit)
    listener:RegisterUnitEvent("UNIT_MODEL_CHANGED",   unit)
    if unit == "target" then listener:RegisterEvent("PLAYER_TARGET_CHANGED") end
    if unit == "focus"  then listener:RegisterEvent("PLAYER_FOCUS_CHANGED")  end
    if unit == "pet"    then listener:RegisterEvent("UNIT_PET")               end

    local function Update()
        local hp       = UnitHealth(unit)
        local maxhp    = UnitHealthMax(unit)
        local power    = UnitPower(unit)
        local maxPower = UnitPowerMax(unit)
        local name     = UnitName(unit) or unit
        local isDead   = UnitIsDead(unit)
        local db       = GetDB(unit)

        displayFrame.hp:SetMinMaxValues(0, maxhp)
        displayFrame.hp:SetValue(isDead and 0 or hp)

        if displayFrame.orbFill then
            if db.sphereMode and db.orbGradientDir == "CENTRE"
               and displayFrame.orbFill2 and displayFrame.orbFill2:IsShown() then
                -- CENTRE gradient: lower half is 0→halfMax, upper half is halfMax→max.
                -- Encode the split into SetMinMaxValues so WoW handles the secret-number
                -- arithmetic internally — no Lua division of secret numbers needed.
                local halfMax = 0
                pcall(function() halfMax = maxhp / 2 end)
                local v = isDead and 0 or hp
                displayFrame.orbFill:SetMinMaxValues(0, halfMax)
                displayFrame.orbFill:SetValue(v)
                displayFrame.orbFill2:SetMinMaxValues(halfMax, maxhp)
                displayFrame.orbFill2:SetValue(v)
            else
                displayFrame.orbFill:SetMinMaxValues(0, maxhp)
                displayFrame.orbFill:SetValue(isDead and 0 or hp)
                if displayFrame.orbFill2 then
                    displayFrame.orbFill2:SetMinMaxValues(0, maxhp)
                    displayFrame.orbFill2:SetValue(isDead and 0 or hp)
                end
            end
        end

        -- Power bar
        if displayFrame.power then
            displayFrame.power:SetMinMaxValues(0, maxPower)
            displayFrame.power:SetValue(isDead and 0 or power)
            UpdatePowerColor(displayFrame, unit)
        end

        -- Power ring — power values are secret numbers in WoW 12.x.
        -- Avoid all Lua comparison/arithmetic on secret values; instead encode
        -- the half-ring split directly into SetMinMaxValues so WoW handles the
        -- math internally.  All arithmetic on secret numbers stays inside pcall.
        --
        -- CW ring visual: left half fills 0-50% of ring (power 0→max/2),
        --                 right half fills 50-100% (power max/2→max).
        -- Achieved by:   left  → SetMinMaxValues(0, halfMax),  SetValue(power)
        --                right → SetMinMaxValues(halfMax, max), SetValue(power)
        -- SetMinMaxValues and SetValue accept secret numbers just like StatusBar
        -- hp/power bars do — no taint error.
        if displayFrame.powerRingFillR and displayFrame.powerRingFillL and db.showOrbPower then
            local ccw   = db.orbPowerRingCCW or false
            local fillR = displayFrame.powerRingFillR
            local fillL = displayFrame.powerRingFillL
            local halfMax = 0
            pcall(function() halfMax = maxPower / 2 end)
            if not ccw then
                fillL:SetMinMaxValues(0, halfMax)
                fillL:SetValue(isDead and 0 or power)
                fillR:SetMinMaxValues(halfMax, maxPower)
                fillR:SetValue(isDead and 0 or power)
            else
                fillR:SetMinMaxValues(0, halfMax)
                fillR:SetValue(isDead and 0 or power)
                fillL:SetMinMaxValues(halfMax, maxPower)
                fillL:SetValue(isDead and 0 or power)
            end
            ApplyPowerRingColor(displayFrame, unit)
        end

        -- Name
        if db.showName ~= false then
            if displayFrame.nameText then
                displayFrame.nameText:SetText(name)
                displayFrame.nameText:Show()
            end
        else
            if displayFrame.nameText then displayFrame.nameText:Hide() end
        end

        -- HP text
        -- IMPORTANT: GetHealthText may return a secret string.
        -- We check hpStr ~= nil (type comparison, safe) rather than comparing
        -- the string value itself, to avoid the "attempt to compare secret string" error.
        if displayFrame.hpText then
            if db.showHPText ~= false then
                local hpStr   = GetHealthText(hp, maxhp, isDead, db.hpContent, db.hpFormat)
                local statStr = db.sphereMode and "" or BuildStatusText(unit)
                -- statStr is always a plain string (our own literals), safe to compare.
                if hpStr ~= nil or statStr ~= "" then
                    displayFrame.hpText:SetText((hpStr or "") .. statStr)
                    displayFrame.hpText:Show()
                else
                    displayFrame.hpText:Hide()
                end
            else
                displayFrame.hpText:Hide()
            end
        end

        -- HP Percent text (independent of HP text)
        if displayFrame.hpPctText then
            if db.showHPPct then
                local pctStr = GetHPPercentText(isDead, db.hpPctShowSymbol ~= false, unit)
                if pctStr ~= nil then
                    displayFrame.hpPctText:SetText(pctStr)
                    displayFrame.hpPctText:Show()
                else
                    displayFrame.hpPctText:Hide()
                end
            else
                displayFrame.hpPctText:Hide()
            end
        end

        -- Level (no "L" prefix)
        if displayFrame.levelText then
            if db.showLevel ~= false and UnitExists(unit) then
                local level = UnitLevel(unit)
                if level and level > 0 then
                    displayFrame.levelText:SetText(tostring(level))
                    displayFrame.levelText:Show()
                elseif level == -1 then
                    displayFrame.levelText:SetText("??")
                    displayFrame.levelText:Show()
                else
                    displayFrame.levelText:Hide()
                end
            else
                displayFrame.levelText:Hide()
            end
        end

        -- Portrait texture/model refresh (only if portrait is shown)
        if displayFrame.portraitFrame and displayFrame.portraitFrame:IsShown() then
            local pMode = db.portraitMode or "None"
            if pMode == "2D" and displayFrame.portrait2D then
                SetPortraitTexture(displayFrame.portrait2D, unit)
            elseif (pMode == "3D" or pMode == "Unit Type") and displayFrame.portrait3D then
                displayFrame.portrait3D:SetUnit(unit)
            end
        end
    end

    listener:SetScript("OnEvent", function() Update() end)
    displayFrame.OnUFLUpdate = Update
end

-- Addon lifecycle ------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
eventFrame:RegisterEvent("UPDATE_STEALTH")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
eventFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        UnitFramesLiteDB = UnitFramesLiteDB or {}
        -- Global (non-unit) settings
        UnitFramesLiteDB.global = UnitFramesLiteDB.global or {
            hideBlizzPlayer   = false,
            hideBlizzTarget   = false,
            hideBlizzFocus    = false,
            hideBlizzPet      = false,
        }
        -- Profiles table: { active="Default", profiles={ Default={player={...}, target={...}, ...} } }
        UnitFramesLiteDB.profiles = UnitFramesLiteDB.profiles or { active = "Default", list = {} }
        for unit, def in pairs(defaults) do
            UnitFramesLiteDB[unit] = CopyDefaults(def, UnitFramesLiteDB[unit] or {})
        end
        local ok, err = pcall(CreateOptionsPanel)
        if not ok then
            print("|cffff4444UnitFramesLite|r: options panel error: " .. tostring(err))
        end
    elseif event == "PLAYER_LOGIN" then
        -- Player and Target are declared in XML; Focus and Pet are dynamic
        local focusFrame = CreateUFLDisplayFrame("UFL_FocusFrame", 0,    -220)
        local petFrame   = CreateUFLDisplayFrame("UFL_PetFrame",   -220, -240)
        SetupFrame(UFL_PlayerFrame, "player")
        SetupFrame(UFL_TargetFrame, "target")
        SetupFrame(focusFrame,      "focus")
        SetupFrame(petFrame,        "pet")
        for unit in pairs(defaults) do
            UnitFramesLite_UpdateFrame(unit)
        end
        UnitFramesLite_ApplyBlizzardFrames()
        SetupResourcePips()
        RegisterResourceOnUpdate(eventFrame)
        UnitFramesLite_UpdateResourceVisibility()
    elseif event == "PLAYER_TARGET_CHANGED" then
        UnitFramesLite_UpdateVisibility("target")
        UnitFramesLite_UpdateAlpha("player")
        UnitFramesLite_UpdateAlpha("target")
        UnitFramesLite_UpdateResourceVisibility()
    elseif event == "PLAYER_FOCUS_CHANGED" then
        UnitFramesLite_UpdateVisibility("focus")
        UnitFramesLite_UpdateAlpha("focus")
    elseif event == "UNIT_PET" then
        UnitFramesLite_UpdateVisibility("pet")
        UnitFramesLite_UpdateAlpha("pet")
    elseif event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
        UpdateResourcePips()
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "UPDATE_SHAPESHIFT_FORM" then
        SetupResourcePips()
        UnitFramesLite_UpdateResourceLayout()
        UpdateResourcePips()
        UnitFramesLite_UpdateResourceVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        for unit in pairs(frames) do
            UnitFramesLite_UpdateAlpha(unit)
            UnitFramesLite_UpdateVisibility(unit)
        end
        UnitFramesLite_UpdateResourceVisibility()
    else
        for unit in pairs(frames) do UnitFramesLite_UpdateVisibility(unit) end
    end
end)

local vehicleFrame = CreateFrame("Frame")
vehicleFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
vehicleFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE",  "player")
vehicleFrame:SetScript("OnEvent", function()
    for unit in pairs(frames) do UnitFramesLite_UpdateVisibility(unit) end
end)
