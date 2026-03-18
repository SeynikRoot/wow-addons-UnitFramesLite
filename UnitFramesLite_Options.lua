local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local function GetFontList()
    if not LSM then return {"Friz Quadrata TT"} end
    local list = LSM:List("font"); table.sort(list); return list
end

local function GetTextureList()
    if not LSM then return {"Blizzard"} end
    local list = LSM:List("statusbar"); table.sort(list); return list
end

-- UI helpers ----------------------------------------------------------------

local function CreateLabel(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function CreateNumberBox(parent, width, x, y, onChanged)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, 20)
    eb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    eb:SetAutoFocus(false)
    eb:SetNumeric(true)
    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local v = tonumber(self:GetText())
        if v then onChanged(v) end
    end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return eb
end

local function CreateSlider(parent, label, minVal, maxVal, step, x, y, onChanged)
    local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    s:SetMinMaxValues(minVal, maxVal)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s.Text:SetText(label)
    s.Low:SetText(tostring(minVal))
    s.High:SetText(tostring(maxVal))
    s:SetScript("OnValueChanged", function(self, v) onChanged(v) end)
    return s
end

-- Dropdown: UIDropDownMenu if available, otherwise a simple cycle button.
-- UIDropDownMenu was deprecated in Dragonflight and may be absent in 12.0.
-- x is the visual left edge; the function handles template offset internally.
local function CreateDropdown(parent, x, y, width, items, getValue, setValue)
    if UIDropDownMenu_Initialize then
        local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, y)   -- template has 16px left pad
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

    -- Fallback: click cycles through values
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width + 24, 22)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetText(tostring(getValue()))
    btn:SetScript("OnClick", function(self)
        local cur = getValue()
        local nxt = items[1]
        for i, v in ipairs(items) do
            if v == cur then nxt = items[i % #items + 1]; break end
        end
        setValue(nxt)
        self:SetText(tostring(nxt))
    end)
    function btn:SetSelection(name) self:SetText(tostring(name)) end
    return btn
end

-- Color swatch button: small preview square + opens the color picker
local function CreateColorSwatch(parent, x, y, getDB, key, callback)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(90, 22)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetText("  Pick...")

    local swatch = btn:CreateTexture(nil, "OVERLAY")
    swatch:SetSize(12, 12)
    swatch:SetPoint("LEFT", btn, "LEFT", 6, 0)

    local function RefreshSwatch()
        local c = getDB()[key] or {1, 1, 1, 1}
        swatch:SetColorTexture(c[1], c[2], c[3], 1)
    end
    RefreshSwatch()
    btn.RefreshSwatch = RefreshSwatch

    btn:SetScript("OnClick", function()
        local db = getDB()
        local r, g, b, a = unpack(db[key] or {1, 1, 1, 1})

        if ColorPickerFrame.SetupColorPickerAndShow then
            -- Modern API: Dragonflight / Patch 10.0+
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    local na = ColorPickerFrame:GetColorAlpha()
                    getDB()[key] = {nr, ng, nb, na}
                    RefreshSwatch(); callback()
                end,
                opacityFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    local na = ColorPickerFrame:GetColorAlpha()
                    getDB()[key] = {nr, ng, nb, na}
                    RefreshSwatch(); callback()
                end,
                cancelFunc = function(prev)
                    getDB()[key] = {
                        prev and prev.r       or r,
                        prev and prev.g       or g,
                        prev and prev.b       or b,
                        prev and prev.opacity or a,
                    }
                    RefreshSwatch(); callback()
                end,
                hasOpacity = true,
                opacity    = a,
                r = r, g = g, b = b,
            })
        else
            -- Legacy API: pre-10.0
            ColorPickerFrame.hasOpacity      = true
            ColorPickerFrame.opacity         = 1 - a
            ColorPickerFrame.previousValues  = {r, g, b, a}
            ColorPickerFrame.func = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = 1 - OpacitySliderFrame:GetValue()
                getDB()[key] = {nr, ng, nb, na}
                RefreshSwatch(); callback()
            end
            ColorPickerFrame.cancelFunc = function(prev)
                getDB()[key] = prev or {r, g, b, a}
                RefreshSwatch(); callback()
            end
            ColorPickerFrame:SetColorRGB(r, g, b)
            ColorPickerFrame:Show()
        end
    end)
    return btn
