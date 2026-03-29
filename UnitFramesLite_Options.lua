local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local function GetFontList()
    if not LSM then return {"Friz Quadrata TT"} end
    local list = LSM:List("font"); table.sort(list); return list
end
local function GetTextureList()
    if not LSM then return {"Blizzard"} end
    local list = LSM:List("statusbar"); table.sort(list); return list
end

-- UI helpers -----------------------------------------------------------------

local function CreateLabel(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function CreateCheckbox(parent, label, x, y, getValue, setValue)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    fs:SetText(label)
    cb:SetChecked(getValue())
    cb:SetScript("OnClick", function(self) setValue(self:GetChecked()) end)
    cb.Refresh = function(self) self:SetChecked(getValue()) end
    return cb
end

local function CreateGroupBox(parent, label, x, y, w, h, titleFont)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    f:SetSize(w, h)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left=3, right=3, top=3, bottom=3},
    })
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.6)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    if label and label ~= "" then
        local lbl = f:CreateFontString(nil, "OVERLAY", titleFont or "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -5)
        lbl:SetText(label)
    end
    return f
end

local function CreateNudgeSlider(parent, label, minV, maxV, step, x, y, sliderW, dbKey, getDB, onChange)
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    lbl:SetText(label)

    local minus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    minus:SetSize(20, 20)
    minus:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 15)
    minus:SetText("-")

    local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 22, y - 13)
    s:SetWidth(sliderW)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s.Text:SetText(""); s.Low:SetText(""); s.High:SetText("")

    local plus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    plus:SetSize(20, 20)
    plus:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 24 + sliderW, y - 15)
    plus:SetText("+")

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(44, 20)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 46 + sliderW, y - 15)
    box:SetAutoFocus(false)

    -- Determine display format from step: step<1 → show 2 decimal places, else integer
    local fmt = (step < 1) and "%.2f" or "%d"
    local function FmtVal(v) return string.format(fmt, v) end

    local updating = false
    local function SetVal(v)
        if updating then return end
        v = math.max(minV, math.min(maxV, math.floor(v / step + 0.5) * step))
        getDB()[dbKey] = v
        updating = true; s:SetValue(v); updating = false
        box:SetText(FmtVal(v))
        onChange()
    end
    s:SetScript("OnValueChanged", function(self, v) if not updating then SetVal(v) end end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus(); local v=tonumber(self:GetText()); if v then SetVal(v) end end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    minus:SetScript("OnClick", function() SetVal((getDB()[dbKey] or 0) - step) end)
    plus:SetScript("OnClick",  function() SetVal((getDB()[dbKey] or 0) + step) end)

    local function Refresh()
        local v = getDB()[dbKey] or 0
        updating = true; s:SetValue(math.max(minV, math.min(maxV, v))); updating = false
        box:SetText(FmtVal(math.max(minV, math.min(maxV, v))))
    end
    Refresh()
    return s, box, Refresh, lbl, minus, plus
end

local function CreateAlphaSliderRow(parent, label, x, y, dbKey, getDB, onChange)
    -- Layout (all on one line):
    --   [label]  [-][  box  ][+]  [====slider====]
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    lbl:SetText(label)

    local minus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    minus:SetSize(22, 22); minus:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 18); minus:SetText("-")

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(45, 20); box:SetPoint("LEFT", minus, "RIGHT", 2, 0); box:SetAutoFocus(false)

    local plus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    plus:SetSize(22, 22); plus:SetPoint("LEFT", box, "RIGHT", 2, 0); plus:SetText("+")

    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("LEFT", plus, "RIGHT", 8, 0)
    slider:SetWidth(120); slider:SetMinMaxValues(0, 1); slider:SetValueStep(0.01)
    slider:SetObeyStepOnDrag(true)
    slider.Text:SetText(""); slider.Low:SetText("0"); slider.High:SetText("1")

    local function SetVal(v)
        v = math.max(0, math.min(1, math.floor(v * 100 + 0.5) / 100))
        getDB()[dbKey] = v; slider:SetValue(v); box:SetText(string.format("%.2f", v)); onChange()
    end
    slider:SetScript("OnValueChanged", function(self, v) SetVal(v) end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus(); local v=tonumber(self:GetText()); if v then SetVal(v) end end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    minus:SetScript("OnClick", function() SetVal(getDB()[dbKey] - 0.05) end)
    plus:SetScript("OnClick",  function() SetVal(getDB()[dbKey] + 0.05) end)

    local function Refresh()
        local v = getDB()[dbKey] or 1.0
        slider:SetValue(v); box:SetText(string.format("%.2f", v))
    end
    Refresh()
    return slider, box, Refresh
end

local function CreateDropdown(parent, x, y, width, items, getValue, setValue)
    if UIDropDownMenu_Initialize then
        local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, y)
        UIDropDownMenu_SetWidth(dd, width)
        local currentItems = items
        UIDropDownMenu_Initialize(dd, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            local cur  = getValue()
            for _, name in ipairs(currentItems) do
                info.text    = name
                info.checked = (name == cur)
                info.func    = function()
                    setValue(name)
                    UIDropDownMenu_SetSelectedName(dd, name)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        local initVal = getValue()
        UIDropDownMenu_SetSelectedName(dd, initVal)
        -- Belt-and-suspenders: also set the button text directly so it shows correctly
        -- before the first OnShow/refresh fires (avoids "Custom" placeholder).
        if dd.Text then dd.Text:SetText(initVal) end
        function dd:SetSelection(name)
            UIDropDownMenu_SetSelectedName(self, name)
            if self.Text then self.Text:SetText(name) end
        end
        function dd:SetOptions(newItems)
            currentItems = newItems
            UIDropDownMenu_Initialize(self, function(self2, level)
                local info = UIDropDownMenu_CreateInfo()
                local cur  = getValue()
                for _, name in ipairs(currentItems) do
                    info.text    = name
                    info.checked = (name == cur)
                    info.func    = function()
                        setValue(name)
                        UIDropDownMenu_SetSelectedName(dd, name)
                        if dd.Text then dd.Text:SetText(name) end
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end)
            -- Force the button text to show the current value immediately
            local curVal = getValue()
            UIDropDownMenu_SetSelectedName(self, curVal)
            if self.Text then self.Text:SetText(curVal) end
        end
        return dd
    end
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width + 24, 22); btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetText(tostring(getValue()))
    local currentItems = items
    btn:SetScript("OnClick", function(self)
        local cur = getValue(); local nxt = currentItems[1]
        for i, v in ipairs(currentItems) do if v == cur then nxt = currentItems[i % #currentItems + 1]; break end end
        setValue(nxt); self:SetText(tostring(nxt))
    end)
    function btn:SetSelection(name) self:SetText(tostring(name)) end
    function btn:SetOptions(newItems) currentItems = newItems end
    return btn
end

-- Inline colour swatch: a small clickable coloured square with a label to its right.
-- Returns the swatch frame; call :RefreshSwatch() to sync the colour display.
local function CreateColorSwatch(parent, x, y, label, getDB, key, callback)
    -- Outer frame acts as the clickable button (20×20)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(20, 20)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    -- Dark border background
    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0.1, 0.1, 0.1, 1)

    -- Colour fill (1px inset)
    local fill = btn:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    fill:SetColorTexture(1, 1, 1, 1)

    -- Label to the right, parented to btn so it hides/shows with it
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", btn, "RIGHT", 6, 0)
    fs:SetText(label)

    local function RefreshSwatch()
        local c = getDB()[key] or {1,1,1,1}
        fill:SetColorTexture(c[1], c[2], c[3], 1)
    end
    RefreshSwatch()
    btn.RefreshSwatch = RefreshSwatch

    btn:SetScript("OnClick", function()
        local db = getDB(); local r,g,b,a = unpack(db[key] or {1,1,1,1})
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc  = function() local nr,ng,nb=ColorPickerFrame:GetColorRGB(); local na=ColorPickerFrame:GetColorAlpha(); getDB()[key]={nr,ng,nb,na}; RefreshSwatch(); callback() end,
                opacityFunc = function() local nr,ng,nb=ColorPickerFrame:GetColorRGB(); local na=ColorPickerFrame:GetColorAlpha(); getDB()[key]={nr,ng,nb,na}; RefreshSwatch(); callback() end,
                cancelFunc  = function(prev) getDB()[key]={prev and prev.r or r, prev and prev.g or g, prev and prev.b or b, prev and prev.opacity or a}; RefreshSwatch(); callback() end,
                hasOpacity=true, opacity=a, r=r, g=g, b=b,
            })
        else
            ColorPickerFrame.hasOpacity=true; ColorPickerFrame.opacity=1-a
            ColorPickerFrame.previousValues={r,g,b,a}
            ColorPickerFrame.func=function() local nr,ng,nb=ColorPickerFrame:GetColorRGB(); local na=1-OpacitySliderFrame:GetValue(); getDB()[key]={nr,ng,nb,na}; RefreshSwatch(); callback() end
            ColorPickerFrame.cancelFunc=function(prev) getDB()[key]=prev or {r,g,b,a}; RefreshSwatch(); callback() end
            ColorPickerFrame:SetColorRGB(r,g,b); ColorPickerFrame:Show()
        end
    end)
    return btn
end

local function DeepCopyDB(src)
    local t = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            t[k] = {}; for i,c in ipairs(v) do t[k][i] = c end
        else t[k] = v end
    end
    return t
end

-- Options lists --------------------------------------------------------------

local alignOptions        = {"LEFT", "CENTER", "RIGHT"}
local dirOptions          = {"HORIZONTAL", "VERTICAL"}
local portraitOptions     = {"Portrait Off", "Portrait Left", "Portrait Right"}  -- legacy
local portraitModeOptions = {"None", "2D", "3D", "Unit Type"}
local portraitSideOptions = {"Left", "Right"}
local alphaAffectsOptions = {"Everything", "Foreground", "Background"}
local hpContentOptions    = {"Cur / Max", "Current", "Max"}
local hpFormatOptions     = {"Full", "Short"}
local fillDirOptions      = {"VERTICAL", "HORIZONTAL"}

-- Tab 1: General -------------------------------------------------------------

