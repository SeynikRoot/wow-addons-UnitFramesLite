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
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    fs:SetText(label)
    cb:SetChecked(getValue())
    cb:SetScript("OnClick", function(self) setValue(self:GetChecked()) end)
    cb.Refresh = function(self) self:SetChecked(getValue()) end
    return cb
end

local function CreateGroupBox(parent, label, x, y, w, h)
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
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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

    local updating = false
    local function SetVal(v)
        if updating then return end
        v = math.max(minV, math.min(maxV, math.floor(v / step + 0.5) * step))
        getDB()[dbKey] = v
        updating = true; s:SetValue(v); updating = false
        box:SetText(tostring(v))
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
        box:SetText(tostring(v))
    end
    Refresh()
    return s, box, Refresh
end

local function CreateAlphaSliderRow(parent, label, x, y, dbKey, getDB, onChange)
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lbl:SetPoint("TOP", parent, "TOPLEFT", x + 130, y)
    lbl:SetText(label)

    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 20)
    slider:SetWidth(260); slider:SetMinMaxValues(0, 1); slider:SetValueStep(0.01)
    slider:SetObeyStepOnDrag(true)
    slider.Text:SetText(""); slider.Low:SetText("0"); slider.High:SetText("1")

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(45, 20); box:SetPoint("TOP", slider, "BOTTOM", 0, -4); box:SetAutoFocus(false)

    local minus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    minus:SetSize(22, 22); minus:SetPoint("RIGHT", box, "LEFT", -2, 0); minus:SetText("-")
    local plus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    plus:SetSize(22, 22); plus:SetPoint("LEFT", box, "RIGHT", 2, 0); plus:SetText("+")

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
        UIDropDownMenu_Initialize(dd, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            local cur  = getValue()
            for _, name in ipairs(items) do
                info.text    = name
                info.checked = (name == cur)
                info.func    = function()
                    setValue(name)
                    UIDropDownMenu_SetSelectedName(dd, name)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        UIDropDownMenu_SetSelectedName(dd, getValue())
        function dd:SetSelection(name) UIDropDownMenu_SetSelectedName(self, name) end
        return dd
    end
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width + 24, 22); btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetText(tostring(getValue()))
    btn:SetScript("OnClick", function(self)
        local cur = getValue(); local nxt = items[1]
        for i, v in ipairs(items) do if v == cur then nxt = items[i % #items + 1]; break end end
        setValue(nxt); self:SetText(tostring(nxt))
    end)
    function btn:SetSelection(name) self:SetText(tostring(name)) end
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

        -- Right column: Class Resources settings (controls both UFL pips and Blizzard bar)
        local resGroup = CreateGroupBox(content, "Class Resources", 350, -8, 260, 510)
        local function resDB() return UnitFramesLite_GetDB("player") end
        local function applyRes()
            if UnitFramesLite_UpdateResourceLayout then UnitFramesLite_UpdateResourceLayout() end
            if UnitFramesLite_UpdateResourceVisibility then UnitFramesLite_UpdateResourceVisibility() end
        end

        -- Source selection
        CreateLabel(resGroup, "Source", 8, -18)
        CreateCheckbox(resGroup, "Use Blizzard resource bar", 8, -34,
            function() return resDB().useBlizzResource or false end,
            function(v) resDB().useBlizzResource = v; applyRes() end)
        CreateCheckbox(resGroup, "Hide Blizzard resource bar", 8, -60,
            function() return resDB().hideBlizzResourceBar or false end,
            function(v)
                resDB().hideBlizzResourceBar = v
                applyRes()
            end)

        -- Show/hide overall
        local sep1 = resGroup:CreateTexture(nil,"ARTWORK"); sep1:SetColorTexture(0.3,0.3,0.3,0.8); sep1:SetHeight(1)
        sep1:SetPoint("TOPLEFT",resGroup,"TOPLEFT",8,-84); sep1:SetPoint("TOPRIGHT",resGroup,"TOPRIGHT",-8,-84)
        CreateLabel(resGroup, "Visibility", 8, -94)
        CreateCheckbox(resGroup, "Show resource bar", 8, -110,
            function() return resDB().showResources ~= false end,
            function(v) resDB().showResources = v; applyRes() end)
        CreateCheckbox(resGroup, "Show in combat", 8, -136,
            function() return resDB().resourceShowInCombat or false end,
            function(v) resDB().resourceShowInCombat = v; applyRes() end)
        CreateCheckbox(resGroup, "Also show with target selected", 8, -160,
            function() return resDB().resourceShowWithTarget or false end,
            function(v) resDB().resourceShowWithTarget = v; applyRes() end)

        -- Alpha
        local sep2 = resGroup:CreateTexture(nil,"ARTWORK"); sep2:SetColorTexture(0.3,0.3,0.3,0.8); sep2:SetHeight(1)
        sep2:SetPoint("TOPLEFT",resGroup,"TOPLEFT",8,-184); sep2:SetPoint("TOPRIGHT",resGroup,"TOPRIGHT",-8,-184)
        CreateLabel(resGroup, "Alpha", 8, -194)
        local _,_,rAlpha = CreateAlphaSliderRow(resGroup,"",8,-214,"resourceAlpha",resDB,applyRes)

        -- Position and size (UFL pips only)
        local sep3 = resGroup:CreateTexture(nil,"ARTWORK"); sep3:SetColorTexture(0.3,0.3,0.3,0.8); sep3:SetHeight(1)
        sep3:SetPoint("TOPLEFT",resGroup,"TOPLEFT",8,-270); sep3:SetPoint("TOPRIGHT",resGroup,"TOPRIGHT",-8,-270)
        CreateLabel(resGroup, "UFL Pips Position & Size", 8, -280)
        local _,_,rPipW   = CreateNudgeSlider(resGroup,"Pip Width",  6,40,1, 8,-302,80,"resourcePipWidth",  resDB,applyRes)
        local _,_,rPipH   = CreateNudgeSlider(resGroup,"Pip Height", 3,20,1, 8,-342,80,"resourcePipHeight", resDB,applyRes)
        local _,_,rPipGap = CreateNudgeSlider(resGroup,"Pip Gap",    0,10,1, 8,-382,80,"resourcePipGap",    resDB,applyRes)
        local _,_,rResX   = CreateNudgeSlider(resGroup,"X Offset",-300,300,1,8,-422,80,"resourceX",         resDB,applyRes)
        local _,_,rResY   = CreateNudgeSlider(resGroup,"Y Offset", -50, 50,1,8,-462,80,"resourceY",         resDB,applyRes)
    end
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

-- Tab 3: Bar -----------------------------------------------------------------

local function BuildBarContent(content, unit, getDB, panel)
    local x = 16; local s, b, r
    local halfW = math.floor(UIParent:GetWidth()  / 2)
    local halfH = math.floor(UIParent:GetHeight() / 2)
    local gx = 8

    -- Position and size at the top (moved here from General tab) --------------
    local posGroup = CreateGroupBox(content, "Position", x, -8, 300, 102)
    s,b,r = CreateNudgeSlider(posGroup,"X Offset",-halfW,halfW,1, gx,-20,168,"x",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.xSlider,panel.xBox,panel.xRefresh = s,b,r
    s,b,r = CreateNudgeSlider(posGroup,"Y Offset",-halfH,halfH,1, gx,-58,168,"y",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.ySlider,panel.yBox,panel.yRefresh = s,b,r

    local sizeGroup = CreateGroupBox(content, "Frame Size", x, -120, 300, 102)
    s,b,r = CreateNudgeSlider(sizeGroup,"Width",60,500,1, gx,-20,168,"frameWidth",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.widthSlider,panel.widthBox,panel.widthRefresh = s,b,r
    s,b,r = CreateNudgeSlider(sizeGroup,"Height",12,120,1, gx,-58,168,"frameHeight",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.heightSlider,panel.heightBox,panel.heightRefresh = s,b,r

    panel.reverseFillCheck = CreateCheckbox(content, "Reverse fill (HP/Power)", x, -234,
        function() return getDB().reverseFill or false end,
        function(v) getDB().reverseFill = v; UnitFramesLite_UpdateFrame(unit) end)

    -- Portrait group box -------------------------------------------------------
    -- Height 260 when unclamped controls are shown; we fix at 260 and show/hide.
    local portGroup = CreateGroupBox(content, "Portrait", x, -258, 300, 260)
    local pgx = 8

    -- Mode row
    CreateLabel(portGroup, "Mode", pgx, -20)
    panel.portraitModeDD = CreateDropdown(portGroup, pgx+44, -18, 120, portraitModeOptions,
        function() return getDB().portraitMode or "None" end,
        function(v) getDB().portraitMode = v; UnitFramesLite_UpdateFrame(unit); panel:UpdatePortraitMode() end)

    -- Side row
    CreateLabel(portGroup, "Side", pgx, -52)
    panel.portraitSideDD = CreateDropdown(portGroup, pgx+44, -50, 100, portraitSideOptions,
        function() return getDB().portraitSide or "Left" end,
        function(v) getDB().portraitSide = v; UnitFramesLite_UpdateFrame(unit) end)

    -- Clamp checkbox — label includes unit name
    local unitLabel = unit:sub(1,1):upper() .. unit:sub(2)  -- "Player", "Target" etc.
    panel.portraitClampCheck = CreateCheckbox(portGroup, "Clamp to " .. unitLabel .. " frame", pgx, -84,
        function() return getDB().portraitClamp ~= false end,
        function(v) getDB().portraitClamp = v; UnitFramesLite_UpdateFrame(unit); panel:UpdatePortraitMode() end)

    -- Unclamped size/position controls (shown when clamp is OFF)
    local unclampedGroup = CreateFrame("Frame", nil, portGroup)
    unclampedGroup:SetPoint("TOPLEFT", portGroup, "TOPLEFT", 0, -108)
    unclampedGroup:SetSize(290, 148)
    panel.portraitUnclampedGroup = unclampedGroup

    s,b,r = CreateNudgeSlider(unclampedGroup,"Width",12,300,1, pgx,-4,140,"portraitW",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.portraitWSlider,panel.portraitWBox,panel.portraitWRefresh = s,b,r
    s,b,r = CreateNudgeSlider(unclampedGroup,"Height",12,300,1, pgx,-42,140,"portraitH",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.portraitHSlider,panel.portraitHBox,panel.portraitHRefresh = s,b,r
    s,b,r = CreateNudgeSlider(unclampedGroup,"X Offset",-500,500,1, pgx,-80,140,"portraitX",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.portraitXSlider,panel.portraitXBox,panel.portraitXRefresh = s,b,r
    s,b,r = CreateNudgeSlider(unclampedGroup,"Y Offset",-500,500,1, pgx,-118,140,"portraitY",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.portraitYSlider,panel.portraitYBox,panel.portraitYRefresh = s,b,r

    -- legacy stub so panel:refresh() line "panel.portraitDD:SetSelection" doesn't error
    panel.portraitDD = CreateDropdown(content, -9999, 0, 80, portraitOptions,
        function() return getDB().portrait or "Portrait Off" end,
        function(v) getDB().portrait = v end)

    panel.UpdatePortraitMode = function(self)
        local isNone   = (getDB().portraitMode or "None") == "None"
        local isClamped = getDB().portraitClamp ~= false
        self.portraitSideDD:SetShown(not isNone)
        self.portraitClampCheck:SetShown(not isNone)
        self.portraitUnclampedGroup:SetShown(not isNone and not isClamped)
    end
    panel:UpdatePortraitMode()

    -- Left column (x=16, y start -526) ----------------------------------------
    CreateLabel(content, "Bar", x, -526)
    local bgBtn = CreateColorSwatch(content, x, -546, "Background Colour", getDB, "barBG", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = bgBtn

    panel.showPowerCheck = CreateCheckbox(content, "Show power bar", x, -594,
        function() return getDB().showPowerBar or false end,
        function(v) getDB().showPowerBar = v; UnitFramesLite_UpdateFrame(unit) end)

    s,b,r = CreateNudgeSlider(content,"HP Bar Height (0 = full frame height)",0,120,1, x,-628,200,"hpBarHeight",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.hpBarHeightSlider,panel.hpBarHeightBox,panel.hpBarHeightRefresh = s,b,r

    CreateLabel(content, "Statusbar Texture (solid colour mode only)", x, -666)
    panel.texDD = CreateDropdown(content, x, -684, 200, GetTextureList(),
        function() return getDB().statusbarTexture or "Blizzard" end,
        function(v) getDB().statusbarTexture = v; UnitFramesLite_UpdateFrame(unit) end)

    -- Right column (x=340, y start -8) ----------------------------------------
    local rx = 340
    CreateLabel(content, "Colour Mode", rx, -8)
    panel.solidCheckbox = CreateCheckbox(content, "Use Solid Colour", rx, -26,
        function() return getDB().useSolidColor or false end,
        function(v) getDB().useSolidColor = v; panel:UpdateColourMode(); UnitFramesLite_UpdateFrame(unit) end)

    local solidBtn  = CreateColorSwatch(content, rx, -64, "Solid Colour",    getDB, "solidColor",    function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = solidBtn
    local gradSBtn  = CreateColorSwatch(content, rx, -64, "Gradient Start Colour", getDB, "gradientStart", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = gradSBtn
    local gradEBtn  = CreateColorSwatch(content, rx, -94, "Gradient End Colour",   getDB, "gradientEnd",   function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = gradEBtn
    local gradDirLabel = CreateLabel(content, "Direction", rx, -126)
    panel.dirDD = CreateDropdown(content, rx, -144, 120, dirOptions,
        function() return getDB().gradientDir or "HORIZONTAL" end,
        function(v) getDB().gradientDir = v; UnitFramesLite_UpdateFrame(unit) end)

    panel.solidGroup    = {solidBtn}
    panel.gradientGroup = {gradSBtn, gradEBtn, gradDirLabel, panel.dirDD}

    -- Bar Border section: below both columns ----------------------------------
    local sep = content:CreateTexture(nil,"ARTWORK"); sep:SetColorTexture(0.3,0.3,0.3,0.8); sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",content,"TOPLEFT",x,-716); sep:SetPoint("TOPRIGHT",content,"TOPRIGHT",-x,-716)

    CreateLabel(content, "Bar Border", x, -726)
    panel.barBorderCheck = CreateCheckbox(content, "Enabled", x+84, -726,
        function() return getDB().barBorderEnabled or false end,
        function(v) getDB().barBorderEnabled = v; UnitFramesLite_UpdateFrame(unit) end)
    s,b,r = CreateNudgeSlider(content,"Border Thickness",1,20,1, x,-754,160,"barBorderThickness",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.borderThicknessSlider,panel.borderThicknessBox,panel.borderThicknessRefresh = s,b,r
    local borderBtn = CreateColorSwatch(content, x, -792, "Border Colour", getDB, "barBorderColor", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = borderBtn
end

-- Tab 4: Orb -----------------------------------------------------------------

local function BuildOrbContent(content, unit, getDB, panel)
    local x = 16; local s, b, r
    local halfW = math.floor(UIParent:GetWidth()  / 2)
    local halfH = math.floor(UIParent:GetHeight() / 2)
    local gx = 8

    -- Position and size at the top (moved here from General tab) --------------
    local posGroup = CreateGroupBox(content, "Position", x, -8, 300, 102)
    s,b,r = CreateNudgeSlider(posGroup,"X Offset",-halfW,halfW,1, gx,-20,168,"x",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.xSlider,panel.xBox,panel.xRefresh = s,b,r
    s,b,r = CreateNudgeSlider(posGroup,"Y Offset",-halfH,halfH,1, gx,-58,168,"y",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.ySlider,panel.yBox,panel.yRefresh = s,b,r

    local sizeGroup = CreateGroupBox(content, "Frame Size", x, -120, 300, 102)
    s,b,r = CreateNudgeSlider(sizeGroup,"Width",60,500,1, gx,-20,168,"frameWidth",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.widthSlider,panel.widthBox,panel.widthRefresh = s,b,r
    s,b,r = CreateNudgeSlider(sizeGroup,"Height",12,120,1, gx,-58,168,"frameHeight",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.heightSlider,panel.heightBox,panel.heightRefresh = s,b,r

    panel.reverseFillCheck = CreateCheckbox(content, "Reverse fill (HP/Power)", x, -234,
        function() return getDB().reverseFill or false end,
        function(v) getDB().reverseFill = v; UnitFramesLite_UpdateFrame(unit) end)

    -- Portrait stub (not shown on Orb tab but referenced by panel:refresh)
    panel.portraitDD = CreateDropdown(content, -9999, 0, 80, portraitOptions,
        function() return getDB().portrait or "Portrait Off" end,
        function(v) getDB().portrait = v end)

    -- Orb / sphere controls ---------------------------------------------------
    CreateLabel(content, "Orb / Sphere Mode", x, -262)
    panel.sphereModeCheck = CreateCheckbox(content, "Enable sphere mode", x, -280,
        function() return getDB().sphereMode or false end,
        function(v) getDB().sphereMode = v; UnitFramesLite_UpdateFrame(unit) end)

    s,b,r = CreateNudgeSlider(content,"Sphere Diameter (px)",20,300,1, x,-312,180,"sphereSize",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.sphereSizeSlider,panel.sphereSizeBox,panel.sphereSizeRefresh = s,b,r

    CreateLabel(content, "Fill Direction", x, -356)
    panel.sphereFillDirDD = CreateDropdown(content, x, -374, 140, fillDirOptions,
        function() return getDB().sphereFillDir or "VERTICAL" end,
        function(v) getDB().sphereFillDir = v; UnitFramesLite_UpdateFrame(unit) end)
    CreateLabel(content, "Gradient Direction", x, -412)
    panel.orbGradDirDD = CreateDropdown(content, x, -430, 140, {"VERTICAL","HORIZONTAL","CENTRE"},
        function() return getDB().orbGradientDir or "VERTICAL" end,
        function(v) getDB().orbGradientDir = v; UnitFramesLite_UpdateFrame(unit) end)

    -- Orb colour
    local sep1 = content:CreateTexture(nil,"ARTWORK"); sep1:SetColorTexture(0.3,0.3,0.3,0.8); sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT",content,"TOPLEFT",x,-456); sep1:SetPoint("TOPRIGHT",content,"TOPRIGHT",-x,-456)

    CreateLabel(content, "Orb Colour", x, -466)
    panel.orbSolidCheck = CreateCheckbox(content, "Use Solid Colour", x, -484,
        function() return getDB().orbUseSolidColor or false end,
        function(v) getDB().orbUseSolidColor = v; panel:UpdateOrbColourMode(); UnitFramesLite_UpdateFrame(unit) end)

    local orbSolidBtn  = CreateColorSwatch(content, x, -518, "Solid Colour",          getDB, "orbSolidColor",    function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = orbSolidBtn

    local orbGSBtn = CreateColorSwatch(content, x,     -518, "Gradient Start Colour", getDB, "orbGradientStart", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = orbGSBtn
    local orbGEBtn = CreateColorSwatch(content, x,     -548, "Gradient End Colour",   getDB, "orbGradientEnd",   function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = orbGEBtn

    panel.orbSolidGroup    = {orbSolidBtn}
    panel.orbGradientGroup = {orbGSBtn, orbGEBtn}

    panel.UpdateOrbColourMode = function(self)
        local isSolid = getDB().orbUseSolidColor
        for _, w in ipairs(self.orbSolidGroup    or {}) do w:SetShown(isSolid)     end
        for _, w in ipairs(self.orbGradientGroup or {}) do w:SetShown(not isSolid) end
    end
    panel:UpdateOrbColourMode()

    -- Inner border
    local sep2 = content:CreateTexture(nil,"ARTWORK"); sep2:SetColorTexture(0.3,0.3,0.3,0.8); sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",content,"TOPLEFT",x,-578); sep2:SetPoint("TOPRIGHT",content,"TOPRIGHT",-x,-578)

    CreateLabel(content, "Inner Border", x, -588)
    panel.showOrbBorderCheck = CreateCheckbox(content, "Show border around health orb", x, -606,
        function() return getDB().showOrbBorder or false end,
        function(v) getDB().showOrbBorder = v; UnitFramesLite_UpdateFrame(unit) end)

    local s2,b2,r2 = CreateNudgeSlider(content,"Border Thickness (px)",1,40,1, x,-642,160,"orbBorderThickness",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.orbBorderThickSlider,panel.orbBorderThickBox,panel.orbBorderThickRefresh = s2,b2,r2

    local borderBtn = CreateColorSwatch(content, x, -696, "Border Colour", getDB, "orbBorderColor", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = borderBtn

    -- Power ring
    local sep3 = content:CreateTexture(nil,"ARTWORK"); sep3:SetColorTexture(0.3,0.3,0.3,0.8); sep3:SetHeight(1)
    sep3:SetPoint("TOPLEFT",content,"TOPLEFT",x,-726); sep3:SetPoint("TOPRIGHT",content,"TOPRIGHT",-x,-726)

    CreateLabel(content, "Power Ring", x, -736)
    panel.showOrbPowerCheck = CreateCheckbox(content, "Show power ring around orb", x, -754,
        function() return getDB().showOrbPower or false end,
        function(v) getDB().showOrbPower = v; UnitFramesLite_UpdateFrame(unit) end)

    local s,b,r = CreateNudgeSlider(content,"Ring Thickness (px)",4,40,1, x,-790,160,"orbPowerRingThickness",getDB,function() UnitFramesLite_UpdateFrame(unit) end)
    panel.ringThickSlider,panel.ringThickBox,panel.ringThickRefresh = s,b,r

    local ringBgBtn = CreateColorSwatch(content, x, -832, "Ring Background Colour", getDB, "orbPowerRingBgColor", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = ringBgBtn

    panel.ringCCWCheck = CreateCheckbox(content, "Counter-clockwise drain", x, -862,
        function() return getDB().orbPowerRingCCW or false end,
        function(v) getDB().orbPowerRingCCW = v; UnitFramesLite_UpdateFrame(unit) end)

    panel.ringTypeColorCheck = CreateCheckbox(content, "Use power type colour", x, -890,
        function() return getDB().orbPowerRingUseTypeColor ~= false end,
        function(v)
            getDB().orbPowerRingUseTypeColor = v
            panel:UpdateRingColourMode()
            UnitFramesLite_UpdateFrame(unit)
        end)

    local ringColBtn = CreateColorSwatch(content, x, -920, "Ring Colour", getDB, "orbPowerRingColor", function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons+1] = ringColBtn
    panel.ringColBtn = ringColBtn

    panel.UpdateRingColourMode = function(self)
        local useType = getDB().orbPowerRingUseTypeColor ~= false
        ringColBtn:SetShown(not useType)
    end
    panel:UpdateRingColourMode()
end

-- Tab 5: Conditions (includes Alpha section) ---------------------------------

local function BuildConditionsContent(content, unit, getDB, panel)
    local x = 16
    -- Left column: Load Conditions --------------------------------------------
    CreateLabel(content, "Load Conditions", x, -8)
    CreateLabel(content, "Show this frame only when checked conditions are met.\nIf none are checked, the frame is always shown.", x, -26)
    local condDefs = {
        {"Mounted","loadMounted",1,1}, {"In vehicle","loadInVehicle",1,2},
        {"Resting","loadResting",1,3}, {"Stealthed","loadStealthed",1,4},
        {"In combat","loadInCombat",1,5},
        {"Out of combat","loadOutOfCombat",2,1}, {"Solo","loadSolo",2,2},
        {"In group","loadInGroup",2,3}, {"In instance","loadInInstance",2,4},
    }
    local colX = {x, x+200}; local startY = -72; local rowH = 32
    panel.conditionChecks = {}
    for _, def in ipairs(condDefs) do
        local label, key, col, row = def[1], def[2], def[3], def[4]
        local cb = CreateCheckbox(content, label, colX[col], startY - (row-1)*rowH,
            function() return getDB()[key] or false end,
            function(v) getDB()[key] = v; UnitFramesLite_UpdateVisibility(unit) end)
        panel.conditionChecks[key] = cb
    end

    -- Right column (x=340): Alpha section starting at y=-8 -------------------
    local ax = 340
    local ay = -8
    CreateLabel(content, "Alpha", ax, ay)
    panel.syncAlphaCheck = CreateCheckbox(content, "Sync both", ax+220, ay,
        function() return getDB().syncAlpha or false end,
        function(v) getDB().syncAlpha = v; UnitFramesLite_UpdateAlpha(unit) end)
    panel.keepTextVisCheck = CreateCheckbox(content, "Keep text + portrait visible", ax, ay-28,
        function() return getDB().keepTextVisible or false end,
        function(v) getDB().keepTextVisible = v; UnitFramesLite_UpdateAlpha(unit) end)
    CreateLabel(content, "Alpha sliders affect", ax, ay-60)
    panel.alphaAffectsDD = CreateDropdown(content, ax+150, ay-78, 120, alphaAffectsOptions,
        function() return getDB().alphaAffects or "Everything" end,
        function(v) getDB().alphaAffects = v; UnitFramesLite_UpdateAlpha(unit) end)

    local _,_,rCombat    = CreateAlphaSliderRow(content,"Alpha in combat",    ax,ay-120,"alphaCombat",   getDB,function() UnitFramesLite_UpdateAlpha(unit) end)
    local _,_,rOutCombat = CreateAlphaSliderRow(content,"Alpha out of combat", ax,ay-210,"alphaOutCombat",getDB,function() UnitFramesLite_UpdateAlpha(unit) end)

    local sep2 = content:CreateTexture(nil,"ARTWORK"); sep2:SetColorTexture(0.3,0.3,0.3,0.8); sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",content,"TOPLEFT",ax,ay-296); sep2:SetPoint("TOPRIGHT",content,"TOPRIGHT",-16,ay-296)
    CreateLabel(content, "Fade Conditions", ax, ay-306)
    panel.fadeNoTargetCheck = CreateCheckbox(content, "Fade when no target selected", ax, ay-324,
        function() return getDB().fadeNoTarget or false end,
        function(v) getDB().fadeNoTarget = v; UnitFramesLite_UpdateAlpha(unit) end)
    local _,_,rFade = CreateAlphaSliderRow(content,"Fade alpha",ax,ay-360,"fadeNoTargetAlpha",getDB,function() UnitFramesLite_UpdateAlpha(unit) end)

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
    panel.UpdatePortraitMode = function() end  -- overwritten by BuildBarContent

    -- Tab buttons are created externally (on the main frame header).
    -- We only create scroll frames + content here.
    local tabNames        = {"General", "Text", "Bar", "Orb", "Conditions"}
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

    BuildGeneralContent(tabContents[1],    unit, getDB, panel)
    BuildTextContent(tabContents[2],       unit, getDB, panel)
    BuildBarContent(tabContents[3],        unit, getDB, panel)
    BuildOrbContent(tabContents[4],        unit, getDB, panel)
    BuildConditionsContent(tabContents[5], unit, getDB, panel)

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
        self.solidCheckbox:Refresh(); self.showPowerCheck:Refresh()
        if self.dirDD then self.dirDD:SetSelection(db.gradientDir or "HORIZONTAL") end
        self.hpBarHeightRefresh(); self.barBorderCheck:Refresh(); self.borderThicknessRefresh()
        self.sphereModeCheck:Refresh(); self.sphereSizeRefresh()
        self.sphereFillDirDD:SetSelection(db.sphereFillDir or "VERTICAL")
        self.orbGradDirDD:SetSelection(db.orbGradientDir or "VERTICAL")
        self.orbSolidCheck:Refresh()
        self.showOrbBorderCheck:Refresh(); self.orbBorderThickRefresh()
        self.showOrbPowerCheck:Refresh(); self.ringThickRefresh()
        self.ringCCWCheck:Refresh(); self.ringTypeColorCheck:Refresh()
        for _, cb in pairs(self.conditionChecks or {}) do cb:Refresh() end
        if self.refreshAlpha then self:refreshAlpha() end
        for _, btn in ipairs(self.swatchButtons) do btn:RefreshSwatch() end
        self:UpdateColourMode()
        self:UpdateOrbColourMode()
        self:UpdateRingColourMode()
        self:UpdatePortraitMode()
    end

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 22); resetBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 12)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        local key = "UFL_RESET_" .. unit:upper()
        StaticPopupDialogs[key] = {
            text = "Reset " .. unit .. " settings to defaults?",
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

    panel:SetScript("OnShow", function(self)
        self:refresh()
        SelectTab(tabSync.current or 1)
    end)
    panel:UpdateColourMode()
    panel:UpdatePortraitMode()
end

-- Main options frame ---------------------------------------------------------

function CreateOptionsPanel()
    local OPTS_W, OPTS_H = 700, 620

    local mainFrame = CreateFrame("Frame", "UnitFramesLiteOptions", UIParent, "BackdropTemplate")
    mainFrame:SetSize(OPTS_W, OPTS_H); mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("HIGH"); mainFrame:SetMovable(true); mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing)
    mainFrame:SetResizable(true)
    mainFrame:SetResizeBounds(500, 400, 1400, 900)
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

    local function SelectUnit(unit)
        profilesPanel:Hide()
        for _, p in pairs(unitPanels) do p:Hide() end
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
    local tabNames = {"General", "Text", "Bar", "Orb", "Conditions"}
    local sharedTabBtns = {}
    for i, name in ipairs(tabNames) do
        local btn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        btn:SetSize(76, 22); btn:SetText(name)
        if i == 1 then btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 210, -38)
        else            btn:SetPoint("LEFT", sharedTabBtns[i-1], "RIGHT", 2, 0) end
        sharedTabBtns[i] = btn
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

    local px, py = 24, -20

    -- Current profile display
    local curLbl = profilesPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    curLbl:SetPoint("TOPLEFT", profilesPanel, "TOPLEFT", px, py)
    curLbl:SetText("Active profile: |cffffd700Default|r")

    local function RefreshProfilePanel()
        local p = UnitFramesLiteDB and UnitFramesLiteDB.profiles
        local active = (p and p.active) or "Default"
        curLbl:SetText("Active profile: |cffffd700" .. active .. "|r")
    end

    -- ── Create New Profile ──────────────────────────────────────────────────
    local createBox = CreateGroupBox(profilesPanel, "Create New Profile", px, py - 30, 300, 66)
    local nameEdit = CreateFrame("EditBox", nil, createBox, "InputBoxTemplate")
    nameEdit:SetSize(160, 20); nameEdit:SetPoint("TOPLEFT", createBox, "TOPLEFT", 8, -24)
    nameEdit:SetAutoFocus(false); nameEdit:SetMaxLetters(40)
    local createBtn = CreateFrame("Button", nil, createBox, "UIPanelButtonTemplate")
    createBtn:SetSize(100, 22); createBtn:SetPoint("LEFT", nameEdit, "RIGHT", 6, 0)
    createBtn:SetText("Create & Save")
    createBtn:SetScript("OnClick", function()
        local name = nameEdit:GetText():match("^%s*(.-)%s*$")
        if name == "" then return end
        if UnitFramesLite_ProfileCreate then UnitFramesLite_ProfileCreate(name) end
        nameEdit:SetText("")
        RefreshProfilePanel()
    end)

    -- ── Profile Selector (shared dropdown) ──────────────────────────────────
    local selGroup = CreateGroupBox(profilesPanel, "Select Profile", px, py - 116, 300, 200)
    local selectedProfile = nil

    -- We need a mutable dropdown; rebuild its items on refresh
    local selDD
    local function GetSelDropdownValue() return selectedProfile or "(none)" end
    local function SetSelDropdownValue(v)
        selectedProfile = (v ~= "(none)") and v or nil
    end
    selDD = CreateDropdown(selGroup, 8, -24, 240, GetProfileList(), GetSelDropdownValue, SetSelDropdownValue)

    local function RefreshSelDD()
        local list = GetProfileList()
        -- Validate selectedProfile is still in the list
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

    -- Set Default button
    local setDefBtn = CreateFrame("Button", nil, selGroup, "UIPanelButtonTemplate")
    setDefBtn:SetSize(130, 22); setDefBtn:SetPoint("TOPLEFT", selGroup, "TOPLEFT", 8, -60)
    setDefBtn:SetText("Load Profile")
    setDefBtn:SetScript("OnClick", function()
        if not selectedProfile then return end
        if UnitFramesLite_ProfileSetDefault then UnitFramesLite_ProfileSetDefault(selectedProfile) end
        RefreshProfilePanel()
        -- Refresh all unit panels
        for _, p in pairs(unitPanels) do if p.refresh then p:refresh() end end
    end)

    local setDefNote = selGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    setDefNote:SetPoint("LEFT", setDefBtn, "RIGHT", 6, 0)
    setDefNote:SetText("|cffaaaaaaLoads settings from the selected profile|r")

    -- Copy From button (loads but keeps active profile unchanged)
    local copyFBtn = CreateFrame("Button", nil, selGroup, "UIPanelButtonTemplate")
    copyFBtn:SetSize(130, 22); copyFBtn:SetPoint("TOPLEFT", selGroup, "TOPLEFT", 8, -90)
    copyFBtn:SetText("Copy From")
    copyFBtn:SetScript("OnClick", function()
        if not selectedProfile then return end
        if UnitFramesLite_ProfileCopyFrom then UnitFramesLite_ProfileCopyFrom(selectedProfile) end
        for _, p in pairs(unitPanels) do if p.refresh then p:refresh() end end
    end)

    local copyFNote = selGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    copyFNote:SetPoint("LEFT", copyFBtn, "RIGHT", 6, 0)
    copyFNote:SetText("|cffaaaaaaApply settings without changing active profile|r")

    -- Save to Profile button (overwrites the selected profile with current settings)
    local saveBtn = CreateFrame("Button", nil, selGroup, "UIPanelButtonTemplate")
    saveBtn:SetSize(130, 22); saveBtn:SetPoint("TOPLEFT", selGroup, "TOPLEFT", 8, -120)
    saveBtn:SetText("Save to Profile")
    saveBtn:SetScript("OnClick", function()
        if not selectedProfile then return end
        if UnitFramesLite_ProfileCreate then UnitFramesLite_ProfileCreate(selectedProfile) end
        RefreshProfilePanel()
    end)

    local saveBtnNote = selGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    saveBtnNote:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    saveBtnNote:SetText("|cffaaaaaaOverwrite selected profile with current settings|r")

    -- Delete button
    local delBtn = CreateFrame("Button", nil, selGroup, "UIPanelButtonTemplate")
    delBtn:SetSize(130, 22); delBtn:SetPoint("TOPLEFT", selGroup, "TOPLEFT", 8, -150)
    delBtn:SetText("Delete Profile")
    delBtn:SetScript("OnClick", function()
        if not selectedProfile then return end
        local name = selectedProfile
        StaticPopupDialogs["UFL_DEL_PROFILE"] = {
            text = "Delete profile \"" .. name .. "\"?",
            button1 = YES, button2 = NO,
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
    profilesTabBtn:SetPoint("LEFT", sharedTabBtns[#sharedTabBtns], "RIGHT", 10, 0)
    profilesTabBtn:SetText("Profiles")

    profilesTabBtn:SetScript("OnClick", function()
        for _, p in pairs(unitPanels) do p:Hide() end
        profilesPanel:Show()
    end)

    -- Resize grip (bottom-right corner)
    local sizeGrip = CreateFrame("Button", nil, mainFrame)
    sizeGrip:SetSize(16, 16)
    sizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -4, 4)
    sizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    sizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    sizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    sizeGrip:SetScript("OnMouseDown", function() mainFrame:StartSizing("BOTTOMRIGHT") end)
    sizeGrip:SetScript("OnMouseUp",   function() mainFrame:StopMovingOrSizing() end)
    sizeGrip:SetFrameLevel(sizeGrip:GetFrameLevel() + 10)
end

function UnitFramesLite_ShowOptions()
    local frame = _G.UnitFramesLiteOptions
    if not frame then return end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end