end

-- Unit panel builder --------------------------------------------------------

local alignOptions = {"LEFT", "CENTER", "RIGHT"}
local dirOptions   = {"HORIZONTAL", "VERTICAL"}

local function BuildUnitPanel(panel, unit)
    -- Always read live DB so resets are reflected correctly
    local function getDB() return UnitFramesLite_GetDB(unit) end

    panel.swatchButtons = {}

    -- Refresh: push DB values back into all controls
    panel.refresh = function(self)
        local db = getDB()
        self.xSlider:SetValue(db.x or 0)
        self.xBox:SetText(tostring(db.x or 0))
        self.ySlider:SetValue(db.y or 0)
        self.yBox:SetText(tostring(db.y or 0))
        self.fontSizeSlider:SetValue(db.fontSize or 14)
        self.fontDD:SetSelection(db.font             or "Friz Quadrata TT")
        self.nameAlignDD:SetSelection(db.nameAlign   or "LEFT")
        self.texDD:SetSelection(db.statusbarTexture  or "Blizzard")
        self.dirDD:SetSelection(db.gradientDir       or "HORIZONTAL")
        self.solidCheckbox:SetChecked(db.useSolidColor)
        for _, b in ipairs(self.swatchButtons) do b:RefreshSwatch() end
        self:UpdateColourMode()
    end

    -- Show/hide solid vs gradient controls
    panel.UpdateColourMode = function(self)
        local isSolid = getDB().useSolidColor
        for _, w in ipairs(self.solidGroup)    do w:SetShown(isSolid)     end
        for _, w in ipairs(self.gradientGroup) do w:SetShown(not isSolid) end
    end

    local screenW = UIParent:GetWidth()
    local screenH = UIParent:GetHeight()
    local maxX    = math.floor(screenW / 2)
    local maxY    = math.floor(screenH / 2)
    local leftX   = 16
    local rightX  = 330

    -- == Position section ===================================================
    CreateLabel(panel, "Position", leftX, -16)

    panel.xSlider = CreateSlider(panel, "X Offset", -maxX, maxX, 1, leftX, -38, function(v)
        v = math.floor(v + 0.5)
        getDB().x = v
        panel.xBox:SetText(tostring(v))
        UnitFramesLite_UpdateFrame(unit)
    end)
    panel.xBox = CreateNumberBox(panel, 55, leftX + 248, -44, function(v)
        getDB().x = v; panel.xSlider:SetValue(v); UnitFramesLite_UpdateFrame(unit)
    end)

    panel.ySlider = CreateSlider(panel, "Y Offset", -maxY, maxY, 1, leftX, -78, function(v)
        v = math.floor(v + 0.5)
        getDB().y = v
        panel.yBox:SetText(tostring(v))
        UnitFramesLite_UpdateFrame(unit)
    end)
    panel.yBox = CreateNumberBox(panel, 55, leftX + 248, -84, function(v)
        getDB().y = v; panel.ySlider:SetValue(v); UnitFramesLite_UpdateFrame(unit)
    end)

    -- == Left column: Text ==================================================
    local textY = -130

    CreateLabel(panel, "Text", leftX, textY)

    CreateLabel(panel, "Font", leftX, textY - 20)
    panel.fontDD = CreateDropdown(panel, leftX, textY - 38, 150, GetFontList(),
        function() return getDB().font or "Friz Quadrata TT" end,
        function(v) getDB().font = v; UnitFramesLite_UpdateFrame(unit) end)

    CreateLabel(panel, "Font Size", leftX, textY - 80)
    panel.fontSizeSlider = CreateSlider(panel, "", 8, 24, 1, leftX, textY - 100, function(v)
        getDB().fontSize = math.floor(v + 0.5); UnitFramesLite_UpdateFrame(unit)
    end)

    CreateLabel(panel, "Name Alignment", leftX, textY - 142)
    panel.nameAlignDD = CreateDropdown(panel, leftX, textY - 160, 110, alignOptions,
        function() return getDB().nameAlign or "LEFT" end,
        function(v) getDB().nameAlign = v; UnitFramesLite_UpdateFrame(unit) end)

    CreateLabel(panel, "Name Colour", leftX, textY - 202)
    local nameBtn = CreateColorSwatch(panel, leftX, textY - 220, getDB, "nameColor",
        function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons + 1] = nameBtn

    CreateLabel(panel, "HP Colour", leftX, textY - 258)
    local hpBtn = CreateColorSwatch(panel, leftX, textY - 276, getDB, "hpColor",
        function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons + 1] = hpBtn

    -- == Right column: Bar ==================================================
    local barY = -16

    CreateLabel(panel, "Bar", rightX, barY)

    CreateLabel(panel, "Background Colour", rightX, barY - 20)
    local bgBtn = CreateColorSwatch(panel, rightX, barY - 38, getDB, "barBG",
        function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons + 1] = bgBtn

    CreateLabel(panel, "Statusbar Texture", rightX, barY - 76)
    panel.texDD = CreateDropdown(panel, rightX, barY - 94, 150, GetTextureList(),
        function() return getDB().statusbarTexture or "Blizzard" end,
        function(v) getDB().statusbarTexture = v; UnitFramesLite_UpdateFrame(unit) end)

    -- == Colour mode ========================================================
    local modeY = barY - 140

    CreateLabel(panel, "Colour Mode", rightX, modeY)

    panel.solidCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    panel.solidCheckbox:SetSize(24, 24)
    panel.solidCheckbox:SetPoint("TOPLEFT", panel, "TOPLEFT", rightX, modeY - 18)
    local cbLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    cbLabel:SetPoint("LEFT", panel.solidCheckbox, "RIGHT", 4, 0)
    cbLabel:SetText("Use Solid Colour")
    panel.solidCheckbox:SetChecked(getDB().useSolidColor)
    panel.solidCheckbox:SetScript("OnClick", function(self)
        getDB().useSolidColor = self:GetChecked()
        panel:UpdateColourMode()
        UnitFramesLite_UpdateFrame(unit)
    end)

    -- Solid colour (shown when useSolidColor = true)
    local solidLabel = CreateLabel(panel, "Solid Colour", rightX, modeY - 56)
    local solidBtn   = CreateColorSwatch(panel, rightX, modeY - 74, getDB, "solidColor",
        function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons + 1] = solidBtn

    -- Gradient controls (shown when useSolidColor = false)
    local gradStartLabel = CreateLabel(panel, "Gradient Start", rightX, modeY - 56)
    local gradStartBtn   = CreateColorSwatch(panel, rightX, modeY - 74, getDB, "gradientStart",
        function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons + 1] = gradStartBtn

    local gradEndLabel = CreateLabel(panel, "Gradient End", rightX, modeY - 112)
    local gradEndBtn   = CreateColorSwatch(panel, rightX, modeY - 130, getDB, "gradientEnd",
        function() UnitFramesLite_UpdateFrame(unit) end)
    panel.swatchButtons[#panel.swatchButtons + 1] = gradEndBtn

    local gradDirLabel = CreateLabel(panel, "Direction", rightX, modeY - 168)
    panel.dirDD = CreateDropdown(panel, rightX, modeY - 186, 120, dirOptions,
        function() return getDB().gradientDir or "HORIZONTAL" end,
        function(v) getDB().gradientDir = v; UnitFramesLite_UpdateFrame(unit) end)

    panel.solidGroup    = {solidLabel, solidBtn}
    panel.gradientGroup = {gradStartLabel, gradStartBtn, gradEndLabel, gradEndBtn,
                           gradDirLabel, panel.dirDD}

    -- Reset button
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 22)
    resetBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 16)
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

    -- Refresh values when the panel is shown
    panel:SetScript("OnShow", function(self) self:refresh() end)
    -- Apply initial show/hide state for solid vs gradient controls
    panel:UpdateColourMode()
