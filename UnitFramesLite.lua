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
        showPowerBar  = false,   -- legacy; superseded by orbPowerMode == "Bar"
        powerBarAttach = true,  -- bar mode: attach power bar to bottom of health bar
        showPowerText = false,
        showResources           = true,
        resourcePipWidth        = 18,
        resourcePipHeight       = 6,
        resourcePipGap          = 3,
        resourcePipShape        = "Rectangle",  -- "Rectangle" | "Circle" | "Diamond"
        resourcePipBorderEnabled   = false,
        resourcePipBorderThickness = 1,
        resourcePipBorderColor     = {0, 0, 0, 1},
        resourceX               = 0,
        resourceY               = 0,
        resourceAlpha           = 1.0,
        resourceUseCustomColor  = false,
        resourceColorMode       = "Solid",       -- "Solid" | "Gradient"
        resourceUseSolidColor   = true,          -- kept for back-compat; derived from resourceColorMode
        resourceGradPerPip      = true,
        resourceSolidColor      = {1, 1, 1, 1},
        resourceGradStart       = {1, 1, 1, 1},
        resourceGradEnd         = {0.3, 0.3, 1, 1},
        resourceShowOutCombat   = true,   -- show custom bar out of combat (always shown in combat)
        resourceShowWithTarget  = false,  -- also show custom bar when target selected (any combat state)
        -- Buff display
        buffIconSize      = 24,
        buffPerRow        = 4,
        buffMaxShown      = 8,
        buffGrowX         = "RIGHT",   -- overridden per-unit below
        buffGrowY         = "DOWN",
        buffXOffset       = 0,
        buffYOffset       = -15,
        buffAnchorToFrame = true,
        buffShowBuffs     = true,
        -- Debuff display
        debuffIconSize    = 24,
        debuffPerRow      = 4,
        debuffMaxShown    = 8,
        debuffGrowX       = "LEFT",    -- overridden per-unit below
        debuffGrowY       = "UP",
        debuffXOffset     = 0,
        debuffYOffset     = 0,
        debuffAnchorToFrame = true,
        debuffShowDebuffs = true,
        debuffPlayerOnly  = false,
        debuffCurableOnly = false,
        auraTooltipEnabled = true,
        auraTooltipDelay   = 0,
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
        orbBgColor        = {0, 0, 0, 0.9},
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
        -- Power ring / bar (orbPowerMode replaces showOrbPower; NOT in defaults so migration can detect nil)
        showOrbPower             = false,  -- kept for migration only
        orbPowerRingThickness    = 8,
        orbPowerRingCCW          = false,
        orbPowerRingUseTypeColor = true,
        orbPowerRingColor        = {0, 0.5, 1, 1},
        orbPowerRingBgColor      = {0, 0, 0, 0.9},
        -- Power bar (used when orbPowerMode == "Bar")
        orbPowerBarWidth         = 80,
        orbPowerBarHeight        = 12,
        orbPowerBarX             = 0,
        orbPowerBarY             = 0,
        orbPowerBarFillDir       = "HORIZONTAL",
        orbPowerBarColor         = {0, 0.5, 1, 1},
        orbPowerBarBgColor       = {0, 0, 0, 0.9},
        orbPowerBarUseTypeColor  = false,
        orbPowerShowOutOfCombat  = true,
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

-- Apply per-unit aura direction defaults
defaults.player.buffGrowX   = "LEFT"
defaults.player.debuffGrowX = "LEFT"
defaults.target.buffGrowX   = "RIGHT"
defaults.target.buffXOffset  = 45
defaults.target.debuffXOffset = 45
defaults.target.debuffGrowX = "RIGHT"

local frames = {}
local auraFrames = {}  -- forward-declared; populated by GetAuraData below

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

-- Returns false when the unit has no meaningful power resource to display.
-- WoW 12.0 secret numbers make UnitPowerMax unsafe to compare in Lua.
-- We instead check whether the unit is a player or player-controlled unit
-- (pets, player-controlled vehicles) — only these reliably have a power bar.
-- Non-player enemies and dummies are excluded even if WoW assigns them a
-- secret non-zero mana value.
local function UnitHasPower(unit)
    if not UnitExists(unit) then return false end
    return UnitIsPlayer(unit) or UnitPlayerControlled(unit) or false
end

-- Alpha ----------------------------------------------------------------------

