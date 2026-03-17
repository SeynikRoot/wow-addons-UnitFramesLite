local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- Simple font + texture lists
local function GetFontList()
    if not LSM then return { "Friz Quadrata TT" } end
    local list = LSM:List("font")
    table.sort(list)
    return list
end

local function GetTextureList()
    if not LSM then return { "Blizzard" } end
    local list = LSM:List("statusbar")
    table.sort(list)
    return list
end

-- Color picker helper
local function OpenColorPicker(dbTable, key, callback)
    local r, g, b, a = unpack(dbTable[key] or {1,1,1,1})

    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = 1 - (a or 1)
    ColorPickerFrame.previousValues = {r, g, b, a}

    ColorPickerFrame.func = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        local na = 1 - OpacitySliderFrame:GetValue()
        dbTable[key] = {nr, ng, nb, na}
        callback()
    end

    ColorPickerFrame.cancelFunc = function(prev)
        dbTable[key] = prev
        callback()
    end

    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Show()
end

-- Basic label
local function CreateLabel(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

-- Edit box for numeric input
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
    eb:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return eb
end

-- Slider
local function CreateSlider(parent, label, minVal, maxVal, step, x, y, onChanged)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Text:SetText(label)
    slider.Low:SetText(tostring(minVal))
    slider.High:SetText(tostring(maxVal))
    slider:SetScript("OnValueChanged", function(self, value)
        onChanged(value)
    end)
    return slider
end

-- Dropdown (simple)
local function CreateDropdown(parent, width, x, y, items, getValue, setValue)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    UIDropDownMenu_SetWidth(dd, width)

    UIDropDownMenu_Initialize(dd, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local current = getValue()
        for _, name in ipairs(items) do
            info.text = name
            info.func = function()
                setValue(name)
                UIDropDownMenu_SetSelectedName(dd, name)
            end
            info.checked = (name == current)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetSelectedName(dd, getValue())
    return dd
end

-- Dropdown with texture swatch
local function CreateTextureDropdown(parent, width, x, y, getValue, setValue)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dd, width)

    local textures = GetTextureList()

    UIDropDownMenu_Initialize(dd, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local current = getValue()
        for _, name in ipairs(textures) do
            info.text = name
            info.func = function()
                setValue(name)
                UIDropDownMenu_SetSelectedName(dd, name)
            end
            info.checked = (name == current)

            -- Swatch
            info.icon = nil
            info.customFrame = nil

            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetSelectedName(dd, getValue())
    return dd
end

-- Alignment dropdown
local alignOptions = { "LEFT", "CENTER", "RIGHT" }

local function CreateAlignDropdown(parent, width, x, y, getValue, setValue)
    return CreateDropdown(parent, width, x, y, alignOptions, getValue, setValue)
end

-- Gradient direction dropdown
local dirOptions = { "HORIZONTAL", "VERTICAL" }

local function CreateDirDropdown(parent, width, x, y, getValue, setValue)
    return CreateDropdown(parent, width, x, y, dirOptions, getValue, setValue)
end

-- Font dropdown
local function CreateFontDropdown(parent, width, x, y, getValue, setValue)
    local fonts = GetFontList()
    return CreateDropdown(parent, width, x, y, fonts, getValue, setValue)
end

-- Panel builder
local function BuildUnitPanel(panel, unit)
    panel.unit = unit

    panel.refresh = function(self)
        local db = UnitFramesLite_GetDB(unit)
        -- Position
        self.xSlider:SetValue(db.x or 0)
        self.xBox:SetText(tostring(db.x or 0))
        self.ySlider:SetValue(db.y or 0)
        self.yBox:SetText(tostring(db.y or 0))

        -- Font
        UIDropDownMenu_SetSelectedName(self.fontDD, db.font or "Friz Quadrata TT")
        self.fontSizeSlider:SetValue(db.fontSize or 14)

        -- Alignment
        UIDropDownMenu_SetSelectedName(self.nameAlignDD, db.nameAlign or "LEFT")
        UIDropDownMenu_SetSelectedName(self.hpAlignDD, db.hpAlign or "RIGHT")

        -- Texture
        UIDropDownMenu_SetSelectedName(self.texDD, db.statusbarTexture or "Blizzard")
    end

    local db = UnitFramesLite_GetDB(unit)

    -- Position section
    CreateLabel(panel, "Position", 16, -16)

    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    local maxX = math.floor(screenW / 2)
    local maxY = math.floor(screenH / 2)

    panel.xSlider = CreateSlider(panel, "X Offset", -maxX, maxX, 1, 16, -40, function(val)
        val = math.floor(val + 0.5)
        db.x = val
        panel.xBox:SetText(tostring(val))
        UnitFramesLite_UpdateFrame(unit)
    end)
    panel.xBox = CreateNumberBox(panel, 60, 260, -40, function(val)
        db.x = val
        panel.xSlider:SetValue(val)
        UnitFramesLite_UpdateFrame(unit)
    end)

    panel.ySlider = CreateSlider(panel, "Y Offset", -maxY, maxY, 1, 16, -80, function(val)
        val = math.floor(val + 0.5)
        db.y = val
        panel.yBox:SetText(tostring(val))
        UnitFramesLite_UpdateFrame(unit)
    end)
    panel.yBox = CreateNumberBox(panel, 60, 260, -80, function(val)
        db.y = val
        panel.ySlider:SetValue(val)
        UnitFramesLite_UpdateFrame(unit)
    end)

    -- Columns
    local leftX  = 16
    local rightX = 320
    local startY = -130

    -- TEXT COLUMN
    CreateLabel(panel, "Text", leftX, startY)

    CreateLabel(panel, "Font", leftX, startY - 24)
    panel.fontDD = CreateFontDropdown(panel, 160, leftX - 16, startY - 40,
        function() return db.font or "Friz Quadrata TT" end,
        function(name)
            db.font = name
            UnitFramesLite_UpdateFrame(unit)
        end
    )

    CreateLabel(panel, "Font Size", leftX, startY - 80)
    panel.fontSizeSlider = CreateSlider(panel, "", 8, 24, 1, leftX, startY - 100, function(val)
        db.fontSize = math.floor(val + 0.5)
        UnitFramesLite_UpdateFrame(unit)
    end)

    CreateLabel(panel, "Name Alignment", leftX, startY - 140)
    panel.nameAlignDD = CreateAlignDropdown(panel, 120, leftX - 16, startY - 156,
        function() return db.nameAlign or "LEFT" end,
        function(val)
            db.nameAlign = val
            UnitFramesLite_UpdateFrame(unit)
        end
    )

    CreateLabel(panel, "HP Alignment", leftX, startY - 196)
    panel.hpAlignDD = CreateAlignDropdown(panel, 120, leftX - 16, startY - 212,
        function() return db.hpAlign or "RIGHT" end,
        function(val)
            db.hpAlign = val
            UnitFramesLite_UpdateFrame(unit)
        end
    )

    -- Name colour
    CreateLabel(panel, "Name Colour", leftX, startY - 252)
    local nameColorBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    nameColorBtn:SetSize(80, 20)
    nameColorBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", leftX, startY - 270)
    nameColorBtn:SetText("Pick...")
    nameColorBtn:SetScript("OnClick", function()
        OpenColorPicker(db, "nameColor", function()
            UnitFramesLite_UpdateFrame(unit)
        end)
    end)

    -- HP colour
    CreateLabel(panel, "HP Colour", leftX, startY - 300)
    local hpColorBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    hpColorBtn:SetSize(80, 20)
    hpColorBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", leftX, startY - 318)
    hpColorBtn:SetText("Pick...")
    hpColorBtn:SetScript("OnClick", function()
        OpenColorPicker(db, "hpColor", function()
            UnitFramesLite_UpdateFrame(unit)
        end)
    end)

    -- BAR COLUMN
    CreateLabel(panel, "Bar", rightX, startY)

    -- Background colour
    CreateLabel(panel, "Background Colour", rightX, startY - 24)
    local bgColorBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    bgColorBtn:SetSize(80, 20)
    bgColorBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", rightX, startY - 42)
    bgColorBtn:SetText("Pick...")
    bgColorBtn:SetScript("OnClick", function()
        OpenColorPicker(db, "barBG", function()
            UnitFramesLite_UpdateFrame(unit)
        end)
    end)

    -- Texture dropdown
    CreateLabel(panel, "Statusbar Texture", rightX, startY - 80)
    panel.texDD = CreateTextureDropdown(panel, 160, rightX - 16, startY - 96,
        function() return db.statusbarTexture or "Blizzard" end,
        function(name)
            db.statusbarTexture = name
            UnitFramesLite_UpdateFrame(unit)
        end
    )

    -- Gradient start
    CreateLabel(panel, "Gradient Start", rightX, startY - 136)
    local gradStartBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    gradStartBtn:SetSize(80, 20)
    gradStartBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", rightX, startY - 154)
    gradStartBtn:SetText("Pick...")
    gradStartBtn:SetScript("OnClick", function()
        OpenColorPicker(db, "gradientStart", function()
            UnitFramesLite_UpdateFrame(unit)
        end)
    end)

    -- Gradient end
    CreateLabel(panel, "Gradient End", rightX, startY - 192)
    local gradEndBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    gradEndBtn:SetSize(80, 20)
    gradEndBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", rightX, startY - 210)
    gradEndBtn:SetText("Pick...")
    gradEndBtn:SetScript("OnClick", function()
        OpenColorPicker(db, "gradientEnd", function()
            UnitFramesLite_UpdateFrame(unit)
        end)
    end)

    -- Gradient direction
    CreateLabel(panel, "Gradient Direction", rightX, startY - 248)
    panel.dirDD = CreateDirDropdown(panel, 140, rightX - 16, startY - 264,
        function() return db.gradientDir or "HORIZONTAL" end,
        function(val)
            db.gradientDir = val
            UnitFramesLite_UpdateFrame(unit)
        end
    )

    -- Reset button
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 22)
    resetBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 16)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        StaticPopupDialogs["UFL_RESET_"..unit] = {
            text = "Reset "..unit.." settings to defaults?",
            button1 = YES,
            button2 = NO,
            OnAccept = function()
                UnitFramesLiteDB[unit] = nil
                UnitFramesLite_UpdateFrame(unit)
                panel:refresh()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("UFL_RESET_"..unit)
    end)

    panel:refresh()
end

-- Parent + child panels
local parent = CreateFrame("Frame", "UnitFramesLiteOptions", UIParent)
UnitFramesLiteOptions = parent
parent.name = "UnitFramesLite"
parent:Hide()
local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("UnitFramesLite")
local subtitle = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText("Lightweight modern unit frames with in-game configuration.")
InterfaceOptions_AddCategory(parent)
print("UnitFramesLite: options category registered")

local playerPanel = CreateFrame("Frame", "UnitFramesLite_PlayerOptions", UIParent)
playerPanel.name = "Player"
playerPanel.parent = "UnitFramesLite"
playerPanel:Hide()
BuildUnitPanel(playerPanel, "player")
InterfaceOptions_AddCategory(playerPanel)

local targetPanel = CreateFrame("Frame", "UnitFramesLite_TargetOptions", UIParent)
targetPanel.name = "Target"
targetPanel.parent = "UnitFramesLite"
targetPanel:Hide()
BuildUnitPanel(targetPanel, "target")
InterfaceOptions_AddCategory(targetPanel)