end

-- Main options frame --------------------------------------------------------
-- A single draggable frame with Player / Target tabs.
-- Also registered with Settings for game menu access (Main Menu → Options → Addons).

function CreateOptionsPanel()
    local OPTS_W, OPTS_H = 700, 530

    local mainFrame = CreateFrame("Frame", "UnitFramesLiteOptions", UIParent, "BackdropTemplate")
    mainFrame:SetSize(OPTS_W, OPTS_H)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing)
    mainFrame:Hide()
    _G.UnitFramesLiteOptions = mainFrame

    -- Backdrop
    mainFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    mainFrame:SetBackdropColor(0, 0, 0, 1)

    -- Title
    local titleText = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleText:SetPoint("TOP", mainFrame, "TOP", 0, -16)
    titleText:SetText("UnitFramesLite")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 2, 2)

    -- Tab buttons (Player / Target)
    local playerTab = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    playerTab:SetSize(110, 24)
    playerTab:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -36)
    playerTab:SetText("Player")

    local targetTab = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    targetTab:SetSize(110, 24)
    targetTab:SetPoint("LEFT", playerTab, "RIGHT", 6, 0)
    targetTab:SetText("Target")

    -- Divider line below tabs
    local divider = mainFrame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  16, -64)
    divider:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -16, -64)

    -- Content frames (parented to mainFrame, positioned below tab bar)
    local CONTENT_TOP = -68

    local playerContent = CreateFrame("Frame", nil, mainFrame)
    playerContent:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     0, CONTENT_TOP)
    playerContent:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    BuildUnitPanel(playerContent, "player")

    local targetContent = CreateFrame("Frame", nil, mainFrame)
    targetContent:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     0, CONTENT_TOP)
    targetContent:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    targetContent:Hide()
    BuildUnitPanel(targetContent, "target")

    -- Tab switching
    local function SelectTab(showPlayer)
        playerContent:SetShown(showPlayer)
        targetContent:SetShown(not showPlayer)
    end
    playerTab:SetScript("OnClick", function() SelectTab(true) end)
    targetTab:SetScript("OnClick", function() SelectTab(false) end)

    -- Register with Settings for game menu (Main Menu → Options → Addons)
    mainFrame.name = "UnitFramesLite"
    local UFL = _G.UnitFramesLite
    if Settings and Settings.RegisterAddOnCategory then
        local ok, cat = pcall(Settings.RegisterAddOnCategory, mainFrame)
        if ok and cat then
            UFL.optionsCategory = cat
        end
    elseif InterfaceOptions_AddCategory then
        pcall(InterfaceOptions_AddCategory, mainFrame)
    end
end

-- Show/hide the options panel -----------------------------------------------

function UnitFramesLite_ShowOptions()
    local UFL = _G.UnitFramesLite

    -- 1. Try modern Settings API (game menu integration)
    if Settings and Settings.OpenToCategory and UFL and UFL.optionsCategory then
        local ok = pcall(function()
            Settings.OpenToCategory(UFL.optionsCategory:GetID())
        end)
        if ok then return end
    end

    -- 2. Try legacy InterfaceOptions
    if InterfaceOptionsFrame_OpenToCategory and _G.UnitFramesLiteOptions then
        pcall(InterfaceOptionsFrame_OpenToCategory, _G.UnitFramesLiteOptions)
        return
    end

    -- 3. Direct toggle — always works
    local frame = _G.UnitFramesLiteOptions
    if frame then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    end
end