function UnitFramesLite_UpdateAlpha(unit)
    local frame = frames[unit]
    if not frame then return end
    local db = GetDB(unit)

    local alphaDB  = (db.syncAlpha) and GetDB("player") or db
    local inCombat = UnitAffectingCombat("player")
    local alpha    = inCombat and (alphaDB.alphaCombat or 1) or (alphaDB.alphaOutCombat or 1)

    if unit == "player" and db.fadeNoTarget and not UnitExists("target") and not inCombat then
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

    local showPowerOOC = db.orbPowerShowOutOfCombat ~= false
    local hasPower     = UnitHasPower(unit)
    local powerAlpha   = hasPower and ((inCombat or showPowerOOC) and alpha or 0) or 0
    if frame.powerRingFrame then frame.powerRingFrame:SetAlpha(powerAlpha) end
    if frame.orbPowerBar    then frame.orbPowerBar:SetAlpha(powerAlpha)    end
    if frame.orbBorderFrame  then frame.orbBorderFrame:SetAlpha(alpha)  end
    if frame.borderFrame     then frame.borderFrame:SetAlpha(alpha)     end

    -- Set alpha on the overlay frame AND directly on each FontString.
    -- The HIGH strata of textOverlay can cause alpha inheritance issues in WoW,
    -- so we belt-and-suspenders by setting both the frame and each text element.
    if frame.textOverlay then frame.textOverlay:SetAlpha(textAlpha) end
    if frame.nameText    then frame.nameText:SetAlpha(textAlpha)    end
    if frame.hpText      then frame.hpText:SetAlpha(textAlpha)      end
    if frame.hpPctText   then frame.hpPctText:SetAlpha(textAlpha)   end
    if frame.levelText   then frame.levelText:SetAlpha(textAlpha)   end

    -- Aura containers are parented to UIParent so must be alpha'd explicitly
    local auraData = auraFrames[unit]
    if auraData then
        if auraData.buff   and auraData.buff.container   then auraData.buff.container:SetAlpha(alpha)   end
        if auraData.debuff and auraData.debuff.container then auraData.debuff.container:SetAlpha(alpha) end
    end

    -- Propagate to any other units that are syncing their alpha from this unit
    if unit == "player" then
        for otherUnit, _ in pairs(frames) do
            if otherUnit ~= "player" and GetDB(otherUnit).syncAlpha then
                UnitFramesLite_UpdateAlpha(otherUnit)
            end
        end
    end
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
    -- UnitHealthPercent returns a secret 0-1 value in 12.x; arithmetic is blocked.
    -- Passing CurveConstants.ScaleTo100 causes the API to return a plain 0-100 integer.
    local ok, result = pcall(function()
        local pct = UnitHealthPercent(unit, true, CurveConstants and CurveConstants.ScaleTo100)
        return string.format("%d", pct) .. sym
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

-- Secondary resource (class resource) power types and max counts.
-- hideWhenEmpty: true  → pip hidden entirely when inactive (Soul Shards, Arcane Charges, Essence)
--               false → pip shows a dim background when inactive (Combo Points, Holy Power, Chi, Runes)
-- fractional:   true  → UnitPower unmodified=true; value is divided by 10 for per-pip fill fraction
--                        (Warlock Soul Shards: 0-50 range, each 10 = one full shard)
-- catFormOnly:  true  → bar only visible while player's primary power is Energy (Feral/cat form)
local CLASS_RESOURCES = {
    ROGUE       = { powerType = Enum.PowerType.ComboPoints,   maxPips = 7, hideWhenEmpty = false },
    DRUID       = { powerType = Enum.PowerType.ComboPoints,   maxPips = 7, hideWhenEmpty = false, catFormOnly = true },
    PALADIN     = { powerType = Enum.PowerType.HolyPower,     maxPips = 5, hideWhenEmpty = false },
    MONK        = { powerType = Enum.PowerType.Chi,           maxPips = 6, hideWhenEmpty = false },
    WARLOCK     = { powerType = Enum.PowerType.SoulShards,    maxPips = 5, hideWhenEmpty = true, fractional = true },
    DEATHKNIGHT = { powerType = nil, isRunes = true,          maxPips = 6, hideWhenEmpty = false },
    MAGE        = { powerType = Enum.PowerType.ArcaneCharges, maxPips = 4, hideWhenEmpty = true },
    EVOKER      = { powerType = Enum.PowerType.Essence,       maxPips = 6, hideWhenEmpty = true },
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

local resourceFrame   = nil   -- created once on PLAYER_LOGIN
local resourcePips    = {}
local resourceClass   = nil
local resourceMaxPips = 0     -- live value from UnitPowerMax; updated in SetupResourcePips
local UpdateResourcePips  -- forward declaration so SetupResourcePips can call it

local function GetPlayerClass()
    local _, cls = UnitClass("player")
    return cls
end

-- Returns true if the resource bar should be suppressed due to a form/spec gate.
-- catFormOnly: Druid combo points only appear in cat form (primary power = Energy).
local function IsResourceGated(cfg)
    if not cfg then return true end
    if cfg.catFormOnly then
        local pt = UnitPowerType("player")
        return pt ~= Enum.PowerType.Energy
    end
    return false
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
    -- Derive the live pip count from the API; fall back to the cap if unavailable.
    local maxPips = cfg.maxPips  -- cap: maximum frames we ever create
    if not cfg.isRunes then
        local livePips = cfg.powerType and UnitPowerMax("player", cfg.powerType)
        if livePips and livePips > 0 then
            maxPips = math.min(livePips, cfg.maxPips)
        end
    end
    resourceMaxPips = maxPips

    if not resourceFrame then
        resourceFrame = CreateFrame("Frame", "UFL_ResourceFrame", UIParent)
        resourceFrame:SetMovable(true)
        resourceFrame:EnableMouse(false)
    end

    -- Build pips — always create up to the class cap so frames exist for any talent configuration.
    for i = 1, cfg.maxPips do
        if not resourcePips[i] then
            local pip = CreateFrame("StatusBar", nil, resourceFrame)

            -- Border: a texture on pip at BACKGROUND sublevel -7.
            -- pip.bg is at sublevel -8 (below border), StatusBar fill is above both.
            -- Textures can be anchored/sized outside their parent frame's bounds.
            local borderTex = pip:CreateTexture(nil, "BACKGROUND", nil, -7)
            borderTex:SetAllPoints(pip)   -- default; resized in UpdateResourceLayout
            borderTex:SetColorTexture(0, 0, 0, 1)
            borderTex:Hide()
            pip.borderTex = borderTex
            -- Mask texture for Circle/Diamond shaped borders
            local borderMask = pip:CreateMaskTexture()
            borderMask:SetAllPoints(pip)
            pip.borderMask = borderMask

            pip:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            pip:SetMinMaxValues(0, 1)
            pip:SetValue(0)
            local bg = pip:CreateTexture(nil, "BACKGROUND", nil, -8)
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
            pip.borderFrame = borderFrame
            resourcePips[i] = pip
        end
    end
    -- Hide pips beyond the live count
    for i = maxPips + 1, #resourcePips do
        resourcePips[i]:Hide()
        if resourcePips[i].borderTex then resourcePips[i].borderTex:Hide() end
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

    local maxPips = resourceMaxPips > 0 and resourceMaxPips or cfg.maxPips
    local pipW    = db.resourcePipWidth   or 18
    local pipH    = db.resourcePipHeight  or 6
    local pipGap  = db.resourcePipGap     or 3
    local totalW  = maxPips * pipW + (maxPips - 1) * pipGap
    resourceFrame:SetSize(totalW, pipH)

    -- Position: anchored to screen centre; x=0,y=0 places the bar at the centre of the screen.
    -- Clamp so the frame stays fully within the screen bounds.
    resourceFrame:ClearAllPoints()
    local rx = db.resourceX or 0
    local ry = db.resourceY or 0
    local screenW = UIParent:GetWidth()
    local screenH = UIParent:GetHeight()
    local halfFrameW = totalW / 2
    local halfFrameH = pipH  / 2
    local halfScreenW = screenW / 2
    local halfScreenH = screenH / 2
    rx = math.max(-(halfScreenW - halfFrameW), math.min(halfScreenW - halfFrameW, rx))
    ry = math.max(-(halfScreenH - halfFrameH), math.min(halfScreenH - halfFrameH, ry))
    resourceFrame:SetPoint("CENTER", UIParent, "CENTER", rx, ry)

    -- Colour
    local useCustom  = db.resourceUseCustomColor
    -- Support both old resourceUseSolidColor and new resourceColorMode
    local colorMode = db.resourceColorMode or (db.resourceUseSolidColor ~= false and "Solid" or "Horizontal Gradient")
    if colorMode == "Gradient" then colorMode = "Horizontal Gradient" end  -- migrate old value
    local useSolid  = (colorMode == "Solid")
    local gradPerPip = db.resourceGradPerPip ~= false     -- default true
    local gs = db.resourceGradStart or {1, 1, 1, 1}
    local ge = db.resourceGradEnd   or {0.3, 0.3, 1, 1}
    local col  -- fallback solid (class colour or custom solid)
    if useCustom then
        col = db.resourceSolidColor or {1, 1, 1, 1}
    elseif cfg.isRunes then
        col = RESOURCE_COLORS.runes
    else
        col = RESOURCE_COLORS[cfg.powerType] or {1, 1, 1}
    end

    local shape = db.resourcePipShape or "Rectangle"

    -- Helper: apply colour to a texture based on current colour settings.
    -- Uses SetVertexColor (not SetColorTexture) so that the texture's shape/rotation is preserved.
    local function ApplyColourToTex(tex, i)
        if not tex then return end
        if useCustom and not useSolid then
            local gradDir = (colorMode == "Vertical Gradient") and "VERTICAL" or "HORIZONTAL"
            if gradPerPip or colorMode == "Vertical Gradient" then
                tex:SetGradient(gradDir,
                    CreateColor(gs[1], gs[2], gs[3], gs[4] or 1),
                    CreateColor(ge[1], ge[2], ge[3], ge[4] or 1))
            else
                local t = maxPips > 1 and (i - 1) / (maxPips - 1) or 0
                local r = gs[1] + (ge[1] - gs[1]) * t
                local g = gs[2] + (ge[2] - gs[2]) * t
                local b = gs[3] + (ge[3] - gs[3]) * t
                tex:SetVertexColor(r, g, b, 1)
            end
        else
            local a = db.resourceAlpha or 1.0
            tex:SetVertexColor(col[1], col[2], col[3], a)
        end
    end

    for i = 1, maxPips do
        local pip = resourcePips[i]
        if pip then
            pip:SetSize(pipW, pipH)
            pip:ClearAllPoints()
            pip:SetPoint("LEFT", resourceFrame, "LEFT", (i-1) * (pipW + pipGap), 0)

            -- ── Apply colour to StatusBar-based pips ──────────────────────────
            local function ApplyStatusBarColour()
                local fillTex = pip:GetStatusBarTexture()
                if useCustom and not useSolid then
                    local gradDir = (colorMode == "Vertical Gradient") and "VERTICAL" or "HORIZONTAL"
                    if gradPerPip or colorMode == "Vertical Gradient" then
                        pip:SetStatusBarColor(1, 1, 1, 1)
                        if fillTex then
                            fillTex:SetGradient(gradDir,
                                CreateColor(gs[1], gs[2], gs[3], gs[4] or 1),
                                CreateColor(ge[1], ge[2], ge[3], ge[4] or 1))
                        end
                    else
                        local t = maxPips > 1 and (i - 1) / (maxPips - 1) or 0
                        local r2 = gs[1] + (ge[1] - gs[1]) * t
                        local g2 = gs[2] + (ge[2] - gs[2]) * t
                        local b2 = gs[3] + (ge[3] - gs[3]) * t
                        if fillTex then fillTex:SetGradient("HORIZONTAL", CreateColor(1,1,1,1), CreateColor(1,1,1,1)) end
                        pip:SetStatusBarColor(r2, g2, b2, 1)
                    end
                else
                    if fillTex then fillTex:SetGradient("HORIZONTAL", CreateColor(1,1,1,1), CreateColor(1,1,1,1)) end
                    local a = db.resourceAlpha or 1.0
                    pip:SetStatusBarColor(col[1], col[2], col[3], a)
                end
            end

            -- Restore StatusBar visibility and remove shaped textures when switching to bar-based shapes
            local function EnterStatusBarMode()
                pip.isShapedPip = false
                pip:SetAlpha(1)
                -- Remove any masks from shaped textures before hiding them
                pcall(function() if pip.shapeFill and pip.shapeMask then pip.shapeFill:RemoveMaskTexture(pip.shapeMask) end end)
                pcall(function() if pip.shapeBg   and pip.bgMask    then pip.shapeBg:RemoveMaskTexture(pip.bgMask)     end end)
                if pip.shapeFill then pip.shapeFill:Hide() end
                if pip.shapeBg   then pip.shapeBg:Hide()   end
                -- Remove any masks from pip.bg (applied by Circle mode) then restore it
                pcall(function() if pip.bg and pip.bgMask then pip.bg:RemoveMaskTexture(pip.bgMask) end end)
                if pip.bg then pip.bg:Show(); pip.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8) end
            end

            -- Set up shaped textures for non-StatusBar shapes (Diamond, Triangle, Arrow)
            local function EnterShapedMode()
                pip.isShapedPip = true
                pip:SetAlpha(1)
                local fillTex = pip:GetStatusBarTexture()
                -- Remove masks from StatusBar fill and pip.bg
                pcall(function() if fillTex and pip.shapeMask then fillTex:RemoveMaskTexture(pip.shapeMask) end end)
                pcall(function() if pip.bg and pip.bgMask then pip.bg:RemoveMaskTexture(pip.bgMask) end end)
                -- Remove circle masks from shaped textures if switching between shaped shapes (e.g. Circle->Diamond)
                pcall(function() if pip.shapeFill and pip.shapeMask then pip.shapeFill:RemoveMaskTexture(pip.shapeMask) end end)
                pcall(function() if pip.shapeBg   and pip.bgMask    then pip.shapeBg:RemoveMaskTexture(pip.bgMask)     end end)
                pip:SetStatusBarColor(0, 0, 0, 0)
                -- Hide the StatusBar bg rectangle — shaped pips draw their own bg via shapeBg texture
                if pip.bg then pip.bg:Hide() end
                if not pip.shapeFill then pip.shapeFill = pip:CreateTexture(nil, "ARTWORK") end
                if not pip.shapeBg   then pip.shapeBg   = pip:CreateTexture(nil, "BACKGROUND") end
            end

            -- ── Border ────────────────────────────────────────────────────────
            -- pip.borderTex is at BACKGROUND sublevel -7 on the pip itself.
            -- pip.bg  is at sublevel -8 (darkens background, below border tex).
            -- StatusBar fill renders above all BACKGROUND sublevels.
            local borderEnabled   = db.resourcePipBorderEnabled
            local borderThickness = db.resourcePipBorderThickness or 1
            local borderColor     = db.resourcePipBorderColor or {0, 0, 0, 1}
            local bt = pip.borderTex
            local bm = pip.borderMask
            if bt then
                pcall(function() bt:RemoveMaskTexture(bm) end)
                if borderEnabled then
                    local t  = borderThickness
                    local bc = borderColor
                    bt:SetTexture("Interface\\Buttons\\WHITE8X8")
                    bt:SetVertexColor(bc[1], bc[2], bc[3], bc[4] or 1)
                    if shape == "Circle" then
                        local circSize = math.min(pipW, pipH) + t * 2
                        bt:ClearAllPoints()
                        bt:SetSize(circSize, circSize)
                        bt:SetPoint("CENTER", pip, "CENTER", 0, 0)
                        bt:SetRotation(0)
                        if bm then
                            bm:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
                            bm:ClearAllPoints(); bm:SetSize(circSize, circSize)
                            bm:SetPoint("CENTER", pip, "CENTER", 0, 0)
                            pcall(function() bt:AddMaskTexture(bm) end)
                        end
                    elseif shape == "Diamond" then
                        local outerS = math.min(pipW, pipH) / math.sqrt(2) + t * math.sqrt(2)
                        bt:ClearAllPoints()
                        bt:SetSize(outerS, outerS)
                        bt:SetPoint("CENTER", pip, "CENTER", 0, 0)
                        bt:SetRotation(math.pi / 4)
                    else -- Rectangle
                        bt:ClearAllPoints()
                        bt:SetSize(pipW + t * 2, pipH + t * 2)
                        bt:SetPoint("CENTER", pip, "CENTER", 0, 0)
                        bt:SetRotation(0)
                    end
                    bt:Show()
                else
                    bt:Hide()
                end
            end

            if shape == "Rectangle" then
                EnterStatusBarMode()
                ApplyStatusBarColour()
                local fillTex = pip:GetStatusBarTexture()
                pcall(function() if fillTex and pip.shapeMask then fillTex:RemoveMaskTexture(pip.shapeMask) end end)
                pcall(function() if pip.bg and pip.bgMask then pip.bg:RemoveMaskTexture(pip.bgMask) end end)

            elseif shape == "Circle" then
                -- Use full-coverage textures masked to a circle so active/inactive
                -- can be shown by alpha, not by StatusBar fill percentage.
                EnterShapedMode()
                local sf, sb = pip.shapeFill, pip.shapeBg
                local circSize = math.min(pipW, pipH)
                sf:SetTexture("Interface\\Buttons\\WHITE8X8")
                sf:SetRotation(0)
                sf:SetSize(circSize, circSize)
                sf:ClearAllPoints(); sf:SetPoint("CENTER", pip, "CENTER", 0, 0)
                sb:SetTexture("Interface\\Buttons\\WHITE8X8")
                sb:SetRotation(0)
                sb:SetSize(circSize, circSize)
                sb:ClearAllPoints(); sb:SetPoint("CENTER", pip, "CENTER", 0, 0)
                sb:SetVertexColor(0.1, 0.1, 0.1, 0.8)
                -- Apply circle mask to both fill and bg textures
                if pip.shapeMask then
                    pip.shapeMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
                    pip.shapeMask:SetAllPoints(pip)
                    pcall(function() sf:AddMaskTexture(pip.shapeMask) end)
                end
                if pip.bgMask then
                    pip.bgMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
                    pip.bgMask:SetAllPoints(pip)
                    pcall(function() sb:AddMaskTexture(pip.bgMask) end)
                end
                ApplyColourToTex(sf, i)
                sf:SetAlpha(0)  -- alpha set by UpdateResourcePips; default to empty
                sf:Show(); sb:Show()

            elseif shape == "Diamond" then
                -- Rotate a square texture 45°. A square of side s has diagonal s*√2.
                -- To fill the pip bounds (pipW × pipH), use s = min(pipW,pipH)/√2 so
                -- the rotated corners touch the pip edges.
                EnterShapedMode()
                local s = math.min(pipW, pipH) / math.sqrt(2)
                local sf, sb = pip.shapeFill, pip.shapeBg
                sf:SetTexture("Interface\\Buttons\\WHITE8X8")
                sf:SetRotation(math.pi / 4)
                sf:SetSize(s, s)
                sf:ClearAllPoints(); sf:SetPoint("CENTER", pip, "CENTER", 0, 0)
                sb:SetTexture("Interface\\Buttons\\WHITE8X8")
                sb:SetRotation(math.pi / 4)
                sb:SetSize(s, s)
                sb:ClearAllPoints(); sb:SetPoint("CENTER", pip, "CENTER", 0, 0)
                sb:SetVertexColor(0.1, 0.1, 0.1, 0.8)
                ApplyColourToTex(sf, i)
                sf:SetAlpha(0)  -- alpha set by UpdateResourcePips; default to empty
                sf:Show(); sb:Show()

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

    local maxPips = resourceMaxPips > 0 and resourceMaxPips or cfg.maxPips

    if cfg.isRunes then
        -- Death Knight runes: use GetRuneCooldown
        for i = 1, 6 do
            local pip = resourcePips[i]
            if pip then
                local start, duration, ready = GetRuneCooldown(i)
                if ready then
                    if pip.isShapedPip then
                        if pip.shapeFill  then pip.shapeFill:SetAlpha(1)  end
                        if pip.shapeFill2 then pip.shapeFill2:SetAlpha(1) end
                    else
                        pip:SetValue(1); pip:SetAlpha(1)
                    end
                else
                    local now = GetTime()
                    local elapsed = now - (start or now)
                    local frac = duration and duration > 0 and (elapsed / duration) or 0
                    if pip.isShapedPip then
                        if pip.shapeFill  then pip.shapeFill:SetAlpha(frac)  end
                        if pip.shapeFill2 then pip.shapeFill2:SetAlpha(frac) end
                    else
                        pip:SetValue(math.max(0, math.min(1, frac))); pip:SetAlpha(0.4)
                    end
                end
            end
        end
    else
        -- All other class resources
        local hideWhenEmpty = cfg.hideWhenEmpty
        local isFractional  = cfg.fractional

        -- UnitPower/UnitPowerMax can return secret numbers in 12.0 for some power types.
        -- All comparisons involving these values must be inside pcall.
        -- cur/max are captured by closure so pcall callbacks can write them.
        local cur = 0
        local max = maxPips
        pcall(function()
            local m = UnitPowerMax("player", cfg.powerType)
            if m and m > 0 then max = math.min(m, maxPips) end
        end)
        if isFractional then
            -- Soul Shards: unmodified 0-50 range; each 10 units = 1 full shard.
            -- Arithmetic on secret values is also forbidden, so wrap in pcall.
            pcall(function() cur = UnitPower("player", cfg.powerType, true) end)
        else
            pcall(function() cur = UnitPower("player", cfg.powerType) end)
        end

        for i = 1, maxPips do
            local pip = resourcePips[i]
            if pip then
                local overMax = false
                pcall(function() overMax = (i > max) end)
                if overMax then
                    pip:Hide()
                else
                    -- Determine fill fraction for this pip (0–1) inside pcall since
                    -- comparing/doing arithmetic with secret numbers throws.
                    local fillFrac = 0
                    if isFractional then
                        pcall(function()
                            local pipMin = (i - 1) * 10
                            fillFrac = math.max(0, math.min(1, (cur - pipMin) / 10))
                        end)
                    else
                        pcall(function() fillFrac = (cur >= i) and 1 or 0 end)
                    end

                    local active = fillFrac > 0

                    if hideWhenEmpty and not active then
                        pip:Hide()
                    else
                        pip:Show()
                        if pip.isShapedPip then
                            if pip.shapeFill  then pip.shapeFill:SetAlpha(fillFrac)  end
                            if pip.shapeFill2 then pip.shapeFill2:SetAlpha(fillFrac) end
                        else
                            pip:SetValue(fillFrac)
                            pip:SetAlpha(active and 1 or 0.35)
                        end
                    end
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

    local barH = (db.hpBarHeight and db.hpBarHeight > 0) and math.min(db.hpBarHeight, h) or h

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
        local bc = db.orbBgColor or {0, 0, 0, 0.9}
        frame.orbBg:SetColorTexture(bc[1], bc[2], bc[3], bc[4] or 0.9)
        if frame.powerRingCentreCover then
            frame.powerRingCentreCover:SetColorTexture(bc[1], bc[2], bc[3], bc[4] or 0.9)
        end

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

        -- Power ring / bar
        local pMode = db.orbPowerMode or "None"

        if pMode == "Ring" and frame.powerRingFrame then
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

            -- Size the centre cover to the orb and colour it with orbBgColor so the
            -- ring BG is only visible in the ring band, not behind the health orb.
            if frame.powerRingCentreCover then
                frame.powerRingCentreCover:SetSize(sz, sz)
                frame.powerRingCentreMask:SetSize(sz, sz)
                frame.powerRingCentreMask:SetPoint("CENTER", prf, "CENTER", 0, 0)
                local bc = db.orbBgColor or {0, 0, 0, 0.9}
                frame.powerRingCentreCover:SetColorTexture(bc[1], bc[2], bc[3], bc[4] or 0.9)
            end

            prf:Show()
        else
            if frame.powerRingFrame then frame.powerRingFrame:Hide() end
        end

        if pMode == "Bar" and frame.orbPowerBar then
            local pb  = frame.orbPowerBar
            local bw  = db.orbPowerBarWidth    or 80
            local bh  = db.orbPowerBarHeight   or 12
            local bx  = db.orbPowerBarX        or 0
            local by  = db.orbPowerBarY        or 0
            local fd  = db.orbPowerBarFillDir  or "HORIZONTAL"
            pb:SetSize(bw, bh)
            pb:ClearAllPoints()
            pb:SetPoint("CENTER", frame, "CENTER", bx, by)
            pb:SetOrientation(fd)
            pb:SetReverseFill(db.reverseFill or false)
            local fc = db.orbPowerBarUseTypeColor and GetPowerColor(unit)
                       or db.orbPowerBarColor or {0, 0.5, 1, 1}
            pb:SetStatusBarColor(fc[1], fc[2], fc[3], fc[4] or 1)
            if frame.orbPowerBarBg then
                local bc = db.orbPowerBarBgColor or {0, 0, 0, 0.9}
                frame.orbPowerBarBg:SetColorTexture(bc[1], bc[2], bc[3], bc[4] or 0.9)
            end
            -- Ensure bar has valid range so it renders before first event fires
            pb:SetMinMaxValues(0, 1); pb:SetValue(1)
            pb:Show()
        else
            if frame.orbPowerBar then frame.orbPowerBar:Hide() end
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
        if frame.orbPowerBar     then frame.orbPowerBar:Hide()    end
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
            -- Bar mode power is enabled when orbPowerMode is "Bar" (or legacy showPowerBar)
            local barPowerEnabled = (db.orbPowerMode == "Bar") or
                                    (db.orbPowerMode == nil and db.showPowerBar)
            if barPowerEnabled then
                local attach = db.powerBarAttach ~= false  -- default true (attached)
                local maxPH  = math.max(1, math.floor(h / 2))
                local pH     = attach and math.max(1, math.min(db.orbPowerBarHeight or 8, maxPH))
                               or math.max(1, db.orbPowerBarHeight or 8)
                local pw     = attach and w or math.max(1, db.orbPowerBarWidth or w)
                local hpH    = math.max(1, barH - pH)
                frame.hp:SetHeight(hpH)
                frame.power:SetWidth(pw)
                frame.power:SetHeight(pH)
                frame.power:ClearAllPoints()
                frame.power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
                local fd = db.orbPowerBarFillDir or "HORIZONTAL"
                frame.power:SetOrientation(fd)
                frame.power:SetReverseFill(db.reverseFill or false)
                local fc = db.orbPowerBarUseTypeColor and GetPowerColor(unit)
                           or db.orbPowerBarColor or {0, 0.5, 1, 1}
                frame.power:SetStatusBarColor(fc[1], fc[2], fc[3], fc[4] or 1)
                if UnitHasPower(unit) then
                    frame.power:Show()
                else
                    frame.hp:SetHeight(barH)
                    frame.power:Hide()
                end
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

    -- Bar border: shown in bar mode only if barBorderEnabled, hidden in sphere mode
    if frame.borderFrame then
        if not db.sphereMode and db.barBorderEnabled ~= false then
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

local function DeepCopyAllDB(src)
    if type(src) ~= "table" then return src end
    local t = {}
    for k, v in pairs(src) do t[k] = DeepCopyAllDB(v) end
    return t
end

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
        -- Mirror aura Grow X: LEFT↔RIGHT for both buffs and debuffs
        if dest.buffGrowX == "LEFT" then dest.buffGrowX = "RIGHT"
        elseif dest.buffGrowX == "RIGHT" then dest.buffGrowX = "LEFT" end
        if dest.debuffGrowX == "LEFT" then dest.debuffGrowX = "RIGHT"
        elseif dest.debuffGrowX == "RIGHT" then dest.debuffGrowX = "LEFT" end
    end
    UnitFramesLite_UpdateFrame(destUnit)
    UnitFramesLite_UpdateAuras(destUnit)
end

-- Profiles -------------------------------------------------------------------

-- Deep copy all keys (including nested tables of any depth)
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


-- Controls visibility and alpha of the custom UFL resource bar only.
-- The Blizzard resource bar is left completely untouched — use WoW Edit Mode for that.
function UnitFramesLite_UpdateResourceVisibility()
    local db = GetDB("player")
    local inCombat  = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target")
    local alpha     = db.resourceAlpha or 1.0

    -- Custom bar is always shown in combat.
    -- "Show out of combat" controls out-of-combat visibility.
    -- "Show when target selected" shows it whenever a target exists regardless of combat state.
    local showOutCombat  = db.resourceShowOutCombat ~= false  -- default true
    local showWithTarget = db.resourceShowWithTarget or false

    local cfg = resourceClass and CLASS_RESOURCES[resourceClass]
    local shouldShow = true
    if db.showResources == false then
        shouldShow = false
    elseif IsResourceGated(cfg) then
        shouldShow = false
    elseif inCombat then
        shouldShow = true
    elseif showWithTarget and hasTarget then
        shouldShow = true
    else
        shouldShow = showOutCombat
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
    if cmd == "debug" then
        local db = GetDB("player")
        print("UFL debug: showHPPct=" .. tostring(db.showHPPct) .. " sphereMode=" .. tostring(db.sphereMode))
        local ok, pct = pcall(UnitHealthPercent, "player", true, CurveConstants and CurveConstants.ScaleTo100)
        print("UFL debug: UnitHealthPercent ok=" .. tostring(ok) .. " pct=" .. tostring(pct))
        local pctStr = GetHPPercentText(false, true, "player")
        print("UFL debug: GetHPPercentText=" .. tostring(pctStr))
        local f = frames and frames["player"]
        print("UFL debug: frames.player=" .. tostring(f ~= nil))
        if f then
            local hpPct = f.hpPctText
            print("UFL debug: hpPctText exists=" .. tostring(hpPct ~= nil)
                .. (hpPct and (" shown=" .. tostring(hpPct:IsShown()) .. " text=" .. tostring(hpPct:GetText())) or ""))
        end
        return
    end
    print("UnitFramesLite commands:  /ufl options  /ufl reset  /ufl debug")
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
    textOverlay:SetFrameStrata("MEDIUM")
    textOverlay:SetFrameLevel(parentLevel + 20)  -- above orb (+3), border (+5), orbPowerBar (+6)
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

    -- Centre cover: sits above powerRingBg (BORDER layer) on the same frame, sized to
    -- the orb diameter and masked to a circle. Always coloured with orbBgColor so the
    -- ring BG colour only shows in the ring band, not the orb centre.
    local powerRingCentreCover = powerRingFrame:CreateTexture(nil, "BORDER")
    powerRingCentreCover:SetPoint("CENTER", powerRingFrame, "CENTER", 0, 0)
    displayFrame.powerRingCentreCover = powerRingCentreCover

    local powerRingCentreMask = powerRingFrame:CreateMaskTexture()
    powerRingCentreMask:SetTexture(ORB_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    powerRingCentreCover:AddMaskTexture(powerRingCentreMask)
    displayFrame.powerRingCentreMask = powerRingCentreMask

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

    -- ── Orb power bar (standalone bar, shown when orbPowerMode=="Bar") ─────
    local orbPowerBar = CreateFrame("StatusBar", nil, displayFrame)
    orbPowerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    orbPowerBar:SetFrameStrata("MEDIUM")
    orbPowerBar:SetFrameLevel(parentLevel + 6)
    orbPowerBar:Hide()
    displayFrame.orbPowerBar = orbPowerBar
    local orbPowerBarBg = orbPowerBar:CreateTexture(nil, "BACKGROUND")
    orbPowerBarBg:SetAllPoints()
    displayFrame.orbPowerBarBg = orbPowerBarBg

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
    listener:RegisterUnitEvent("UNIT_AURA",            unit)
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
        local pMode = db.orbPowerMode or "None"
        if pMode == "Ring" and displayFrame.powerRingFillR and displayFrame.powerRingFillL then
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
        if pMode == "Bar" and displayFrame.orbPowerBar then
            displayFrame.orbPowerBar:SetMinMaxValues(0, maxPower)
            displayFrame.orbPowerBar:SetValue(isDead and 0 or power)
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

    listener:SetScript("OnEvent", function(_, evt)
        Update()
        if evt == "UNIT_AURA" then UnitFramesLite_UpdateAuras(unit) end
    end)
    displayFrame.OnUFLUpdate = Update

    -- Orb HP% text: poll UnitHealthPercent on a throttle so the text stays in sync
    -- with the fill without waiting for UNIT_HEALTH events. CurveConstants.ScaleTo100
    -- returns a plain integer, avoiding all secret-number arithmetic.
    local orbPctElapsed = 0
    orbFill:SetScript("OnUpdate", function(self, elapsed)
        orbPctElapsed = orbPctElapsed + elapsed
        if orbPctElapsed < 0.05 then return end  -- ~20 Hz
        orbPctElapsed = 0
        local db = GetDB(unit)
        if not (db.sphereMode and db.showHPPct) then return end
        local hpPctText = displayFrame.hpPctText
        if not hpPctText or not hpPctText:IsShown() then return end
        local pctStr = GetHPPercentText(UnitIsDead(unit), db.hpPctShowSymbol ~= false, unit)
        if pctStr then hpPctText:SetText(pctStr) end
    end)
end

-- Aura display --------------------------------------------------------------
-- Separate containers for buffs and debuffs per unit.
-- Layout and filtering are recomputed on every UNIT_AURA event.

-- auraFrames[unit] = { buff = {container, pool={}}, debuff = {container, pool={}} }
-- (auraFrames is forward-declared near the top of the file)

local DISPEL_TYPES = { Magic=true, Curse=true, Disease=true, Poison=true }

local function GetAuraData(unit)
    if auraFrames[unit] then return auraFrames[unit] end
    local function makeSlot(suffix)
        local c = CreateFrame("Frame", "UFL_Auras_" .. unit .. "_" .. suffix, UIParent)
        c:SetSize(1, 1); c:Hide()
        return { container = c, pool = {} }
    end
    auraFrames[unit] = { buff = makeSlot("buff"), debuff = makeSlot("debuff") }
    return auraFrames[unit]
end

-- Keep old name for event-init call compatibility
local function GetAuraContainer(unit) return GetAuraData(unit) end

local function GetOrCreateIcon(pool, idx, container)
    if pool[idx] then return pool[idx] end
    local btn = CreateFrame("Button", nil, container)
    btn:SetSize(24, 24)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon
    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0, 0, 0, 1)
    local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    cd:SetAllPoints(); cd:SetDrawEdge(false); cd:SetHideCountdownNumbers(false)
    btn.cd = cd
    local stack = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    stack:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, 0)
    btn.stack = stack
    local debuffBorder = btn:CreateTexture(nil, "OVERLAY")
    debuffBorder:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    debuffBorder:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    debuffBorder:SetAllPoints(); debuffBorder:Hide()
    btn.debuffBorder = debuffBorder

    -- Tooltip: btn.auraUnit and btn.auraIndex are set by LayoutAuraStrip before Show()
    local tooltipTimer = nil
    btn:SetScript("OnEnter", function(self)
        local db = self.auraUnit and GetDB(self.auraUnit)
        if not db or not db.auraTooltipEnabled then return end
        local delay = db.auraTooltipDelay or 0
        local function showTip()
            tooltipTimer = nil
            if not self:IsMouseOver() then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
            if self.auraUnit and self.auraIndex and self.auraFilter then
                GameTooltip:SetUnitAura(self.auraUnit, self.auraIndex, self.auraFilter)
            end
            GameTooltip:Show()
        end
        if delay <= 0 then
            showTip()
        else
            tooltipTimer = C_Timer.After(delay, showTip)
        end
    end)
    btn:SetScript("OnLeave", function()
        tooltipTimer = nil
        GameTooltip:Hide()
    end)

    pool[idx] = btn
    return btn