local function BuildGeneralContent(content, unit, getDB, panel)
    local x = 16
    local halfW = math.floor(UIParent:GetWidth()  / 2)
    local halfH = math.floor(UIParent:GetHeight() / 2)
    local gx = 8; local s, b, r

    -- Left column (x=16): Enable, Lock, Copy Settings, Blizzard frames --------
    CreateLabel(content, "Frame Basics", x, -8)
    panel.enabledCheck = CreateCheckbox(content, "Enable this frame", x, -28,
        function() return getDB().enabled ~= false end,
        function(v) getDB().enabled = v; UnitFramesLite_UpdateFrame(unit) end)
    panel.lockedCheck = CreateCheckbox(content, "Lock frame (disable dragging)", x, -56,
        function() return getDB().locked or false end,
        function(v) getDB().locked = v end)

    -- These are referenced by panel:refresh() so we still create them, just hidden/stubs
    -- Position, size, reverseFill, portrait are now on the Bar and Orb tabs.
    -- We keep the slider references so panel:refresh() doesn't error.
    panel.reverseFillCheck = CreateCheckbox(content, "", -9999, -9999,
        function() return getDB().reverseFill or false end,
        function(v) getDB().reverseFill = v; UnitFramesLite_UpdateFrame(unit) end)
    local posGroup = CreateFrame("Frame", nil, content)
    s,b,r = CreateNudgeSlider(posGroup,"X",-halfW,halfW,1, 0,0,100,"x",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.xSlider,panel.xBox,panel.xRefresh = s,b,r
    s,b,r = CreateNudgeSlider(posGroup,"Y",-halfH,halfH,1, 0,-40,100,"y",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.ySlider,panel.yBox,panel.yRefresh = s,b,r
    local sizeGroup = CreateFrame("Frame", nil, content)
    s,b,r = CreateNudgeSlider(sizeGroup,"W",60,500,1, 0,0,100,"frameWidth",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.widthSlider,panel.widthBox,panel.widthRefresh = s,b,r
    s,b,r = CreateNudgeSlider(sizeGroup,"H",12,120,1, 0,-40,100,"frameHeight",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.heightSlider,panel.heightBox,panel.heightRefresh = s,b,r
    panel.portraitDD = CreateDropdown(content, -9999, 0, 80, portraitOptions,
        function() return getDB().portrait or "Portrait Off" end,
        function(v) getDB().portrait = v end)
    posGroup:Hide(); sizeGroup:Hide()

    -- Copy settings
    local copyGroup = CreateGroupBox(content, "Copy Settings", x, -80, 320, 60)
    local unitLabels = {player="Player", target="Target", focus="Focus", pet="Pet"}
    local others = {}
    for u in pairs(unitLabels) do if u ~= unit then others[#others+1] = u end end
    table.sort(others)

    -- Default copy target: prefer "target", fall back to first in sorted list
    local copyTargetUnit = (unit ~= "target" and "target") or others[1]
    local copyUnitLabels = {}
    for _, u in ipairs(others) do copyUnitLabels[#copyUnitLabels+1] = unitLabels[u] or u end

    local copyToBtn = CreateFrame("Button", nil, copyGroup, "UIPanelButtonTemplate")
    copyToBtn:SetSize(120, 22)
    copyToBtn:SetPoint("TOPLEFT", copyGroup, "TOPLEFT", 8, -30)
    copyToBtn:SetText("Copy to " .. (unitLabels[copyTargetUnit] or copyTargetUnit))

    local copyUnitDD = CreateDropdown(copyGroup, 140, -22, 120, copyUnitLabels,
        function() return unitLabels[copyTargetUnit] or copyTargetUnit end,
        function(v)
            for u, lbl in pairs(unitLabels) do
                if lbl == v then copyTargetUnit = u; break end
            end
            copyToBtn:SetText("Copy to " .. v)
        end)

    copyToBtn:SetScript("OnClick", function()
        -- Mirror X positions when copying player↔target
        local mirror = (unit == "player" and copyTargetUnit == "target")
                    or (unit == "target" and copyTargetUnit == "player")
        if UnitFramesLite_CopyUnit then
            UnitFramesLite_CopyUnit(unit, copyTargetUnit, mirror)
        end
    end)

    -- Left column continued: Blizzard Unit Frames (player-only) ---------------
    if unit == "player" then
        local blizzGroup = CreateGroupBox(content, "Blizzard Unit Frames", x, -152, 320, 140)
        local function getGlobal() return UnitFramesLiteDB and UnitFramesLiteDB.global or {} end
        local blizzDefs = {
            {"Hide Blizzard Player Frame", "hideBlizzPlayer"},
            {"Hide Blizzard Target Frame", "hideBlizzTarget"},
            {"Hide Blizzard Focus Frame",  "hideBlizzFocus"},
            {"Hide Blizzard Pet Frame",    "hideBlizzPet"},
        }
        for i, def in ipairs(blizzDefs) do
            local label, key = def[1], def[2]
            CreateCheckbox(blizzGroup, label, 8, -16 - (i-1)*24,
                function() return getGlobal()[key] or false end,
                function(v)
                    getGlobal()[key] = v
                    if UnitFramesLite_ApplyBlizzardFrames then
                        UnitFramesLite_ApplyBlizzardFrames()
                    end
                end)
        end
        local note = blizzGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        note:SetPoint("BOTTOMLEFT", blizzGroup, "BOTTOMLEFT", 8, 10)
        note:SetText("|cffaaaaaa/reload to restore hidden Blizzard frames|r")

    end
end

-- Tab 6: Class Resources (player-only) ----------------------------------------

local function BuildClassResourcesContent(content, unit, getDB, panel)
    if unit ~= "player" then return end

    local function resDB() return UnitFramesLite_GetDB("player") end
    local function applyRes()
        if UnitFramesLite_UpdateResourceLayout then UnitFramesLite_UpdateResourceLayout() end
        if UnitFramesLite_UpdateResourceVisibility then UnitFramesLite_UpdateResourceVisibility() end
    end

    local x  = 16  -- left column x
    local rx = 266 -- right column x (pips panel)

    -- ── Visibility ────────────────────────────────────────────────────────────
    CreateLabel(content, "Visibility", x, -8)
    CreateCheckbox(content, "Show resource bar", x, -26,
        function() return resDB().showResources ~= false end,
        function(v) resDB().showResources = v; applyRes() end)

    -- Forward-declare so showOutCombatCB's closure can reference both
    local showWithTargetCB
    local showWithTargetLabel

    local function setShowWithTargetVisible(shown)
        if showWithTargetCB    then showWithTargetCB:SetShown(shown) end
        if showWithTargetLabel then showWithTargetLabel:SetShown(shown) end
    end

    -- When unticked, bar only shows in combat
    local showOutCombatCB = CreateCheckbox(content, "Show out of combat", x, -52,
        function() return resDB().resourceShowOutCombat ~= false end,
        function(v)
            resDB().resourceShowOutCombat = v
            setShowWithTargetVisible(not v)
            applyRes()
        end)

    -- Built manually so we can hide the label independently
    do
        local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", content, "TOPLEFT", x, -78)
        local fs = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        fs:SetText("Show when target selected")
        cb:SetChecked(resDB().resourceShowWithTarget or false)
        cb:SetScript("OnClick", function(self)
            resDB().resourceShowWithTarget = self:GetChecked()
            applyRes()
        end)
        cb.Refresh = function(self) self:SetChecked(resDB().resourceShowWithTarget or false) end
        showWithTargetCB    = cb
        showWithTargetLabel = fs
    end

    -- ── Alpha ─────────────────────────────────────────────────────────────────
    local sep1 = content:CreateTexture(nil,"ARTWORK"); sep1:SetColorTexture(0.3,0.3,0.3,0.8); sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT",content,"TOPLEFT",x,-104); sep1:SetSize(230,1)
    local _,_,rAlpha = CreateNudgeSlider(content,"Alpha",0,1,0.01, x,-114,120,"resourceAlpha",resDB,applyRes)

    -- ── Position ──────────────────────────────────────────────────────────────
    local sep2 = content:CreateTexture(nil,"ARTWORK"); sep2:SetColorTexture(0.3,0.3,0.3,0.8); sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",content,"TOPLEFT",x,-150); sep2:SetSize(230,1)
    CreateLabel(content, "Position", x, -160)
    local _,_,rResX = CreateNudgeSlider(content,"X Offset",-1000,1000,1, x,-180,120,"resourceX",resDB,applyRes)
    local _,_,rResY = CreateNudgeSlider(content,"Y Offset", -600, 600,1, x,-220,120,"resourceY",resDB,applyRes)

    -- ── Vertical separator between left and right columns ─────────────────────
    local vsep = content:CreateTexture(nil,"ARTWORK"); vsep:SetColorTexture(0.3,0.3,0.3,0.8); vsep:SetWidth(1)
    vsep:SetPoint("TOPLEFT",  content,"TOPLEFT",  rx - 10, -8)
    vsep:SetPoint("BOTTOMLEFT",content,"BOTTOMLEFT",rx - 10,  0)

    -- ── RIGHT: UFL Pips Size, Position & Shape ────────────────────────────────
    local px = rx
    local UpdatePipSizeControls  -- forward declaration
    CreateLabel(content, "UFL Pips Size & Position", px, -8)

    -- Width+Height sliders (shown for Rectangle and Diamond)
    local sliderW, sliderWBox, rPipW, sliderWLabel, sliderWMinus, sliderWPlus =
        CreateNudgeSlider(content,"Pip Width",  6,50,1, px,-28, 80,"resourcePipWidth",  resDB,applyRes)
    local sliderH, sliderHBox, rPipH, sliderHLabel, sliderHMinus, sliderHPlus =
        CreateNudgeSlider(content,"Pip Height", 3,50,1, px,-68, 80,"resourcePipHeight", resDB,applyRes)

    -- Size slider (shown for Circle — keeps width=height so circle stays round)
    local sliderS, sliderSBox, _, sliderSLabel, sliderSMinus, sliderSPlus =
        CreateNudgeSlider(content,"Pip Size", 3,50,1, px,-28, 80,"resourcePipWidth", resDB,
        function()
            local db = resDB()
            db.resourcePipHeight = db.resourcePipWidth
            if rPipH then rPipH() end
            applyRes()
        end)

    local _,_,rPipGap = CreateNudgeSlider(content,"Pip Gap", 0,50,1, px,-108,80,"resourcePipGap", resDB,applyRes)
    CreateLabel(content, "Pip Shape", px, -148)
    local shapeDD = CreateDropdown(content, px, -166, 110, {"Rectangle","Circle","Diamond"},
        function() return resDB().resourcePipShape or "Rectangle" end,
        function(v)
            resDB().resourcePipShape = v
            if v == "Circle" then
                local db = resDB()
                db.resourcePipHeight = db.resourcePipWidth
                if rPipH then rPipH() end
            end
            UpdatePipSizeControls()
            applyRes()
        end)

    -- Show/hide width+height vs size depending on shape
    local function setWHShown(shown)
        sliderWLabel:SetShown(shown); sliderW:SetShown(shown); sliderWBox:SetShown(shown)
        sliderWMinus:SetShown(shown); sliderWPlus:SetShown(shown)
        sliderHLabel:SetShown(shown); sliderH:SetShown(shown); sliderHBox:SetShown(shown)
        sliderHMinus:SetShown(shown); sliderHPlus:SetShown(shown)
    end
    local function setSShown(shown)
        sliderSLabel:SetShown(shown); sliderS:SetShown(shown); sliderSBox:SetShown(shown)
        sliderSMinus:SetShown(shown); sliderSPlus:SetShown(shown)
    end
    UpdatePipSizeControls = function()
        local isCircle = (resDB().resourcePipShape or "Rectangle") == "Circle"
        setWHShown(not isCircle)
        setSShown(isCircle)
    end
    UpdatePipSizeControls()

    -- ── Bottom section: Pip Colour (left) + Pip Border (right) side by side ──
    local sep3 = content:CreateTexture(nil,"ARTWORK"); sep3:SetColorTexture(0.3,0.3,0.3,0.8); sep3:SetHeight(1)
    sep3:SetPoint("TOPLEFT",content,"TOPLEFT",x,-260); sep3:SetPoint("TOPRIGHT",content,"TOPRIGHT",-8,-260)

    -- Left: Pip Colour ─────────────────────────────────────────────────────────
    CreateLabel(content, "Pip Colour", x, -270)

    local colorDetails
    local useCustomCheck = CreateCheckbox(content, "Use Custom Colour", x, -288,
        function() return resDB().resourceUseCustomColor or false end,
        function(v) resDB().resourceUseCustomColor = v; colorDetails:SetShown(v); applyRes() end)

    colorDetails = CreateFrame("Frame", nil, content)
    colorDetails:SetPoint("TOPLEFT", content, "TOPLEFT", x, -312)
    colorDetails:SetSize(240, 70)

    local COLOR_MODES = {"Solid", "Horizontal Gradient", "Vertical Gradient"}
    local function getColorMode()
        local m = resDB().resourceColorMode
        if m == "Gradient" then m = "Horizontal Gradient" end  -- migrate old value
        if m and m ~= "" then return m end
        return (resDB().resourceUseSolidColor ~= false) and "Solid" or "Horizontal Gradient"
    end

    -- Dropdown width=130; UIDropDownMenuTemplate rendered right edge ≈ x + 146 (130+32-16).
    -- Swatches start at x+154 to give an 8px gap.
    local colorModeDD = CreateDropdown(colorDetails, 0, -4, 130, COLOR_MODES,
        getColorMode,
        function(v)
            resDB().resourceColorMode = v
            resDB().resourceUseSolidColor = (v == "Solid")
            colorDetails:UpdateColourMode()
            applyRes()
        end)

    local solidSwatch     = CreateColorSwatch(colorDetails, 154, -10, "", resDB, "resourceSolidColor", applyRes)
    local gradStartSwatch = CreateColorSwatch(colorDetails, 154, -10, "", resDB, "resourceGradStart",  applyRes)
    local gradEndSwatch   = CreateColorSwatch(colorDetails, 178, -10, "", resDB, "resourceGradEnd",    applyRes)

    local gradPerPipCB, gradPerPipLabel
    do
        local cb = CreateFrame("CheckButton", nil, colorDetails, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", colorDetails, "TOPLEFT", 0, -32)
        local fs = colorDetails:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        fs:SetText("Colour each pip individually")
        cb:SetChecked(resDB().resourceGradPerPip ~= false)
        cb:SetScript("OnClick", function(self)
            resDB().resourceGradPerPip = self:GetChecked()
            applyRes()
        end)
        cb.Refresh = function(self) self:SetChecked(resDB().resourceGradPerPip ~= false) end
        gradPerPipCB    = cb
        gradPerPipLabel = fs
    end

    colorDetails.UpdateColourMode = function(self)
        local mode = getColorMode()
        local isSolid    = (mode == "Solid")
        local isVertical = (mode == "Vertical Gradient")
        solidSwatch:SetShown(isSolid)
        gradStartSwatch:SetShown(not isSolid)
        gradEndSwatch:SetShown(not isSolid)
        local showPerPip = not isSolid and not isVertical
        gradPerPipCB:SetShown(showPerPip)
        gradPerPipLabel:SetShown(showPerPip)
        colorModeDD:SetSelection(mode)
    end

    colorDetails:SetShown(resDB().resourceUseCustomColor or false)
    colorDetails:UpdateColourMode()

    useCustomCheck.Refresh = function(self)
        local v = resDB().resourceUseCustomColor or false
        self:SetChecked(v); colorDetails:SetShown(v)
    end

    -- Right: Pip Border ────────────────────────────────────────────────────────
    local bx = rx   -- right column, same x as Pip Size section above
    CreateLabel(content, "Pip Border", bx, -270)

    -- Thickness slider (hidden until Enabled is ticked)
    local borderDetails = CreateFrame("Frame", nil, content)
    borderDetails:SetPoint("TOPLEFT", content, "TOPLEFT", bx, -314)
    borderDetails:SetSize(220, 36)
    local _,_,rBorderThick = CreateNudgeSlider(borderDetails, "Thickness", 1, 10, 1, 0, -4, 100,
        "resourcePipBorderThickness", resDB, applyRes)

    -- "Enabled" checkbox with colour swatch inline to its right.
    -- Checkbox (24px) + "Enabled" label (~50px) + gap → swatch label at bx+88, swatch at bx+128.
    local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", content, "TOPLEFT", bx, -288)
    local enabledLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    enabledLabel:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    enabledLabel:SetText("Enabled")
    cb:SetChecked(resDB().resourcePipBorderEnabled or false)
    -- Colour label + swatch anchored to the checkbox so they share the same vertical centre.
    -- "Enabled" label ends ~74px from cb's left; leave 10px gap before "Colour".
    local colLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colLabel:SetPoint("LEFT", cb, "RIGHT", 74, 0)
    colLabel:SetText("Colour")
    -- CreateColorSwatch anchors to parent via TOPLEFT; re-anchor immediately after creation.
    local borderSwatch = CreateColorSwatch(content, 0, 0, "", resDB, "resourcePipBorderColor", applyRes)
    borderSwatch:ClearAllPoints()
    borderSwatch:SetPoint("LEFT", colLabel, "RIGHT", 6, 0)

    local function SetBorderShown(v)
        borderDetails:SetShown(v)
        colLabel:SetShown(v)
        borderSwatch:SetShown(v)
    end

    cb:SetScript("OnClick", function(self)
        local v = self:GetChecked()
        resDB().resourcePipBorderEnabled = v
        SetBorderShown(v)
        applyRes()
    end)
    cb.Refresh = function(self)
        local v = resDB().resourcePipBorderEnabled or false
        self:SetChecked(v)
        SetBorderShown(v)
    end

    SetBorderShown(resDB().resourcePipBorderEnabled or false)

    -- Apply initial visibility of "show when target" based on "show out of combat"
    setShowWithTargetVisible(not (resDB().resourceShowOutCombat ~= false))
end

-- Tab 2: Text ----------------------------------------------------------------

local function BuildTextContent(content, unit, getDB, panel)
    local s, b, r
    local COL_W = 220
    local c1 = 6
    local c2 = c1 + COL_W + 6
    local c3 = c2 + COL_W + 6
    local c4 = c3 + COL_W + 6

    -- Global default font (fallback when per-section font is nil)
    CreateLabel(content, "Default Font", c1, -8)
    panel.fontDD = CreateDropdown(content, c1, -26, 200, GetFontList(),
        function() return getDB().font or "Friz Quadrata TT" end,
        function(v) getDB().font = v; UnitFramesLite_UpdateFrame(unit) end)

    -- Colour swatch helper (parent-aware, no label — used inside group boxes)
    local function ColSwatch(parent, x, y, colorKey, labelText)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(20, 20)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        local border = btn:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints(); border:SetColorTexture(0.1, 0.1, 0.1, 1)
        local fill = btn:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
        fill:SetColorTexture(1, 1, 1, 1)
        if labelText then
            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetPoint("LEFT", btn, "RIGHT", 6, 0)
            fs:SetText(labelText)
        end
        local function Refresh()
            local c = getDB()[colorKey] or {1,1,1,1}; fill:SetColorTexture(c[1],c[2],c[3],1)
        end
        Refresh(); btn.RefreshSwatch = Refresh
        btn:SetScript("OnClick", function()
            local db = getDB(); local r,g,b,a = unpack(db[colorKey] or {1,1,1,1})
            if ColorPickerFrame.SetupColorPickerAndShow then
                ColorPickerFrame:SetupColorPickerAndShow({
                    swatchFunc  = function() local nr,ng,nb=ColorPickerFrame:GetColorRGB(); local na=ColorPickerFrame:GetColorAlpha(); db[colorKey]={nr,ng,nb,na}; Refresh(); UnitFramesLite_UpdateFrame(unit) end,
                    opacityFunc = function() local nr,ng,nb=ColorPickerFrame:GetColorRGB(); local na=ColorPickerFrame:GetColorAlpha(); db[colorKey]={nr,ng,nb,na}; Refresh(); UnitFramesLite_UpdateFrame(unit) end,
                    cancelFunc  = function(prev) db[colorKey]={prev and prev.r or r,prev and prev.g or g,prev and prev.b or b,prev and prev.opacity or a}; Refresh(); UnitFramesLite_UpdateFrame(unit) end,
                    hasOpacity=true, opacity=a, r=r, g=g, b=b,
                })
            else
                ColorPickerFrame.hasOpacity=true; ColorPickerFrame.opacity=1-a
                ColorPickerFrame.previousValues={r,g,b,a}
                ColorPickerFrame.func=function() local nr,ng,nb=ColorPickerFrame:GetColorRGB(); local na=1-OpacitySliderFrame:GetValue(); db[colorKey]={nr,ng,nb,na}; Refresh(); UnitFramesLite_UpdateFrame(unit) end
                ColorPickerFrame.cancelFunc=function(prev) db[colorKey]=prev or {r,g,b,a}; Refresh(); UnitFramesLite_UpdateFrame(unit) end
                ColorPickerFrame:SetColorRGB(r,g,b); ColorPickerFrame:Show()
            end
        end)
        panel.swatchButtons[#panel.swatchButtons+1] = btn
        return btn
    end

    -- Inside each group box:
    --   y=-24: Show checkbox (below the group box title at y=-5)
    --   y=-50: Colour swatch
    --   y=-76: Collapsible container (font/align/position controls)
    local GX      = 4    -- x padding inside group box
    local CTR_TOP = -96  -- collapsible container top inside group box

    -- ── Column 1: Name Text ──────────────────────────────────────────────────
    local nameBox = CreateGroupBox(content, "Name Text", c1, -50, COL_W, 310)
    local nameCtr  -- forward declaration so checkbox closure can reference it
    local function NameShown() return getDB().showName ~= false end
    panel.showNameCheck = CreateCheckbox(nameBox, "Show", GX, -24, NameShown,
        function(v) getDB().showName = v; nameCtr:SetShown(NameShown()); UnitFramesLite_UpdateFrame(unit) end)
    panel.showNameCheck.Refresh = function(self)
        self:SetChecked(NameShown()); nameCtr:SetShown(NameShown())
    end
    ColSwatch(nameBox, GX, -54, "nameColor", "Name Colour")

    nameCtr = CreateFrame("Frame", nil, nameBox)
    nameCtr:SetPoint("TOPLEFT", nameBox, "TOPLEFT", GX, CTR_TOP)
    nameCtr:SetSize(COL_W - GX * 2, 220)

    CreateLabel(nameCtr, "Font",  0, -10)
    panel.nameFontDD = CreateDropdown(nameCtr, 44, -8, 120, GetFontList(),
        function() return getDB().nameFont or getDB().font or "Friz Quadrata TT" end,
        function(v) getDB().nameFont = v; UnitFramesLite_UpdateFrame(unit) end)
    CreateLabel(nameCtr, "Align", 0, -40)
    panel.nameAlignDD = CreateDropdown(nameCtr, 44, -38, 100, alignOptions,
        function() return getDB().nameAlign or "LEFT" end,
        function(v) getDB().nameAlign = v; UnitFramesLite_UpdateFrame(unit) end)
    s,b,r = CreateNudgeSlider(nameCtr,"Size",6,36,1, 0,-70,60,"nameTextFontSize",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.nameFontSizeSlider, panel.nameFontSizeBox, panel.nameFontSizeRefresh = s,b,r
    s,b,r = CreateNudgeSlider(nameCtr,"X Off",-500,500,1, 0,-110,60,"nameTextX",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.nameXSlider, panel.nameXBox, panel.nameXRefresh = s,b,r
    s,b,r = CreateNudgeSlider(nameCtr,"Y Off",-500,500,1, 0,-150,60,"nameTextY",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.nameYSlider, panel.nameYBox, panel.nameYRefresh = s,b,r
    nameCtr:SetShown(NameShown())

    -- ── Column 2: HP Text ────────────────────────────────────────────────────
    local hpTextBox = CreateGroupBox(content, "HP Text", c2, -50, COL_W, 420)
    local hpTextCtr
    local function HPTextShown() return getDB().showHPText ~= false end
    panel.showHPTextCheck = CreateCheckbox(hpTextBox, "Show", GX, -24, HPTextShown,
        function(v) getDB().showHPText = v; hpTextCtr:SetShown(HPTextShown()); UnitFramesLite_UpdateFrame(unit) end)
    panel.showHPTextCheck.Refresh = function(self)
        self:SetChecked(HPTextShown()); hpTextCtr:SetShown(HPTextShown())
    end
    ColSwatch(hpTextBox, GX, -54, "hpTextColor", "Text Colour")

    hpTextCtr = CreateFrame("Frame", nil, hpTextBox)
    hpTextCtr:SetPoint("TOPLEFT", hpTextBox, "TOPLEFT", GX, CTR_TOP)
    hpTextCtr:SetSize(COL_W - GX * 2, 320)

    CreateLabel(hpTextCtr, "Font",    0, -10)
    panel.hpTextFontDD = CreateDropdown(hpTextCtr, 44, -8, 120, GetFontList(),
        function() return getDB().hpTextFont or getDB().font or "Friz Quadrata TT" end,
        function(v) getDB().hpTextFont = v; UnitFramesLite_UpdateFrame(unit) end)
    CreateLabel(hpTextCtr, "Align",   0, -40)
    panel.hpTextAlignDD = CreateDropdown(hpTextCtr, 44, -38, 100, alignOptions,
        function() return getDB().hpTextAlign or "CENTER" end,
        function(v) getDB().hpTextAlign = v; UnitFramesLite_UpdateFrame(unit) end)
    s,b,r = CreateNudgeSlider(hpTextCtr,"Size",6,36,1, 0,-70,60,"hpTextFontSize",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.hpFontSizeSlider, panel.hpFontSizeBox, panel.hpFontSizeRefresh = s,b,r
    s,b,r = CreateNudgeSlider(hpTextCtr,"X Off",-500,500,1, 0,-110,60,"hpTextX",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.hpXSlider, panel.hpXBox, panel.hpXRefresh = s,b,r
    s,b,r = CreateNudgeSlider(hpTextCtr,"Y Off",-500,500,1, 0,-150,60,"hpTextY",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.hpYSlider, panel.hpYBox, panel.hpYRefresh = s,b,r
    CreateLabel(hpTextCtr, "Content", 0, -190)
    panel.hpContentDD = CreateDropdown(hpTextCtr, 60, -188, 100, hpContentOptions,
        function() return getDB().hpContent or "Cur / Max" end,
        function(v) getDB().hpContent = v; UnitFramesLite_UpdateFrame(unit) end)
    CreateLabel(hpTextCtr, "Format",  0, -220)
    panel.hpFormatDD = CreateDropdown(hpTextCtr, 60, -218, 100, hpFormatOptions,
        function() return getDB().hpFormat or "Full" end,
        function(v) getDB().hpFormat = v; UnitFramesLite_UpdateFrame(unit) end)
    hpTextCtr:SetShown(HPTextShown())

    -- ── Column 3: HP Percent ─────────────────────────────────────────────────
    local hpPctBox = CreateGroupBox(content, "HP Percent", c3, -50, COL_W, 330)
    local hpPctCtr
    local function HPPctShown() return getDB().showHPPct or false end
    panel.showHPPctCheck = CreateCheckbox(hpPctBox, "Show", GX, -24, HPPctShown,
        function(v) getDB().showHPPct = v; hpPctCtr:SetShown(HPPctShown()); UnitFramesLite_UpdateFrame(unit) end)
    panel.showHPPctCheck.Refresh = function(self)
        self:SetChecked(HPPctShown()); hpPctCtr:SetShown(HPPctShown())
    end
    ColSwatch(hpPctBox, GX, -54, "hpPctColor", "Text Colour")

    hpPctCtr = CreateFrame("Frame", nil, hpPctBox)
    hpPctCtr:SetPoint("TOPLEFT", hpPctBox, "TOPLEFT", GX, CTR_TOP)
    hpPctCtr:SetSize(COL_W - GX * 2, 230)

    CreateLabel(hpPctCtr, "Font",  0, -10)
    panel.hpPctFontDD = CreateDropdown(hpPctCtr, 44, -8, 120, GetFontList(),
        function() return getDB().hpPctFont or getDB().font or "Friz Quadrata TT" end,
        function(v) getDB().hpPctFont = v; UnitFramesLite_UpdateFrame(unit) end)
    CreateLabel(hpPctCtr, "Align", 0, -40)
    panel.hpPctAlignDD = CreateDropdown(hpPctCtr, 44, -38, 100, alignOptions,
        function() return getDB().hpPctAlign or "CENTER" end,
        function(v) getDB().hpPctAlign = v; UnitFramesLite_UpdateFrame(unit) end)
    s,b,r = CreateNudgeSlider(hpPctCtr,"Size",6,36,1, 0,-70,60,"hpPctFontSize",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.hpPctFontSizeSlider, panel.hpPctFontSizeBox, panel.hpPctFontSizeRefresh = s,b,r
    s,b,r = CreateNudgeSlider(hpPctCtr,"X Off",-500,500,1, 0,-110,60,"hpPctX",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.hpPctXSlider, panel.hpPctXBox, panel.hpPctXRefresh = s,b,r
    s,b,r = CreateNudgeSlider(hpPctCtr,"Y Off",-500,500,1, 0,-150,60,"hpPctY",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.hpPctYSlider, panel.hpPctYBox, panel.hpPctYRefresh = s,b,r
    panel.hpPctSymbolCheck = CreateCheckbox(hpPctCtr, "Show %", 0, -190,
        function() return getDB().hpPctShowSymbol ~= false end,
        function(v) getDB().hpPctShowSymbol = v; UnitFramesLite_UpdateFrame(unit) end)
    hpPctCtr:SetShown(HPPctShown())

    -- ── Column 4: Level Text ─────────────────────────────────────────────────
    local levelBox = CreateGroupBox(content, "Level Text", c4, -50, COL_W, 310)
    local levelCtr
    local function LevelShown() return getDB().showLevel ~= false end
    panel.showLevelCheck = CreateCheckbox(levelBox, "Show", GX, -24, LevelShown,
        function(v) getDB().showLevel = v; levelCtr:SetShown(LevelShown()); UnitFramesLite_UpdateFrame(unit) end)
    panel.showLevelCheck.Refresh = function(self)
        self:SetChecked(LevelShown()); levelCtr:SetShown(LevelShown())
    end
    ColSwatch(levelBox, GX, -54, "levelColor", "Text Colour")

    levelCtr = CreateFrame("Frame", nil, levelBox)
    levelCtr:SetPoint("TOPLEFT", levelBox, "TOPLEFT", GX, CTR_TOP)
    levelCtr:SetSize(COL_W - GX * 2, 220)

    CreateLabel(levelCtr, "Font",  0, -10)
    panel.levelFontDD = CreateDropdown(levelCtr, 44, -8, 120, GetFontList(),
        function() return getDB().levelFont or getDB().font or "Friz Quadrata TT" end,
        function(v) getDB().levelFont = v; UnitFramesLite_UpdateFrame(unit) end)
    CreateLabel(levelCtr, "Align", 0, -40)
    panel.levelTextAlignDD = CreateDropdown(levelCtr, 44, -38, 100, alignOptions,
        function() return getDB().levelTextAlign or "CENTER" end,
        function(v) getDB().levelTextAlign = v; UnitFramesLite_UpdateFrame(unit) end)
    s,b,r = CreateNudgeSlider(levelCtr,"Size",6,36,1, 0,-70,60,"levelTextFontSize",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.levelFontSizeSlider, panel.levelFontSizeBox, panel.levelFontSizeRefresh = s,b,r
    s,b,r = CreateNudgeSlider(levelCtr,"X Off",-500,500,1, 0,-110,60,"levelTextX",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.levelXSlider, panel.levelXBox, panel.levelXRefresh = s,b,r
    s,b,r = CreateNudgeSlider(levelCtr,"Y Off",-500,500,1, 0,-150,60,"levelTextY",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.levelYSlider, panel.levelYBox, panel.levelYRefresh = s,b,r
    levelCtr:SetShown(LevelShown())
end

-- Tab 3: Appearance (Bar + Orb unified) -------------------------------------

local function BuildAppearanceContent(content, unit, getDB, panel)
    local x = 16; local s, b, r
    local halfW = math.floor(UIParent:GetWidth()  / 2)
    local halfH = math.floor(UIParent:GetHeight() / 2)
    local gx = 8
    local rx = 320   -- right column x

    -- ── Frame Style selector (top, full width) ──────────────────────────────
    CreateLabel(content, "Frame Style", x, -8)
    panel.frameStyleDD = CreateDropdown(content, x + 90, -6, 100, {"Bar", "Orb"},
        function() return (getDB().sphereMode and "Orb") or "Bar" end,
        function(v)
            getDB().sphereMode = (v == "Orb")
            UnitFramesLite_UpdateFrame(unit)
            panel:UpdateAppearanceMode()
        end)

    -- ── Shared: Reverse Fill (above Position) ───────────────────────────────
    panel.reverseFillCheck = CreateCheckbox(content, "Reverse fill (HP/Power)", x, -40,
        function() return getDB().reverseFill or false end,
        function(v) getDB().reverseFill = v; UnitFramesLite_UpdateFrame(unit) end)

    -- ── Shared: Position ────────────────────────────────────────────────────
    local posGroup = CreateGroupBox(content, "Position", x, -66, 290, 102, "GameFontNormal")
    s,b,r = CreateNudgeSlider(posGroup,"X Offset",-halfW,halfW,1, gx,-20,158,"x",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.xSlider,panel.xBox,panel.xRefresh = s,b,r
    s,b,r = CreateNudgeSlider(posGroup,"Y Offset",-halfH,halfH,1, gx,-58,158,"y",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.ySlider,panel.yBox,panel.yRefresh = s,b,r

    -- ── Bar-only: Frame Size (below Position, left column) ──────────────────
    local sizeGroup = CreateGroupBox(content, "Frame Size", x, -178, 290, 102, "GameFontNormal")
    s,b,r = CreateNudgeSlider(sizeGroup,"Width",60,500,1, gx,-20,158,"frameWidth",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.widthSlider,panel.widthBox,panel.widthRefresh = s,b,r
    s,b,r = CreateNudgeSlider(sizeGroup,"Height",12,120,1, gx,-58,158,"frameHeight",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.heightSlider,panel.heightBox,panel.heightRefresh = s,b,r

    -- ── Bar-only: Portrait (below Frame Size, left column) ──────────────────
    -- Height: Mode+Side row=44, Clamp checkbox=30, unclamped sliders=4×38=152, padding=14 → ~180
    local portGroup = CreateGroupBox(content, "Portrait", x, -290, 290, 180, "GameFontNormal")
    local pgx = 8
    CreateLabel(portGroup, "Mode", pgx, -20)
    panel.portraitModeDD = CreateDropdown(portGroup, pgx+44, -18, 110, portraitModeOptions,
        function() return getDB().portraitMode or "None" end,
        function(v) getDB().portraitMode = v; UnitFramesLite_UpdateFrame(unit); panel:UpdatePortraitMode() end)
    CreateLabel(portGroup, "Side", pgx, -52)
    panel.portraitSideDD = CreateDropdown(portGroup, pgx+44, -50, 90, portraitSideOptions,
        function() return getDB().portraitSide or "Left" end,
        function(v) getDB().portraitSide = v; UnitFramesLite_UpdateFrame(unit) end)
    local unitLabel = unit:sub(1,1):upper() .. unit:sub(2)
    panel.portraitClampCheck = CreateCheckbox(portGroup, "Clamp to " .. unitLabel .. " frame", pgx, -84,
        function() return getDB().portraitClamp ~= false end,
        function(v) getDB().portraitClamp = v; UnitFramesLite_UpdateFrame(unit); panel:UpdatePortraitMode() end)
    local unclampedGroup = CreateFrame("Frame", nil, portGroup)
    unclampedGroup:SetPoint("TOPLEFT", portGroup, "TOPLEFT", 0, -108)
    unclampedGroup:SetSize(280, 72)
    panel.portraitUnclampedGroup = unclampedGroup
    s,b,r = CreateNudgeSlider(unclampedGroup,"Width",12,300,1, pgx,-4,130,"portraitW",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.portraitWSlider,panel.portraitWBox,panel.portraitWRefresh = s,b,r
    s,b,r = CreateNudgeSlider(unclampedGroup,"X Offset",-500,500,1, pgx,-42,130,"portraitX",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.portraitXSlider,panel.portraitXBox,panel.portraitXRefresh = s,b,r
    -- Height and Y Offset hidden (portrait is always clamped to frame height; Y rarely needed)

    -- legacy stub so panel:refresh() "panel.portraitDD:SetSelection" doesn't error
    panel.portraitDD = CreateDropdown(content, -9999, 0, 80, portraitOptions,
        function() return getDB().portrait or "Portrait Off" end,
        function(v) getDB().portrait = v end)

    panel.UpdatePortraitMode = function(self)
        local isNone    = (getDB().portraitMode or "None") == "None"
        local isClamped = getDB().portraitClamp ~= false
        self.portraitSideDD:SetShown(not isNone)
        self.portraitClampCheck:SetShown(not isNone)
        self.portraitUnclampedGroup:SetShown(not isNone and not isClamped)
    end

    -- Store bar-only group references for UpdateAppearanceMode
    panel.appSizeGroup = sizeGroup
    panel.appPortGroup = portGroup

    -- ── BAR section — right column beside Position/Size/Portrait ─────────────
    local barSection = CreateGroupBox(content, "Bar", rx, -66, 268, 440, "GameFontNormal")
    barSection:Hide()
    panel.barSection = barSection

    local bx = 8   -- x inside barSection
    local bSliderW = 140  -- slider width to fit 268px column

    -- ── Colour & Texture sub-group ────────────────────────────────────────────
    -- Stacked layout: BG colour, solid/gradient swatches, then texture below
    local colGroup = CreateGroupBox(barSection, "Colour & Texture", bx, -16, 248, 230, "GameFontNormal")

    CreateLabel(colGroup, "Background", bx, -20)
    local bgBtn = CreateColorSwatch(colGroup, bx+80, -18, "Background Colour", getDB, "barBG", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = bgBtn

    panel.solidCheckbox = CreateCheckbox(colGroup, "Use Solid Colour", bx, -46,
        function() return getDB().useSolidColor or false end,
        function(v) getDB().useSolidColor = v; panel:UpdateColourMode(); UnitFramesLite_UpdateFrame(unit) end)

    local solidBtn  = CreateColorSwatch(colGroup, bx, -78, "Solid Colour",   getDB, "solidColor",    function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = solidBtn
    local gradSBtn  = CreateColorSwatch(colGroup, bx, -78, "Gradient Start", getDB, "gradientStart", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = gradSBtn
    local gradEBtn  = CreateColorSwatch(colGroup, bx, -104, "Gradient End",  getDB, "gradientEnd",   function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = gradEBtn
    local gradDirLabel = CreateLabel(colGroup, "Direction", bx, -132)
    panel.dirDD = CreateDropdown(colGroup, bx, -150, 120, dirOptions,
        function() return getDB().gradientDir or "HORIZONTAL" end,
        function(v) getDB().gradientDir = v; UnitFramesLite_UpdateFrame(unit) end)

    panel.solidGroup    = {solidBtn}
    panel.gradientGroup = {gradSBtn, gradEBtn, gradDirLabel, panel.dirDD}

    -- Texture below colour controls (hidden when solid colour)
    local texLabel = CreateLabel(colGroup, "Statusbar Texture", bx, -182)
    panel.texLabel = texLabel
    panel.texDD = CreateDropdown(colGroup, bx, -200, 200, GetTextureList(),
        function() return getDB().statusbarTexture or "Blizzard" end,
        function(v) getDB().statusbarTexture = v; UnitFramesLite_UpdateFrame(unit) end)

    -- UpdateColourMode also toggles texture visibility
    panel.UpdateColourMode = function(self)
        local isSolid = getDB().useSolidColor
        for _, w in ipairs(self.solidGroup    or {}) do w:SetShown(isSolid)     end
        for _, w in ipairs(self.gradientGroup or {}) do w:SetShown(not isSolid) end
        if self.texLabel then self.texLabel:SetShown(not isSolid) end
        if self.texDD    then self.texDD:SetShown(not isSolid)    end
    end

    -- ── General bar controls (below colour group) ─────────────────────────────
    -- colGroup top at -16, height 230 → bottom -246, +10 gap → genY=-256
    local genY = -256

    s,b,r = CreateNudgeSlider(barSection,"HP Bar Height (0 = full)",0,120,1, bx,genY,bSliderW,"hpBarHeight",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.hpBarHeightSlider,panel.hpBarHeightBox,panel.hpBarHeightRefresh = s,b,r

    -- ── Bar Border (collapsible sub-frame) ───────────────────────────────────
    local borderY = genY - 80
    CreateLabel(barSection, "Bar Border", bx, borderY)
    local barBorderDetails
    panel.barBorderCheck = CreateCheckbox(barSection, "Enabled", bx+80, borderY,
        function() return getDB().barBorderEnabled or false end,
        function(v)
            getDB().barBorderEnabled = v
            barBorderDetails:SetShown(v)
            UnitFramesLite_UpdateFrame(unit)
        end)
    barBorderDetails = CreateFrame("Frame", nil, barSection)
    barBorderDetails:SetPoint("TOPLEFT", barSection, "TOPLEFT", 0, borderY - 14)
    barBorderDetails:SetSize(260, 80)
    s,b,r = CreateNudgeSlider(barBorderDetails,"Border Thickness",1,20,1, bx,-14,bSliderW,"barBorderThickness",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.borderThicknessSlider,panel.borderThicknessBox,panel.borderThicknessRefresh = s,b,r
    local borderBtn = CreateColorSwatch(barBorderDetails, bx, -52, "Border Colour", getDB, "barBorderColor", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = borderBtn
    barBorderDetails:SetShown(getDB().barBorderEnabled or false)
    panel.barBorderCheck.Refresh = function(self)
        local v = getDB().barBorderEnabled or false
        self:SetChecked(v); barBorderDetails:SetShown(v)
    end

    -- ── ORB section — full width, starts at y=-66 ────────────────────────────
    -- Left column: Orb Size & Direction, Orb Colour, Orb Background groups
    -- Right column: Power Ring group (top), Inner Border group (below)
    local orbSection = CreateFrame("Frame", nil, content)
    orbSection:SetPoint("TOPLEFT", content, "TOPLEFT", x, -178)
    orbSection:SetSize(590, 680)
    orbSection:Hide()
    panel.orbSection = orbSection

    local ox  = 0    -- left column x within orbSection (group box interior uses gx=8)
    local orx = 310  -- right column x

    -- ── Orb Size & Direction (left column, group box) ─────────────────────────
    local orbSizeGroup = CreateGroupBox(orbSection, "Orb Size & Direction", ox, 0, 290, 152, "GameFontNormal")
    s,b,r = CreateNudgeSlider(orbSizeGroup,"Orb Diameter (px)",20,300,1, gx,-28,100,"sphereSize",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.sphereSizeSlider,panel.sphereSizeBox,panel.sphereSizeRefresh = s,b,r
    CreateLabel(orbSizeGroup, "Health Fill Direction", gx, -66)
    panel.sphereFillDirDD = CreateDropdown(orbSizeGroup, gx, -84, 110, fillDirOptions,
        function() return getDB().sphereFillDir or "VERTICAL" end,
        function(v) getDB().sphereFillDir = v; UnitFramesLite_UpdateFrame(unit) end)
    CreateLabel(orbSizeGroup, "Gradient Direction", gx, -110)
    panel.orbGradDirDD = CreateDropdown(orbSizeGroup, gx, -126, 110, {"VERTICAL","HORIZONTAL","CENTRE"},
        function() return getDB().orbGradientDir or "VERTICAL" end,
        function(v) getDB().orbGradientDir = v; UnitFramesLite_UpdateFrame(unit) end)

    -- ── Orb Colour (left column, group box) ──────────────────────────────────
    local orbColGroup = CreateGroupBox(orbSection, "Orb Colour", ox, -162, 290, 100, "GameFontNormal")
    panel.orbSolidCheck = CreateCheckbox(orbColGroup, "Use Solid Colour", gx, -20,
        function() return getDB().orbUseSolidColor or false end,
        function(v) getDB().orbUseSolidColor = v; panel:UpdateOrbColourMode(); UnitFramesLite_UpdateFrame(unit) end)
    local orbSolidBtn = CreateColorSwatch(orbColGroup, gx, -54, "Solid",      getDB, "orbSolidColor",    function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = orbSolidBtn
    local orbGSBtn    = CreateColorSwatch(orbColGroup, gx, -54, "Grad Start", getDB, "orbGradientEnd",   function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = orbGSBtn
    local orbGEBtn    = CreateColorSwatch(orbColGroup, gx, -80, "Grad End",   getDB, "orbGradientStart", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = orbGEBtn
    panel.orbSolidGroup    = {orbSolidBtn}
    panel.orbGradientGroup = {orbGSBtn, orbGEBtn}
    panel.UpdateOrbColourMode = function(self)
        local isSolid = getDB().orbUseSolidColor
        for _, w in ipairs(self.orbSolidGroup    or {}) do w:SetShown(isSolid)     end
        for _, w in ipairs(self.orbGradientGroup or {}) do w:SetShown(not isSolid) end
    end

    -- ── Orb Background (left column, group box) ───────────────────────────────
    local orbBgGroup = CreateGroupBox(orbSection, "Orb Background", ox, -272, 290, 96, "GameFontNormal")
    local orbBgBtn = CreateColorSwatch(orbBgGroup, gx, -20, "Colour", getDB, "orbBgColor", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = orbBgBtn
    local function orbBgAlphaDB()
        local db = getDB()
        return setmetatable({}, {
            __index    = function(_, k) if k == "orbBgAlpha" then return math.max(0, math.min(1, (db.orbBgColor or {})[4] or 0.9)) end end,
            __newindex = function(_, k, v) if k == "orbBgAlpha" then if not db.orbBgColor then db.orbBgColor = {0,0,0,0.9} end; db.orbBgColor[4] = math.max(0, math.min(1, v)) end end,
        })
    end
    local s4,b4,r4 = CreateNudgeSlider(orbBgGroup,"Alpha",0,1,0.01, gx,-54,100,"orbBgAlpha",orbBgAlphaDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.orbBgAlphaRefresh = r4

    -- ── Power group (right column, shared between Bar and Orb modes) ────────────
    -- Anchored to content so it can be shown in both bar and orb modes.
    local powerGroup = CreateGroupBox(content, "Power", rx, -66, 268, 320, "GameFontNormal")
    powerGroup:Hide()
    panel.orbPowerGroup = powerGroup   -- kept for UpdateAppearanceMode compat

    CreateLabel(powerGroup, "Type", gx, -22)

    local ringDetailsFrame = CreateFrame("Frame", nil, powerGroup)
    local barDetailsFrame  = CreateFrame("Frame", nil, powerGroup)

    local function UpdatePowerMode()
        local m      = getDB().orbPowerMode or "None"
        local isOrb  = getDB().sphereMode
        local attach = getDB().powerBarAttach ~= false
        ringDetailsFrame:SetShown(m == "Ring")
        barDetailsFrame:SetShown(m == "Bar")
        if m == "Bar" then
            -- Attach checkbox: only in bar-frame mode
            panel.powerBarAttachCheck:SetShown(not isOrb)
            -- Width row: hidden when attached in bar-frame mode
            panel.powerBarWidthRow:SetShown(isOrb or not attach)
            -- Height slider: when attached, clamp max to frameHeight/2
            if not isOrb and attach then
                local maxH = math.max(1, math.floor((getDB().frameHeight or 35) / 2))
                panel.orbPBarHeightSlider:SetMinMaxValues(1, maxH)
            else
                panel.orbPBarHeightSlider:SetMinMaxValues(4, 80)
            end
        end
    end
    panel.UpdatePowerMode = UpdatePowerMode
    panel.UpdatePowerBarAttach = function(self) UpdatePowerMode() end

    -- Power type dropdown — options differ by mode; rebuilt in UpdateAppearanceMode
    panel.powerTypeDD = CreateDropdown(powerGroup, gx + 52, -20, 90, {"None","Ring","Bar"},
        function() return getDB().orbPowerMode or "None" end,
        function(v)
            getDB().orbPowerMode = v
            -- Migrate legacy showPowerBar when user explicitly picks a mode
            getDB().showPowerBar = (v == "Bar")
            UpdatePowerMode()
            UnitFramesLite_UpdateFrame(unit)
        end)

    -- Ring details sub-frame
    ringDetailsFrame:SetPoint("TOPLEFT", powerGroup, "TOPLEFT", 0, -50)
    ringDetailsFrame:SetSize(260, 150)
    local s3,b3,r3 = CreateNudgeSlider(ringDetailsFrame,"Thickness (px)",4,40,1, gx,-4,100,"orbPowerRingThickness",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.ringThickSlider,panel.ringThickBox,panel.ringThickRefresh = s3,b3,r3
    panel.ringCCWCheck = CreateCheckbox(ringDetailsFrame, "Counter-clockwise", gx, -46,
        function() return getDB().orbPowerRingCCW or false end,
        function(v) getDB().orbPowerRingCCW = v; UnitFramesLite_UpdateFrame(unit) end)
    panel.ringTypeColorCheck = CreateCheckbox(ringDetailsFrame, "Use power type colour", gx, -72,
        function() return getDB().orbPowerRingUseTypeColor ~= false end,
        function(v)
            getDB().orbPowerRingUseTypeColor = v
            panel:UpdateRingColourMode()
            UnitFramesLite_UpdateFrame(unit)
        end)
    local ringColBtn = CreateColorSwatch(ringDetailsFrame, gx, -106, "Ring Colour", getDB, "orbPowerRingColor", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = ringColBtn
    panel.ringColBtn = ringColBtn
    panel.UpdateRingColourMode = function(self)
        ringColBtn:SetShown(getDB().orbPowerRingUseTypeColor == false)
    end

    -- Bar details sub-frame (shared by bar-frame and orb Bar mode)
    -- Layout (top-to-bottom):
    --   y=  0 : Attach to health bar checkbox  (bar-frame mode only)
    --   y=-30 : Width row                       (hidden when attached in bar-frame mode)
    --   y=-68 : Height
    --   y=-106: X Offset
    --   y=-144: Y Offset
    --   y=-182: Fill Direction label + dropdown
    --   y=-210: FG/BG colour swatches
    barDetailsFrame:SetPoint("TOPLEFT", powerGroup, "TOPLEFT", 0, -50)
    barDetailsFrame:SetSize(260, 240)

    -- Attach checkbox (bar-frame mode only, at top)
    local attachCheck = CreateCheckbox(barDetailsFrame, "Attach to health bar", gx, 0,
        function() return getDB().powerBarAttach ~= false end,
        function(v)
            getDB().powerBarAttach = v
            panel:UpdatePowerBarAttach()
            UnitFramesLite_UpdateFrame(unit)
        end)
    panel.powerBarAttachCheck = attachCheck

    -- Width row (hidden when attached in bar-frame mode)
    local pBarWidthRow = CreateFrame("Frame", nil, barDetailsFrame)
    pBarWidthRow:SetPoint("TOPLEFT", barDetailsFrame, "TOPLEFT", 0, -30)
    pBarWidthRow:SetSize(260, 38)
    local s5,b5,r5 = CreateNudgeSlider(pBarWidthRow,"Width",20,400,1, gx,-4,100,"orbPowerBarWidth",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.orbPBarWidthSlider,panel.orbPBarWidthBox,panel.orbPBarWidthRefresh = s5,b5,r5
    panel.powerBarWidthRow = pBarWidthRow

    local s6,b6,r6 = CreateNudgeSlider(barDetailsFrame,"Height",4,80,1,       gx,-68, 100,"orbPowerBarHeight",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.orbPBarHeightSlider,panel.orbPBarHeightBox,panel.orbPBarHeightRefresh = s6,b6,r6
    local s7,b7,r7 = CreateNudgeSlider(barDetailsFrame,"X Offset",-500,500,1, gx,-106,100,"orbPowerBarX",     getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.orbPBarXSlider,panel.orbPBarXBox,panel.orbPBarXRefresh = s7,b7,r7
    local s8,b8,r8 = CreateNudgeSlider(barDetailsFrame,"Y Offset",-500,500,1, gx,-144,100,"orbPowerBarY",     getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.orbPBarYSlider,panel.orbPBarYBox,panel.orbPBarYRefresh = s8,b8,r8
    CreateLabel(barDetailsFrame, "Fill Direction", gx, -182)
    panel.orbPBarFillDirDD = CreateDropdown(barDetailsFrame, gx, -200, 120, {"HORIZONTAL","VERTICAL"},
        function() return getDB().orbPowerBarFillDir or "HORIZONTAL" end,
        function(v) getDB().orbPowerBarFillDir = v; UnitFramesLite_UpdateFrame(unit) end)
    local orbPBarFgBtn = CreateColorSwatch(barDetailsFrame, gx,     -230, "Foreground", getDB, "orbPowerBarColor",   function() UnitFramesLite_UpdateFrame(unit) end)
    local orbPBarBgBtn = CreateColorSwatch(barDetailsFrame, gx+130, -230, "Background", getDB, "orbPowerBarBgColor", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = orbPBarFgBtn
    panel.swatchButtons[#panel.swatchButtons+1] = orbPBarBgBtn

    -- Init visibility
    UpdatePowerMode()
    panel.showOrbPowerCheck = { Refresh = function() end }

    -- ── Inner Border (right column below Power group, anchored to content) ────
    local orbBorderGroup = CreateGroupBox(content, "Inner Border", rx, -396, 268, 120, "GameFontNormal")
    orbBorderGroup:Hide()
    panel.orbBorderGroup = orbBorderGroup
    local orbBorderDetails  -- declared before checkbox so closure captures the upvalue
    panel.showOrbBorderCheck = CreateCheckbox(orbBorderGroup, "Enabled", gx, -20,
        function() return getDB().showOrbBorder or false end,
        function(v)
            getDB().showOrbBorder = v
            orbBorderDetails:SetShown(v)
            UnitFramesLite_UpdateFrame(unit)
        end)
    orbBorderDetails = CreateFrame("Frame", nil, orbBorderGroup)
    orbBorderDetails:SetPoint("TOPLEFT", orbBorderGroup, "TOPLEFT", 0, -40)
    orbBorderDetails:SetSize(260, 80)
    local s2,b2,r2 = CreateNudgeSlider(orbBorderDetails,"Thickness (px)",1,40,1, gx,-4,100,"orbBorderThickness",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.orbBorderThickSlider,panel.orbBorderThickBox,panel.orbBorderThickRefresh = s2,b2,r2
    local orbBorderBtn = CreateColorSwatch(orbBorderDetails, gx, -42, "Border Colour", getDB, "orbBorderColor", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = orbBorderBtn
    orbBorderDetails:SetShown(getDB().showOrbBorder or false)
    panel.showOrbBorderCheck.Refresh = function(self)
        local v = getDB().showOrbBorder or false
        self:SetChecked(v); orbBorderDetails:SetShown(v)
    end

    -- ── Hidden sphereMode stub (panel:refresh calls self.sphereModeCheck:Refresh()) ──
    panel.sphereModeCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    panel.sphereModeCheck:SetPoint("TOPLEFT", content, "TOPLEFT", -9999, 0)
    panel.sphereModeCheck:SetChecked(getDB().sphereMode or false)
    panel.sphereModeCheck.Refresh = function(self) self:SetChecked(getDB().sphereMode or false) end

    -- ── UpdateAppearanceMode ────────────────────────────────────────────────
    panel.UpdateAppearanceMode = function(self)
        -- Migrate legacy showPowerBar to orbPowerMode if not yet set
        if getDB().orbPowerMode == nil and getDB().showPowerBar then
            getDB().orbPowerMode = "Bar"
        end
        local isOrb = getDB().sphereMode
        barSection:SetShown(not isOrb)
        orbSection:SetShown(isOrb)
        -- Power group: always at rx, -66 (right column top) in both modes.
        if self.orbPowerGroup then
            self.orbPowerGroup:ClearAllPoints()
            self.orbPowerGroup:SetPoint("TOPLEFT", content, "TOPLEFT", rx, -66)
            self.orbPowerGroup:SetShown(true)
        end
        if self.orbBorderGroup then self.orbBorderGroup:SetShown(isOrb) end
        -- Frame Size is bar-only (left column, always at x,-178)
        sizeGroup:SetShown(not isOrb)
        -- Bar mode: Bar section left column (below Frame Size), Portrait right column (below Power)
        -- Orb mode: Bar section hidden, Portrait hidden
        if not isOrb then
            barSection:ClearAllPoints()
            barSection:SetPoint("TOPLEFT", content, "TOPLEFT", x, -290)
            barSection:SetSize(290, 440)
            portGroup:ClearAllPoints()
            portGroup:SetPoint("TOPLEFT", content, "TOPLEFT", rx, -396)
            portGroup:SetSize(268, 180)
        end
        portGroup:SetShown(not isOrb)
        if self.frameStyleDD then
            self.frameStyleDD:SetSelection(isOrb and "Orb" or "Bar")
        end
        -- Rebuild power type dropdown options: bar mode hides Ring option
        if self.powerTypeDD then
            local opts = isOrb and {"None","Ring","Bar"} or {"None","Bar"}
            self.powerTypeDD:SetOptions(opts)
            -- If Ring was selected and we're now in bar mode, reset to None
            local cur = getDB().orbPowerMode or "None"
            if not isOrb and cur == "Ring" then
                getDB().orbPowerMode = "None"
                cur = "None"
            end
            self.powerTypeDD:SetSelection(cur)
        end
        -- Sync sub-section visibility with DB when switching modes
        if isOrb then
            orbBorderDetails:SetShown(getDB().showOrbBorder or false)
        else
            barBorderDetails:SetShown(getDB().barBorderEnabled or false)
        end
        UpdatePowerMode()
    end
end

-- Tab 5: Buffs / Debuffs ------------------------------------------------------

local function BuildBuffsContent(content, unit, getDB, panel)
    local function applyAuras() UnitFramesLite_UpdateAuras(unit) end
    local db = getDB

    -- Two equal-width columns side by side.
    -- Content width ≈ 620px; each column 300px wide with 8px gap between.
    local GRP_W      = 295
    local GRP_H_BUFF = 390    -- buffs: no filter checkboxes
    local GRP_H_DEB  = 440    -- debuffs: two extra filter checkboxes
    local SW         = 140   -- slider width inside group box (fits in GRP_W with all chrome)
    local refreshFns = {}

    local function BuildSection(prefix, isDebuff, ox, oy)
        local title  = isDebuff and "Debuffs" or "Buffs"
        local grpH   = isDebuff and GRP_H_DEB or GRP_H_BUFF
        local grp    = CreateGroupBox(content, title, ox, oy, GRP_W, grpH)
        local gx    = 8
        local gy    = -24
        local refreshList = {}

        local function gdb(k)   return db()[prefix .. k] end
        local function sdb(k,v) db()[prefix .. k] = v; applyAuras() end

        -- Row 1: Icon Size
        local _,_,rIconSize = CreateNudgeSlider(grp, "Icon Size", 12, 64, 1,
            gx, gy, SW, prefix.."IconSize", db, applyAuras)
        refreshList[#refreshList+1] = rIconSize
        gy = gy - 38

        -- Row 2: Per Row
        local _,_,rPerRow = CreateNudgeSlider(grp, "Per Row", 1, 16, 1,
            gx, gy, SW, prefix.."PerRow", db, applyAuras)
        refreshList[#refreshList+1] = rPerRow
        gy = gy - 38

        -- Row 3: Max Shown
        local _,_,rMaxShown = CreateNudgeSlider(grp, "Max Shown", 1, 64, 1,
            gx, gy, SW, prefix.."MaxShown", db, applyAuras)
        refreshList[#refreshList+1] = rMaxShown
        gy = gy - 40

        -- Row 4: Grow X dropdown
        CreateLabel(grp, "Grow X", gx, gy)
        local growXDD = CreateDropdown(grp, gx + 60, gy - 18, 100, {"RIGHT","LEFT"},
            function() return gdb("GrowX") or (isDebuff and "LEFT" or "RIGHT") end,
            function(v) sdb("GrowX", v) end)
        gy = gy - 44

        -- Row 5: Grow Y dropdown
        CreateLabel(grp, "Grow Y", gx, gy)
        local growYDD = CreateDropdown(grp, gx + 60, gy - 18, 100, {"DOWN","UP"},
            function() return gdb("GrowY") or (isDebuff and "UP" or "DOWN") end,
            function(v) sdb("GrowY", v) end)
        gy = gy - 44

        -- Row 6: X Offset
        local _,_,rXOfs = CreateNudgeSlider(grp, "X Offset", -500, 500, 1,
            gx, gy, SW, prefix.."XOffset", db, applyAuras)
        refreshList[#refreshList+1] = rXOfs
        gy = gy - 38

        -- Row 7: Y Offset
        local _,_,rYOfs = CreateNudgeSlider(grp, "Y Offset", -500, 500, 1,
            gx, gy, SW, prefix.."YOffset", db, applyAuras)
        refreshList[#refreshList+1] = rYOfs
        gy = gy - 32

        -- Row 8: Anchor checkbox
        local anchorCB = CreateCheckbox(grp, "Anchor to unit frame", gx, gy,
            function() return db()[prefix.."AnchorToFrame"] ~= false end,
            function(v) db()[prefix.."AnchorToFrame"] = v; applyAuras() end)
        gy = gy - 26

        -- Row 9: Show checkbox
        local showKey = isDebuff and "debuffShowDebuffs" or "buffShowBuffs"
        local showLabel = isDebuff and "Show Debuffs" or "Show Buffs"
        local showCB = CreateCheckbox(grp, showLabel, gx, gy,
            function() return db()[showKey] ~= false end,
            function(v) db()[showKey] = v; applyAuras() end)

        -- Debuff-only filter checkboxes
        local playerOnlyCB, curableOnlyCB
        if isDebuff then
            gy = gy - 26
            playerOnlyCB = CreateCheckbox(grp, "Only cast by player", gx, gy,
                function() return db().debuffPlayerOnly or false end,
                function(v) db().debuffPlayerOnly = v; applyAuras() end)
            gy = gy - 26
            curableOnlyCB = CreateCheckbox(grp, "Only curable", gx, gy,
                function() return db().debuffCurableOnly or false end,
                function(v) db().debuffCurableOnly = v; applyAuras() end)
        end

        refreshFns[#refreshFns+1] = function()
            for _, fn in ipairs(refreshList) do fn() end
            anchorCB:Refresh(); showCB:Refresh()
            growXDD:SetSelection(gdb("GrowX") or (isDebuff and "LEFT" or "RIGHT"))
            growYDD:SetSelection(gdb("GrowY") or (isDebuff and "UP" or "DOWN"))
            if playerOnlyCB  then playerOnlyCB:Refresh()  end
            if curableOnlyCB then curableOnlyCB:Refresh() end
        end
    end

    BuildSection("buff",   false, 8,         -8)
    BuildSection("debuff", true,  8 + GRP_W + 8, -8)

    panel.refreshBuffs = function()
        for _, fn in ipairs(refreshFns) do fn() end
    end
end

-- Tab 6: Conditions (includes Alpha section) ---------------------------------

local function BuildConditionsContent(content, unit, getDB, panel)
    -- ── Load Conditions group (left) ─────────────────────────────────────────
    local condBox = CreateGroupBox(content, "Load Conditions", 8, -8, 330, 230)
    local hint = condBox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", condBox, "TOPLEFT", 8, -18)
    hint:SetText("Show frame only when checked conditions are met.\nIf none are ticked the frame is always shown.")
    hint:SetTextColor(0.7, 0.7, 0.7)

    local condDefs = {
        {"Mounted",       "loadMounted",      1, 1},
        {"In vehicle",    "loadInVehicle",    1, 2},
        {"Resting",       "loadResting",      1, 3},
        {"Stealthed",     "loadStealthed",    1, 4},
        {"In combat",     "loadInCombat",     1, 5},
        {"Out of combat", "loadOutOfCombat",  2, 1},
        {"Solo",          "loadSolo",         2, 2},
        {"In group",      "loadInGroup",      2, 3},
        {"In instance",   "loadInInstance",   2, 4},
    }
    local colX = {8, 168}; local startY = -58; local rowH = 28
    panel.conditionChecks = {}
    for _, def in ipairs(condDefs) do
        local label, key, col, row = def[1], def[2], def[3], def[4]
        local cb = CreateCheckbox(condBox, label, colX[col], startY - (row-1)*rowH,
            function() return getDB()[key] or false end,
            function(v) getDB()[key] = v; UnitFramesLite_UpdateVisibility(unit) end)
        panel.conditionChecks[key] = cb
    end

    -- ── Visibility Alpha group (right top) ───────────────────────────────────
    local alphaBox = CreateGroupBox(content, "Visibility Alpha", 346, -8, 310, 230)
    local gx = 8

    panel.keepTextVisCheck = CreateCheckbox(alphaBox, "Keep text + portrait visible", gx, -18,
        function() return getDB().keepTextVisible or false end,
        function(v) getDB().keepTextVisible = v; UnitFramesLite_UpdateAlpha(unit) end)

    local affLbl = alphaBox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    affLbl:SetPoint("TOPLEFT", alphaBox, "TOPLEFT", gx, -46)
    affLbl:SetText("Sliders affect")
    panel.alphaAffectsDD = CreateDropdown(alphaBox, gx+90, -64, 120, alphaAffectsOptions,
        function() return getDB().alphaAffects or "Everything" end,
        function(v) getDB().alphaAffects = v; UnitFramesLite_UpdateAlpha(unit) end)

    local outLabel = (unit == "player") and "Alpha out of combat (& target)" or "Alpha out of combat"
    local function onOutCombatChange()
        UnitFramesLite_UpdateAlpha(unit)
        if unit == "player" then UnitFramesLite_UpdateAlpha("target") end
    end
    local _,_,rCombat    = CreateNudgeSlider(alphaBox, "Alpha in combat",  0,1,0.01, gx,-100,140,"alphaCombat",    getDB, function() UnitFramesLite_UpdateAlpha(unit) end)
    local _,_,rOutCombat = CreateNudgeSlider(alphaBox, outLabel,           0,1,0.01, gx,-142,140,"alphaOutCombat", getDB, onOutCombatChange)

    panel.syncAlphaCheck = CreateCheckbox(alphaBox, "Sync in/out alpha", gx, -196,
        function() return getDB().syncAlpha or false end,
        function(v) getDB().syncAlpha = v; UnitFramesLite_UpdateAlpha(unit) end)

    -- ── Fade Conditions group (right bottom) ─────────────────────────────────
    local fadeBox = CreateGroupBox(content, "Fade Conditions", 346, -246, 310, 100)

    panel.fadeNoTargetCheck = CreateCheckbox(fadeBox, "Fade when no target selected", gx, -18,
        function() return getDB().fadeNoTarget or false end,
        function(v) getDB().fadeNoTarget = v; UnitFramesLite_UpdateAlpha(unit) end)
    local _,_,rFade = CreateNudgeSlider(fadeBox, "Fade alpha", 0,1,0.01, gx,-46,140,"fadeNoTargetAlpha", getDB, function() UnitFramesLite_UpdateAlpha(unit) end)

    panel.refreshAlpha = function()
        rCombat(); rOutCombat(); rFade()
        panel.syncAlphaCheck:Refresh(); panel.keepTextVisCheck:Refresh()
        panel.fadeNoTargetCheck:Refresh()
        panel.alphaAffectsDD:SetSelection(getDB().alphaAffects or "Everything")
    end
end

-- Unit panel (5 tabs, buttons live on the main frame) -------------------------

local function BuildUnitPanel(panel, unit, tabSync)
    local function getDB() return UnitFramesLite_GetDB(unit) end
    panel.swatchButtons = {}

    panel.UpdateColourMode = function(self)
        local isSolid = getDB().useSolidColor
        for _, w in ipairs(self.solidGroup    or {}) do w:SetShown(isSolid)     end
        for _, w in ipairs(self.gradientGroup or {}) do w:SetShown(not isSolid) end
    end
    panel.UpdateOrbColourMode = function() end
    panel.UpdateRingColourMode = function() end
    panel.UpdatePortraitMode = function() end
    panel.UpdateAppearanceMode = function() end  -- overwritten by BuildAppearanceContent

    -- Tab buttons are created externally (on the main frame header).
    -- We only create scroll frames + content here.
    local tabNames        = {"General", "Appearance", "Text", "Class Resources", "Auras", "Conditions"}
    local tabContents     = {}   -- scroll child frames (passed to Build* functions)
    local tabScrollFrames = {}   -- scroll frame wrappers (shown/hidden by SelectTab)

    for i = 1, #tabNames do
        -- Scroll frame for the tab (provides vertical scrollbar automatically)
        local sf = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     panel, "TOPLEFT",     0,   -4)
        sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26,  40)
        sf:Hide()
        tabScrollFrames[i] = sf

        -- Scroll child: tall enough for all content; width synced with scroll frame
        local sc = CreateFrame("Frame", nil, sf)
        sc:SetSize(620, 1000)
        sf:SetScrollChild(sc)
        sf:HookScript("OnSizeChanged", function(self) sc:SetWidth(self:GetWidth()) end)
        tabContents[i] = sc
    end

    local function SelectTab(idx)
        for i, sf in ipairs(tabScrollFrames) do sf:SetShown(i == idx) end
    end
    SelectTab(tabSync.current or 1)
    panel.SelectTab = SelectTab

    BuildGeneralContent(tabContents[1],          unit, getDB, panel)
    BuildAppearanceContent(tabContents[2],       unit, getDB, panel)
    BuildTextContent(tabContents[3],             unit, getDB, panel)
    BuildClassResourcesContent(tabContents[4],   unit, getDB, panel)
    BuildBuffsContent(tabContents[5],            unit, getDB, panel)
    BuildConditionsContent(tabContents[6],       unit, getDB, panel)

    panel.refresh = function(self)
        local db = getDB()
        self.enabledCheck:Refresh(); self.reverseFillCheck:Refresh(); self.lockedCheck:Refresh()
        self.portraitDD:SetSelection(db.portrait or "Portrait Off")
        if self.portraitModeDD  then self.portraitModeDD:SetSelection(db.portraitMode or "None") end
        if self.portraitSideDD  then self.portraitSideDD:SetSelection(db.portraitSide or "Left") end
        if self.portraitClampCheck then self.portraitClampCheck:Refresh() end
        if self.portraitWRefresh then self.portraitWRefresh() end
        if self.portraitHRefresh then self.portraitHRefresh() end
        if self.portraitXRefresh then self.portraitXRefresh() end
        if self.portraitYRefresh then self.portraitYRefresh() end
        self:UpdatePortraitMode()
        self.xRefresh(); self.yRefresh(); self.widthRefresh(); self.heightRefresh()
        self.showNameCheck:Refresh(); self.showHPTextCheck:Refresh()
        self.showHPPctCheck:Refresh(); self.showLevelCheck:Refresh()
        self.fontDD:SetSelection(db.font or "Friz Quadrata TT")
        if self.nameFontDD  then self.nameFontDD:SetSelection(db.nameFont  or db.font or "Friz Quadrata TT") end
        if self.hpTextFontDD then self.hpTextFontDD:SetSelection(db.hpTextFont or db.font or "Friz Quadrata TT") end
        if self.hpPctFontDD then self.hpPctFontDD:SetSelection(db.hpPctFont or db.font or "Friz Quadrata TT") end
        if self.levelFontDD then self.levelFontDD:SetSelection(db.levelFont or db.font or "Friz Quadrata TT") end
        self.nameAlignDD:SetSelection(db.nameAlign or "LEFT")
        if self.hpContentDD then self.hpContentDD:SetSelection(db.hpContent or "Cur / Max") end
        if self.hpFormatDD  then self.hpFormatDD:SetSelection(db.hpFormat   or "Full")      end
        self.hpTextAlignDD:SetSelection(db.hpTextAlign or "CENTER")
        self.hpPctAlignDD:SetSelection(db.hpPctAlign or "CENTER")
        self.hpPctSymbolCheck:Refresh()
        self.levelTextAlignDD:SetSelection(db.levelTextAlign or "CENTER")
        self.nameFontSizeRefresh(); self.nameXRefresh(); self.nameYRefresh()
        self.hpFontSizeRefresh();   self.hpXRefresh();   self.hpYRefresh()
        self.hpPctFontSizeRefresh(); self.hpPctXRefresh(); self.hpPctYRefresh()
        self.levelFontSizeRefresh(); self.levelXRefresh(); self.levelYRefresh()
        self.texDD:SetSelection(db.statusbarTexture or "Blizzard")
        self.solidCheckbox:Refresh()
        if self.dirDD then self.dirDD:SetSelection(db.gradientDir or "HORIZONTAL") end
        self.hpBarHeightRefresh(); self.barBorderCheck:Refresh(); self.borderThicknessRefresh()
        self.sphereModeCheck:Refresh(); self.sphereSizeRefresh()
        if self.frameStyleDD then self.frameStyleDD:SetSelection(db.sphereMode and "Orb" or "Bar") end
        self.sphereFillDirDD:SetSelection(db.sphereFillDir or "VERTICAL")
        self.orbGradDirDD:SetSelection(db.orbGradientDir or "VERTICAL")
        self.orbSolidCheck:Refresh()
        self.showOrbBorderCheck:Refresh(); self.orbBorderThickRefresh()
        self.showOrbPowerCheck:Refresh(); self.ringThickRefresh()
        self.ringCCWCheck:Refresh(); self.ringTypeColorCheck:Refresh()
        if self.powerTypeDD         then self.powerTypeDD:SetSelection(db.orbPowerMode or "None") end
        if self.powerBarAttachCheck then self.powerBarAttachCheck:Refresh() end
        if self.orbPBarWidthRefresh  then self.orbPBarWidthRefresh()  end
        if self.orbPBarHeightRefresh then self.orbPBarHeightRefresh() end
        if self.orbPBarXRefresh      then self.orbPBarXRefresh()      end
        if self.orbPBarYRefresh      then self.orbPBarYRefresh()      end
        if self.orbPBarFillDirDD     then self.orbPBarFillDirDD:SetSelection(db.orbPowerBarFillDir or "HORIZONTAL") end
        if self.UpdateAppearanceMode then self:UpdateAppearanceMode() end
        for _, cb in pairs(self.conditionChecks or {}) do cb:Refresh() end
        if self.refreshAlpha then self:refreshAlpha() end
        if self.refreshBuffs then self:refreshBuffs() end
        for _, btn in ipairs(self.swatchButtons) do btn:RefreshSwatch() end
        self:UpdateColourMode()
        self:UpdateOrbColourMode()
        self:UpdateRingColourMode()
        self:UpdatePortraitMode()
        self:UpdateAppearanceMode()
    end

    -- Keys owned by each tab (index matches tabNames order).
    -- Nilling these keys then re-running CopyDefaults restores just that tab's defaults.
    local TAB_KEYS = {
        -- 1: General
        { "x","y","enabled","locked","frameWidth","frameHeight","reverseFill",
          "portrait","portraitMode","portraitSide","portraitClamp",
          "portraitW","portraitH","portraitX","portraitY",
          "showName","showHPText","showHPPct","showLevel","showPowerBar","showPowerText",
          "hpBarHeight","barBorderEnabled","barBorderThickness","barBorderColor",
          "nameAlign","hpTextAlign","hpPctAlign","levelTextAlign",
        },
        -- 2: Appearance
        { "useSolidColor","solidColor","gradientStart","gradientEnd","gradientDir",
          "statusbarTexture","barBG",
          "sphereMode","sphereSize","sphereFillDir","orbGradientDir",
          "orbBgColor",
          "orbGradStart","orbGradEnd","orbSolidColor","orbUseSolidColor",
          "showOrbBorder","orbBorderThickness","orbBorderColor",
          "showOrbPower","orbPowerMode",
          "orbPowerRingThickness","orbPowerRingCCW",
          "orbPowerRingBgColor","orbPowerRingColor","orbPowerRingUseTypeColor",
          "orbPowerBarWidth","orbPowerBarHeight","orbPowerBarX","orbPowerBarY",
          "orbPowerBarFillDir","orbPowerBarColor","orbPowerBarBgColor",
        },
        -- 3: Text
        { "font","nameFont","hpTextFont","hpPctFont","levelFont",
          "nameColor","hpTextColor","hpPctColor","levelColor","hpColor",
          "nameTextFontSize","nameTextX","nameTextY",
          "hpTextFontSize","hpTextX","hpTextY",
          "hpPctFontSize","hpPctX","hpPctY",
          "levelTextFontSize","levelTextX","levelTextY",
          "hpContent","hpFormat","hpPctSymbol",
        },
        -- 4: Class Resources
        { "showResources","resourceShowOutCombat","resourceShowWithTarget","resourceAlpha",
          "resourceX","resourceY",
          "resourcePipWidth","resourcePipHeight","resourcePipGap","resourcePipShape",
          "resourcePipBorderEnabled","resourcePipBorderThickness","resourcePipBorderColor",
          "resourceUseCustomColor","resourceColorMode","resourceUseSolidColor",
          "resourceSolidColor","resourceGradStart","resourceGradEnd","resourceGradPerPip",
        },
        -- 5: Auras
        { "buffIconSize","buffPerRow","buffMaxShown","buffGrowX","buffGrowY",
          "buffXOffset","buffYOffset","buffAnchorToFrame","buffShowBuffs",
          "debuffIconSize","debuffPerRow","debuffMaxShown","debuffGrowX","debuffGrowY",
          "debuffXOffset","debuffYOffset","debuffAnchorToFrame","debuffShowDebuffs",
          "debuffPlayerOnly","debuffCurableOnly",
        },
        -- 6: Conditions
        { "loadMounted","loadInVehicle","loadResting","loadStealthed","loadInCombat",
          "loadOutOfCombat","loadSolo","loadInGroup","loadInInstance",
          "syncAlpha","keepTextVisible","alphaAffects",
          "alphaCombat","alphaOutCombat","fadeNoTarget","fadeNoTargetAlpha",
        },
    }

    local resetAllBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetAllBtn:SetSize(150, 22); resetAllBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 12)
    resetAllBtn:SetText("Reset All to Defaults")
    resetAllBtn:SetScript("OnClick", function()
        local key = "UFL_RESET_" .. unit:upper()
        StaticPopupDialogs[key] = {
            text = "Reset ALL " .. unit .. " settings to defaults?",
            button1 = YES, button2 = NO,
            OnAccept = function()
                UnitFramesLiteDB[unit] = nil
                UnitFramesLite_UpdateFrame(unit)
                panel:refresh()
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show(key)
    end)

    local resetTabBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetTabBtn:SetSize(100, 22); resetTabBtn:SetPoint("RIGHT", resetAllBtn, "LEFT", -6, 0)
    resetTabBtn:SetText("Reset Tab")
    resetTabBtn:SetScript("OnClick", function()
        local tabIdx  = tabSync.current or 1
        local tabName = ({"General","Appearance","Text","Class Resources","Auras","Conditions"})[tabIdx] or "Tab"
        local key = "UFL_RESET_TAB_" .. unit:upper() .. "_" .. tabIdx
        StaticPopupDialogs[key] = {
            text = "Reset " .. unit .. " " .. tabName .. " settings to defaults?",
            button1 = YES, button2 = NO,
            OnAccept = function()
                local db = UnitFramesLiteDB[unit]
                if db and TAB_KEYS[tabIdx] then
                    -- Nil the tab's keys so GetDB re-fills them from defaults
                    for _, k in ipairs(TAB_KEYS[tabIdx]) do db[k] = nil end
                    UnitFramesLite_GetDB(unit)  -- re-applies CopyDefaults
                end
                UnitFramesLite_UpdateFrame(unit)
                if tabIdx == 5 and UnitFramesLite_UpdateAuras then
                    UnitFramesLite_UpdateAuras(unit)
                end
                if tabIdx == 4 then
                    if UnitFramesLite_UpdateResourceLayout    then UnitFramesLite_UpdateResourceLayout()    end
                    if UnitFramesLite_UpdateResourceVisibility then UnitFramesLite_UpdateResourceVisibility() end
                end
                panel:refresh()
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show(key)
    end)

    local undoBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    undoBtn:SetSize(80, 22); undoBtn:SetPoint("RIGHT", resetTabBtn, "LEFT", -6, 0)
    undoBtn:SetText("Undo")
    undoBtn:SetEnabled(false)
    undoBtn:SetScript("OnClick", function()
        if panel.undoSnapshot then
            UnitFramesLiteDB[unit] = DeepCopyDB(panel.undoSnapshot)
            UnitFramesLite_UpdateFrame(unit)
            panel:refresh()
            panel.undoSnapshot = nil
            undoBtn:SetEnabled(false)
        end
    end)

    panel:SetScript("OnShow", function(self)
        -- Fresh snapshot each time panel opens so undo goes back to this moment
        panel.undoSnapshot = DeepCopyDB(getDB())
        undoBtn:SetEnabled(true)
        self:refresh()
        SelectTab(tabSync.current or 1)
    end)
    panel:UpdateColourMode()
    panel:UpdatePortraitMode()
    panel:UpdateAppearanceMode()
end

-- Main options frame ---------------------------------------------------------

function CreateOptionsPanel()
    local OPTS_W, OPTS_H = 700, 620

    local mainFrame = CreateFrame("Frame", "UnitFramesLiteOptions", UIParent, "BackdropTemplate")
    mainFrame:SetSize(OPTS_W, OPTS_H); mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("HIGH"); mainFrame:SetMovable(true); mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")

    -- Pin the frame to an absolute TOPLEFT anchor before StartMoving/StartSizing.
    --
    -- WHY THIS EXISTS:
    --   WoW's StartMoving() and StartSizing() require the frame to be anchored by a
    --   single TOPLEFT point. Any other anchor (e.g. CENTER) causes the frame to jump
    --   the moment the mouse moves, because WoW recalculates the position from the
    --   wrong reference point.
    --
    -- WHY THE SCALE CONVERSION IS REQUIRED (do not remove):
    --   GetLeft()/GetTop() return coordinates in the frame's *own* effective-scale
    --   space. SetPoint with UIParent as the reference expects coordinates in
    --   *UIParent's* effective-scale space. Without the conversion the frame teleports
    --   by the difference between the two scales (usually small but visible).
    --   Formula: uiParentCoord = frameCoord * (frame.effectiveScale / UIParent.effectiveScale)
    local function PinToTopLeft()
        local x = mainFrame:GetLeft()
        local y = mainFrame:GetTop()
        if not x or not y then return end
        local scale = mainFrame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x * scale, y * scale)
    end

    mainFrame:SetScript("OnShow",      function() PinToTopLeft() end)
    mainFrame:SetScript("OnDragStart", function(self) PinToTopLeft(); self:StartMoving() end)
    mainFrame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing(); PinToTopLeft() end)
    mainFrame:SetResizable(true)
    mainFrame:SetResizeBounds(560, 400, 1400, 900)
    mainFrame:EnableMouseWheel(true)
    mainFrame:SetScript("OnMouseWheel", function(self, delta)
        if not IsControlKeyDown() then return end
        local s = math.max(0.5, math.min(2.0, self:GetScale() + delta * 0.05))
        self:SetScale(s)
    end)
    mainFrame:Hide()
    _G.UnitFramesLiteOptions = mainFrame

    mainFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left=11, right=12, top=12, bottom=11},
    })
    mainFrame:SetBackdropColor(0, 0, 0, 1)

    local titleText = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleText:SetPoint("TOP", mainFrame, "TOP", 0, -16); titleText:SetText("UnitFramesLite")

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 2, 2)

    -- Unit selector dropdown
    CreateLabel(mainFrame, "Unit:", 16, -38)
    local unitItems = {"Player", "Target", "Focus", "Pet"}
    local unitMap   = {Player="player", Target="target", Focus="focus", Pet="pet"}
    local currentLabel = "Player"

    local divider = mainFrame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.3, 0.3, 0.3, 0.8); divider:SetHeight(1)
    divider:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  16, -64)
    divider:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -16, -64)

    local tabSync = {current = 1}

    local profilesPanel  -- forward-declared so SelectUnit and tab buttons can reference it

    -- Build a panel for each unit
    local unitPanels = {}
    for _, label in ipairs(unitItems) do
        local u = unitMap[label]
        local c = CreateFrame("Frame", nil, mainFrame)
        c:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     0, -68)
        c:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
        c:Hide()
        BuildUnitPanel(c, u, tabSync)
        unitPanels[u] = c
    end
    unitPanels["player"]:Show()

    local classResourcesBtn  -- forward-declared; set after tab buttons are created

    local function SelectUnit(unit)
        profilesPanel:Hide()
        for _, p in pairs(unitPanels) do p:Hide() end
        -- Class Resources tab is player-only: hide button for other units and
        -- fall back to tab 1 if it was active
        local isPlayer = (unit == "player")
        if classResourcesBtn then classResourcesBtn:SetShown(isPlayer) end
        if not isPlayer and tabSync.current == 6 then
            tabSync.current = 1
        end
        if unitPanels[unit] then
            unitPanels[unit]:Show()
            if unitPanels[unit].SelectTab then
                unitPanels[unit].SelectTab(tabSync.current)
            end
        end
    end

    -- The dropdown needs to be created after SelectUnit is defined
    local unitDD = CreateDropdown(mainFrame, 60, -28, 120, unitItems,
        function() return currentLabel end,
        function(v)
            currentLabel = v
            SelectUnit(unitMap[v])
        end)

    -- Tab buttons on the main frame header, right of the unit dropdown
    local tabNames = {"General", "Appearance", "Text", "Class Resources", "Auras", "Conditions"}
    local tabWidths = {76, 100, 60, 110, 60, 90}
    local sharedTabBtns = {}
    for i, name in ipairs(tabNames) do
        local btn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        btn:SetSize(tabWidths[i] or 76, 22); btn:SetText(name)
        sharedTabBtns[i] = btn
        if i == 4 then classResourcesBtn = btn end
        btn:SetScript("OnClick", function()
            tabSync.current = i
            -- SelectUnit hides the profiles panel and shows the correct unit panel
            SelectUnit(unitMap[currentLabel])
            -- Then switch all panels to this tab
            for _, p in pairs(unitPanels) do
                if p.SelectTab then p.SelectTab(i) end
            end
        end)
    end

    -- ── Profiles panel (top-level, replaces unit panels when shown) ──────────
    profilesPanel = CreateFrame("Frame", nil, mainFrame)
    profilesPanel:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     0, -68)
    profilesPanel:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    profilesPanel:Hide()

    local function GetProfileList()
        if not (UnitFramesLiteDB and UnitFramesLiteDB.profiles) then return {"(none)"} end
        local names = UnitFramesLite_ProfileList and UnitFramesLite_ProfileList() or {}
        if #names == 0 then return {"(none)"} end
        return names
    end

    local px, py = 16, -16

    -- Active profile label
    local curLbl = profilesPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    curLbl:SetPoint("TOPLEFT", profilesPanel, "TOPLEFT", px, py)
    curLbl:SetText("Active profile: |cffffd700Default|r")

    local function RefreshProfilePanel()
        local p = UnitFramesLiteDB and UnitFramesLiteDB.profiles
        local active = (p and p.active) or "Default"
        curLbl:SetText("Active profile: |cffffd700" .. active .. "|r")
    end

    -- ── Left column: Create + Select ─────────────────────────────────────────
    local leftBox = CreateGroupBox(profilesPanel, "Profiles", px, py - 30, 280, 300)

    -- Create new
    local newLbl = leftBox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    newLbl:SetPoint("TOPLEFT", leftBox, "TOPLEFT", 10, -18)
    newLbl:SetText("New profile name:")
    local nameEdit = CreateFrame("EditBox", nil, leftBox, "InputBoxTemplate")
    nameEdit:SetSize(170, 20); nameEdit:SetPoint("TOPLEFT", leftBox, "TOPLEFT", 10, -36)
    nameEdit:SetAutoFocus(false); nameEdit:SetMaxLetters(40)
    local createBtn = CreateFrame("Button", nil, leftBox, "UIPanelButtonTemplate")
    createBtn:SetSize(80, 22); createBtn:SetPoint("LEFT", nameEdit, "RIGHT", 4, 0)
    createBtn:SetText("Create")
    createBtn:SetScript("OnClick", function()
        local name = nameEdit:GetText():match("^%s*(.-)%s*$")
        if name == "" then return end
        StaticPopupDialogs["UFL_CREATE_PROFILE"] = {
            text = "Create profile \"" .. name .. "\" and save current settings to it?",
            button1 = "Yes", button2 = "Cancel",
            OnAccept = function()
                if UnitFramesLite_ProfileCreate then UnitFramesLite_ProfileCreate(name) end
                nameEdit:SetText("")
                RefreshProfilePanel()
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show("UFL_CREATE_PROFILE")
    end)

    -- Divider
    local divTex = leftBox:CreateTexture(nil, "ARTWORK")
    divTex:SetColorTexture(0.3, 0.3, 0.3, 0.8); divTex:SetHeight(1)
    divTex:SetPoint("TOPLEFT", leftBox, "TOPLEFT", 8, -68)
    divTex:SetPoint("TOPRIGHT", leftBox, "TOPRIGHT", -8, -68)

    -- Select existing
    local selLbl = leftBox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    selLbl:SetPoint("TOPLEFT", leftBox, "TOPLEFT", 10, -78)
    selLbl:SetText("Select profile:")

    local selectedProfile = nil
    local selDD
    local function GetSelDropdownValue() return selectedProfile or "(none)" end
    local function SetSelDropdownValue(v)
        selectedProfile = (v ~= "(none)") and v or nil
    end
    selDD = CreateDropdown(leftBox, 10, -96, 220, GetProfileList(), GetSelDropdownValue, SetSelDropdownValue)

    local function RefreshSelDD()
        local list = GetProfileList()
        local found = false
        for _, n in ipairs(list) do if n == selectedProfile then found = true; break end end
        if not found then selectedProfile = (list[1] ~= "(none)") and list[1] or nil end
        if UIDropDownMenu_Initialize then
            UIDropDownMenu_Initialize(selDD, function(self, level)
                local info = UIDropDownMenu_CreateInfo()
                for _, name in ipairs(list) do
                    info.text = name; info.checked = (name == selectedProfile)
                    info.func  = function() selectedProfile = name; UIDropDownMenu_SetSelectedName(selDD, name) end
                    UIDropDownMenu_AddButton(info, level)
                end
            end)
            UIDropDownMenu_SetSelectedName(selDD, selectedProfile or "(none)")
        else
            selDD:SetSelection(selectedProfile or "(none)")
        end
    end

    -- ── Right column: Actions ─────────────────────────────────────────────────
    local actBox = CreateGroupBox(profilesPanel, "Actions", px + 296, py - 30, 330, 300)
    local bx, by = 10, -18
    local bW, bH = 120, 24
    local rowGap = 52

    local function MakeActionBtn(label, desc, offsetY, onClick)
        local btn = CreateFrame("Button", nil, actBox, "UIPanelButtonTemplate")
        btn:SetSize(bW, bH); btn:SetPoint("TOPLEFT", actBox, "TOPLEFT", bx, offsetY)
        btn:SetText(label)
        btn:SetScript("OnClick", onClick)
        local note = actBox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        note:SetPoint("TOPLEFT", btn, "TOPRIGHT", 8, -4)
        note:SetWidth(180); note:SetJustifyH("LEFT")
        note:SetText("|cffaaaaaa" .. desc .. "|r")
        return btn
    end

    MakeActionBtn("Load Profile", "Switch to the selected profile and apply its settings.", by, function()
        if not selectedProfile then return end
        local name = selectedProfile
        StaticPopupDialogs["UFL_LOAD_PROFILE"] = {
            text = "Load profile \"" .. name .. "\"?\nThis will apply its settings and make it the active profile.",
            button1 = "Yes", button2 = "Cancel",
            OnAccept = function()
                if UnitFramesLite_ProfileSetDefault then UnitFramesLite_ProfileSetDefault(name) end
                RefreshProfilePanel()
                for _, p in pairs(unitPanels) do if p.refresh then p:refresh() end end
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show("UFL_LOAD_PROFILE")
    end)

    MakeActionBtn("Copy From", "Apply settings from the selected profile without changing the active profile.", by - rowGap, function()
        if not selectedProfile then return end
        local name = selectedProfile
        StaticPopupDialogs["UFL_COPY_PROFILE"] = {
            text = "Copy settings from \"" .. name .. "\"?\nYour active profile will remain unchanged.",
            button1 = "Yes", button2 = "Cancel",
            OnAccept = function()
                if UnitFramesLite_ProfileCopyFrom then UnitFramesLite_ProfileCopyFrom(name) end
                for _, p in pairs(unitPanels) do if p.refresh then p:refresh() end end
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show("UFL_COPY_PROFILE")
    end)

    MakeActionBtn("Save to Profile", "Overwrite the selected profile with your current settings.", by - rowGap * 2, function()
        if not selectedProfile then return end
        local name = selectedProfile
        StaticPopupDialogs["UFL_SAVE_PROFILE"] = {
            text = "Overwrite profile \"" .. name .. "\" with current settings?",
            button1 = "Yes", button2 = "Cancel",
            OnAccept = function()
                if UnitFramesLite_ProfileCreate then UnitFramesLite_ProfileCreate(name) end
                RefreshProfilePanel()
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show("UFL_SAVE_PROFILE")
    end)

    MakeActionBtn("Delete Profile", "Permanently remove the selected profile.", by - rowGap * 3, function()
        if not selectedProfile then return end
        local name = selectedProfile
        StaticPopupDialogs["UFL_DEL_PROFILE"] = {
            text = "Permanently delete profile \"" .. name .. "\"?",
            button1 = "Yes", button2 = "Cancel",
            OnAccept = function()
                if UnitFramesLite_ProfileDelete then UnitFramesLite_ProfileDelete(name) end
                selectedProfile = nil
                RefreshSelDD(); RefreshProfilePanel()
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show("UFL_DEL_PROFILE")
    end)

    profilesPanel:SetScript("OnShow", function()
        RefreshSelDD(); RefreshProfilePanel()
    end)

    -- ── "Profiles" top-level button beside the unit dropdown ────────────────
    local profilesTabBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    profilesTabBtn:SetSize(76, 22)
    profilesTabBtn:SetText("Profiles")

    profilesTabBtn:SetScript("OnClick", function()
        for _, p in pairs(unitPanels) do p:Hide() end
        profilesPanel:Show()
    end)

    -- Ordered list of all tab buttons for reflow (Profiles last)
    local allTabBtns = {}
    for _, b in ipairs(sharedTabBtns) do allTabBtns[#allTabBtns + 1] = b end
    allTabBtns[#allTabBtns + 1] = profilesTabBtn

    -- TAB_START_X: x offset where the first tab button begins (after "Unit:" + dropdown)
    local TAB_START_X = 210
    local BTN_H       = 22
    local BTN_GAP     = 2
    local ROW1_Y      = -38   -- y for first row (relative to mainFrame TOPLEFT)
    local ROW2_Y      = ROW1_Y - (BTN_H + 4)  -- y for second row when wrapping

    -- These are repositioned by ReflowTabButtons; forward-declare so the divider
    -- and panels can reference them after reflow.
    local function SetContentOffsets(twoRows)
        local divY     = twoRows and (ROW2_Y - BTN_H - 2) or -64
        local panelY   = divY - 4
        divider:ClearAllPoints()
        divider:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  16, divY)
        divider:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -16, divY)
        for _, c in pairs(unitPanels) do
            c:ClearAllPoints()
            c:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     0, panelY)
            c:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
        end
        profilesPanel:ClearAllPoints()
        profilesPanel:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     0, panelY)
        profilesPanel:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    end

    local function ReflowTabButtons()
        local frameW = mainFrame:GetWidth()
        if not frameW or frameW == 0 then return end

        -- Place buttons left-to-right, wrapping to a new row when they would overflow.
        -- Profiles gets an extra 8px left gap to visually separate it from the tab buttons.
        local RIGHT_MARGIN = 16
        local rowYs = {ROW1_Y, ROW2_Y}
        local x   = TAB_START_X
        local row = 1

        for i, btn in ipairs(allTabBtns) do
            local isProfiles = (btn == profilesTabBtn)
            local extraGap   = isProfiles and 8 or 0
            local btnW       = btn:GetWidth()

            -- Wrap to next row if this button (plus its gap) would exceed the right edge
            if row < #rowYs and (x + extraGap + btnW > frameW - RIGHT_MARGIN) then
                row = row + 1
                x   = TAB_START_X
                extraGap = 0  -- no extra gap when starting a new row
            end

            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", x + extraGap, rowYs[row])
            x = x + extraGap + btnW + BTN_GAP
        end

        SetContentOffsets(row > 1)
    end

    -- Initial layout and re-layout on resize
    ReflowTabButtons()
    mainFrame:SetScript("OnSizeChanged", function() ReflowTabButtons() end)

    -- Resize grip (bottom-right corner)
    local sizeGrip = CreateFrame("Button", nil, mainFrame)
    sizeGrip:SetSize(16, 16)
    sizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -4, 4)
    sizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    sizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    sizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    sizeGrip:RegisterForDrag("LeftButton")
    sizeGrip:SetScript("OnDragStart", function() PinToTopLeft(); mainFrame:StartSizing("BOTTOMRIGHT") end)
    sizeGrip:SetScript("OnDragStop",  function() mainFrame:StopMovingOrSizing(); PinToTopLeft() end)
    sizeGrip:SetFrameLevel(sizeGrip:GetFrameLevel() + 10)
end

function UnitFramesLite_ShowOptions()
    local frame = _G.UnitFramesLiteOptions
    if not frame then return end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end