end

local DEBUFF_COLORS = {
    Magic   = {0.2, 0.6, 1},
    Curse   = {0.6, 0,   1},
    Disease = {0.6, 0.4, 0},
    Poison  = {0,   0.6, 0},
}

-- Returns how far above/below the frame centre the outermost visual edge extends.
-- In orb mode this is the orb radius + power ring thickness (if shown).
-- In bar mode it's just half the frame height.
local function GetFrameVerticalExtent(frame, db)
    if db.sphereMode then
        local sz    = math.max(20, db.sphereSize or 80)
        local extra = 0
        local pMode = db.orbPowerMode or "None"
        if pMode == "Ring" then
            extra = math.max(4, db.orbPowerRingThickness or 8)
        end
        return sz / 2 + extra
    else
        return (db.frameHeight or 35) / 2
    end
end

-- Lay out one aura strip (buffs or debuffs) given collected aura list + config.
local function LayoutAuraStrip(slot, auras, frame, db, iconSize, perRow, maxShown,
                                growX, growY, xOffset, yOffset, anchorToFrame, extraVertPad,
                                unit, auraFilter)
    local container = slot.container
    local pool      = slot.pool
    local gap       = 2

    -- Clamp to maxShown
    local count = math.min(#auras, maxShown)

    if count == 0 then
        container:Hide()
        for i = 1, #pool do pool[i]:Hide() end
        return
    end

    local cols  = math.max(1, perRow)
    local rows  = math.ceil(count / cols)
    local totalW = cols * (iconSize + gap) - gap
    local totalH = rows * (iconSize + gap) - gap

    -- For debuffs growing UP: container TOPLEFT is the top-left of the bottom row.
    -- Icon[1] should be centred on the orb, so shift container left by half its width
    -- minus half an icon (so icon[1] centre = frame centre).
    -- growX=LEFT: icon[1] is placed at container RIGHT edge going left →
    --   icon[1] right edge = container TOPLEFT.x + totalW - 0 = container right.
    --   icon[1] centre.x   = container right - iconSize/2
    --   we want icon[1] centre.x = frame centre.x → xOffset = -(totalW - iconSize/2)
    -- growX=RIGHT: icon[1] left = 0 → centre = iconSize/2 → xOffset = -iconSize/2
    -- This is automatically handled by the container anchor xOffset: caller passes 0 for centred.

    container:SetSize(math.max(1, totalW), math.max(1, totalH))
    container:ClearAllPoints()

    if anchorToFrame and frame then
        -- Vertical padding: account for orb/ring extending beyond the frame rect
        local vertExtent = GetFrameVerticalExtent(frame, db)
        local frameH     = (db.frameHeight or 35)
        local pad        = math.max(0, vertExtent - frameH / 2) + extraVertPad + 2

        -- Natural horizontal base for icon[1]:
        --   Orb mode  → icon[1] centred on orb centre → baseX = 0
        --   Bar mode  → icon[1] at the near edge of the health bar:
        --               growX=LEFT  → start at right edge → baseX = +frameWidth/2
        --               growX=RIGHT → start at left edge  → baseX = -frameWidth/2
        local baseX
        if db.sphereMode then
            baseX = 0
        else
            local halfW = (db.frameWidth or 160) / 2
            baseX = (growX == "LEFT") and halfW or -halfW
        end

        -- cxOffset positions the container so icon[1]'s centre lands at baseX + xOffset.
        -- icon[1] centre within container:
        --   growX=LEFT  → icon[1] is the rightmost icon in row 1 → its centre x = totalW - iconSize/2
        --   growX=RIGHT → icon[1] is the leftmost icon           → its centre x = iconSize/2
        -- container TOPLEFT.x = frame_centre.x + (baseX + xOffset) - icon1_centre_in_container
        local icon1CentreInContainer = (growX == "LEFT") and (totalW - iconSize / 2) or (iconSize / 2)
        local cxOffset = baseX + xOffset - icon1CentreInContainer

        if growY == "UP" then
            container:SetPoint("BOTTOM", frame, "TOP", cxOffset, pad + yOffset)
        else
            container:SetPoint("TOP", frame, "BOTTOM", cxOffset, -pad + yOffset)
        end
    else
        container:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
    end

    -- Place icons
    for i = 1, count do
        local aura = auras[i]
        local btn  = GetOrCreateIcon(pool, i, container)
        btn:SetSize(iconSize, iconSize)
        local col  = (i - 1) % cols
        local row  = math.floor((i - 1) / cols)
        local xStep  = (growX == "RIGHT") and  (iconSize + gap) or -(iconSize + gap)
        local yStep  = (growY == "DOWN")  and -(iconSize + gap) or  (iconSize + gap)
        -- startX/startY: position of icon[1] within the container
        local startX = (growX == "RIGHT") and 0 or (totalW - iconSize)
        local startY = (growY == "DOWN")  and 0 or -(totalH - iconSize)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", container, "TOPLEFT", startX + col * xStep, startY + row * yStep)

        btn.auraUnit   = unit
        btn.auraIndex  = i
        btn.auraFilter = auraFilter
        btn.icon:SetTexture(aura.icon)
        -- aura.applications and aura.duration can be secret numbers in 12.0 — comparisons must use pcall.
        local showStack = false
        pcall(function() showStack = aura.applications and aura.applications > 1 end)
        btn.stack:SetText(showStack and aura.applications or "")
        local cdSet = false
        if aura.duration and aura.expirationTime then
            pcall(function()
                if aura.duration > 0 then
                    btn.cd:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                    cdSet = true
                end
            end)
        end
        if not cdSet then btn.cd:SetCooldown(0, 0) end
        local showBorder = false
        pcall(function()
            showBorder = aura.isHarmful and aura.dispelName and DEBUFF_COLORS[aura.dispelName] ~= nil
        end)
        if showBorder then
            local dc = DEBUFF_COLORS[aura.dispelName]
            btn.debuffBorder:SetVertexColor(dc[1], dc[2], dc[3])
            btn.debuffBorder:Show()
        else
            btn.debuffBorder:Hide()
        end
        btn:Show()
    end

    -- Hide unused pool slots
    for i = count + 1, #pool do pool[i]:Hide() end
    container:Show()
end

function UnitFramesLite_UpdateAuras(unit)
    local data = GetAuraData(unit)

    local frame = frames[unit]
    if not frame or not frame:IsShown() then
        data.buff.container:Hide()
        data.debuff.container:Hide()
        return
    end

    local db = GetDB(unit)

    -- Collect buffs
    local buffs = {}
    if db.buffShowBuffs ~= false and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local i = 1
        while true do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
            if not aura then break end
            buffs[#buffs + 1] = aura
            i = i + 1
        end
    end

    -- Collect debuffs
    local debuffs = {}
    if db.debuffShowDebuffs ~= false and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local i = 1
        while true do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
            if not aura then break end
            local fromPlayer = false
            pcall(function() fromPlayer = aura.isFromPlayerOrPlayerPet == true end)
            if db.debuffPlayerOnly and not fromPlayer then
                -- skip
            elseif db.debuffCurableOnly and not (aura.dispelName and DISPEL_TYPES[aura.dispelName]) then
                -- skip
            else
                debuffs[#debuffs + 1] = aura
            end
            i = i + 1
        end
    end

    -- Layout buffs (below frame)
    if db.buffShowBuffs ~= false and #buffs > 0 then
        LayoutAuraStrip(data.buff, buffs, frame, db,
            db.buffIconSize  or 24,
            db.buffPerRow    or 4,
            db.buffMaxShown  or 8,
            db.buffGrowX     or "RIGHT",
            db.buffGrowY     or "DOWN",
            db.buffXOffset   or 0,
            db.buffYOffset   or 0,
            db.buffAnchorToFrame ~= false,
            0, unit, "HELPFUL")
    else
        data.buff.container:Hide()
        for i = 1, #data.buff.pool do data.buff.pool[i]:Hide() end
    end

    -- Layout debuffs (above frame)
    if db.debuffShowDebuffs ~= false and #debuffs > 0 then
        LayoutAuraStrip(data.debuff, debuffs, frame, db,
            db.debuffIconSize  or 24,
            db.debuffPerRow    or 4,
            db.debuffMaxShown  or 8,
            db.debuffGrowX     or "LEFT",
            db.debuffGrowY     or "UP",
            db.debuffXOffset   or 0,
            db.debuffYOffset   or 0,
            db.debuffAnchorToFrame ~= false,
            0, unit, "HARMFUL")
    else
        data.debuff.container:Hide()
        for i = 1, #data.debuff.pool do data.debuff.pool[i]:Hide() end
    end
end

function UnitFramesLite_UpdateAllAuras()
    for unit in pairs(frames) do
        UnitFramesLite_UpdateAuras(unit)
    end
end

function UnitFramesLite_PositionAuraFrame(unit)
    -- Called after the unit frame moves/resizes so auras re-anchor correctly
    UnitFramesLite_UpdateAuras(unit)
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
eventFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
eventFrame:RegisterUnitEvent("UNIT_AURA", "focus")
eventFrame:RegisterUnitEvent("UNIT_AURA", "pet")
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
        -- Migrate: showOrbPower (bool) → orbPowerMode (string)
        -- Migrate: showPowerBar (bool) → orbPowerMode (string)
        -- Runs before CopyDefaults. Also fixes saves where orbPowerMode was wrongly
        -- set to "None" by a previous version that had it in defaults.
        for _, unit in ipairs({"player", "target", "focus", "pet"}) do
            local udb = UnitFramesLiteDB[unit]
            if udb then
                if udb.showOrbPower == true and (udb.orbPowerMode == nil or udb.orbPowerMode == "None") then
                    udb.orbPowerMode = "Ring"
                elseif udb.showPowerBar == true and udb.orbPowerMode == nil then
                    udb.orbPowerMode = "Bar"
                end
            end
        end
        for unit, def in pairs(defaults) do
            UnitFramesLiteDB[unit] = CopyDefaults(def, UnitFramesLiteDB[unit] or {})
        end
        -- Migrate: buffYOffset was previously defaulted to 0; new default is -15
        for _, unit in ipairs({"player", "target"}) do
            local udb = UnitFramesLiteDB[unit]
            if udb and udb.buffYOffset == 0 then udb.buffYOffset = -15 end
        end
        -- Migrate: target buff/debuff X offset was previously 0; new default is 45
        local tudb = UnitFramesLiteDB["target"]
        if tudb then
            if tudb.buffXOffset  == 0 then tudb.buffXOffset  = 45 end
            if tudb.debuffXOffset == 0 then tudb.debuffXOffset = 45 end
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
        -- Initialise aura containers for all units
        for unit in pairs(defaults) do GetAuraContainer(unit) end
        UnitFramesLite_UpdateAllAuras()
        for unit in pairs(defaults) do UnitFramesLite_UpdateAlpha(unit) end
    elseif event == "UNIT_AURA" then
        UnitFramesLite_UpdateAuras(arg1)
    elseif event == "PLAYER_TARGET_CHANGED" then
        UnitFramesLite_UpdateVisibility("target")
        UnitFramesLite_UpdateFrame("target")
        UnitFramesLite_UpdateAlpha("player")
        UnitFramesLite_UpdateAlpha("target")
        UnitFramesLite_UpdateResourceVisibility()
        -- Clear target auras immediately so stale icons from the previous target
        -- don't flash before UNIT_AURA fires with the new target's data.
        local td = auraFrames["target"]
        if td then
            td.buff.container:Hide()
            td.debuff.container:Hide()
            for _, btn in ipairs(td.buff.pool)   do btn:Hide() end
            for _, btn in ipairs(td.debuff.pool) do btn:Hide() end
        end
        UnitFramesLite_UpdateAuras("target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        UnitFramesLite_UpdateVisibility("focus")
        UnitFramesLite_UpdateAlpha("focus")
    elseif event == "UNIT_PET" then
        UnitFramesLite_UpdateVisibility("pet")
        UnitFramesLite_UpdateAlpha("pet")
    elseif event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
        UpdateResourcePips()
    elseif event == "UNIT_DISPLAYPOWER" then
        -- Fires when the player's primary power type changes (e.g. Druid shifting forms).
        -- catFormOnly resources (Druid combo points) should appear/disappear accordingly.
        SetupResourcePips()
        UnitFramesLite_UpdateResourceLayout()
        UpdateResourcePips()
        UnitFramesLite_UpdateResourceVisibility()
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
        UnitFramesLite_UpdateAllAuras()
    end
end)

local vehicleFrame = CreateFrame("Frame")
vehicleFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
vehicleFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE",  "player")
vehicleFrame:SetScript("OnEvent", function()
    for unit in pairs(frames) do UnitFramesLite_UpdateVisibility(unit) end
end)
