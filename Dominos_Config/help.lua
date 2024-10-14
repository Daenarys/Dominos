--------------------------------------------------------------------------------
-- Overlay UI Help Dialog
-- Shows information about how to configure bars in configuration mode
--------------------------------------------------------------------------------

local _, Addon = ...
local L = _G.LibStub("AceLocale-3.0"):GetLocale(Addon:GetParent():GetName())

local GRID_SIZE_MINIMUM = 1
local GRID_SIZE_MAXIMUM = 128
local GRID_SIZE_STEP = 1

local HelpDialog = _G.CreateFrame('Frame', nil, nil)

HelpDialog:Hide()

function HelpDialog:OnLoad(owner)
    self:SetParent(owner)

    self:EnableMouse(true)
    self:RegisterForDrag('LeftButton')
    self:SetClampedToScreen(true)
    self:SetFrameStrata('FULLSCREEN_DIALOG')
    self:SetMovable(true)
    self:SetSize(360, 120)
    self:SetPoint('TOP', 0, -24)
    self:SetScript('OnDragStart', self.OnDragStart)
    self:SetScript('OnDragStop', self.OnDragStop)

    local border = CreateFrame('Frame', nil, self, 'DialogBorderTemplate')
    border.TopEdge:SetSize(32, 32)
    border.TopEdge:SetTexture("Interface\\FrameGeneral\\UIFrameDiamondMetal", true)
    border.TopEdge:SetTexCoord(0, 0.5, 0.13671875, 0.26171875)

    border.TopLeftCorner:SetSize(32, 32)
    border.TopLeftCorner:SetTexture("Interface\\FrameGeneral\\UIFrameDiamondMetal")
    border.TopLeftCorner:SetTexCoord(0.015625, 0.515625, 0.53515625, 0.66015625)

    border.TopRightCorner:SetSize(32, 32)
    border.TopRightCorner:SetTexture("Interface\\FrameGeneral\\UIFrameDiamondMetal")
    border.TopRightCorner:SetTexCoord(0.015625, 0.515625, 0.66796875, 0.79296875)

    border.BottomEdge:SetSize(32, 32)
    border.BottomEdge:SetTexture("Interface\\FrameGeneral\\UIFrameDiamondMetal", true)
    border.BottomEdge:SetTexCoord(0, 0.5, 0.00390625, 0.12890625)

    border.BottomLeftCorner:SetSize(32, 32)
    border.BottomLeftCorner:SetTexture("Interface\\FrameGeneral\\UIFrameDiamondMetal")
    border.BottomLeftCorner:SetTexCoord(0.015625, 0.515625, 0.26953125, 0.39453125)

    border.BottomRightCorner:SetSize(32, 32)
    border.BottomRightCorner:SetTexture("Interface\\FrameGeneral\\UIFrameDiamondMetal")
    border.BottomRightCorner:SetTexCoord(0.015625, 0.515625, 0.40234375, 0.52734375)

    border.LeftEdge:SetSize(32, 32)
    border.LeftEdge:SetTexture("Interface\\FrameGeneral\\UIFrameDiamondMetalVertical", false, true)
    border.LeftEdge:SetTexCoord(0.0078125, 0.2578125, 0, 1)

    border.RightEdge:SetSize(32, 32)
    border.RightEdge:SetTexture("Interface\\FrameGeneral\\UIFrameDiamondMetalVertical", false, true)
    border.RightEdge:SetTexCoord(0.2734375, 0.5234375, 0, 1)

    local header = self:CreateTexture(nil, 'ARTWORK')
    header:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Header')
    header:SetWidth(326)
    header:SetHeight(64)
    header:SetPoint('TOP', 0, 12)

    local title = self:CreateFontString(nil, 'ARTWORK')
    title:SetFontObject('GameFontNormal')
    title:SetPoint('TOP', header, 'TOP', 0, -14)
    title:SetText(L.ConfigMode)

    local desc = self:CreateFontString(nil, 'ARTWORK')
    desc:SetFontObject('GameFontHighlight')
    desc:SetJustifyV('TOP')
    desc:SetJustifyH('LEFT')
    desc:SetPoint('TOPLEFT', 18, -32)
    desc:SetPoint('BOTTOMRIGHT', -18, 48)
    desc:SetText(L.ConfigModeHelp)

    local exitButton = _G.CreateFrame('Button', nil, self, 'UIPanelButtonNoTooltipResizeToFitTemplate')

    exitButton.Text:SetText(_G.EXIT)
    exitButton:SetScript('OnClick', function() self:OnExitButtonClicked() end)
    exitButton:SetPoint('BOTTOMRIGHT', -14, 14)

    self.exitButton = exitButton

    local showGridButton = _G.CreateFrame('CheckButton', nil, self, "UICheckButtonTemplate")

    showGridButton.text:SetText(L.ShowAlignmentGrid)
    showGridButton:SetChecked(Addon:GetParent():GetAlignmentGridEnabled())
    showGridButton:SetScript('OnClick', function(button) self:OnShowGridButtonClicked(button) end)
    showGridButton:SetPoint('BOTTOMLEFT', 14, 10)


	local slider = Addon.Slider:New({
		name = L.GridDensity,

        min = GRID_SIZE_MINIMUM,
        max = GRID_SIZE_MAXIMUM,
        step = GRID_SIZE_STEP,

		get = function()
			return Addon:GetParent():GetAlignmentGridSize()
		end,

		set = function(_, value)
			Addon:GetParent():SetAlignmentGridSize(value)
		end
    })

    slider:SetParent(self)
    slider:SetScale(0.8)
    slider:SetPoint('LEFT', showGridButton, 'RIGHT', 75, -6)
    slider:SetPoint('RIGHT', exitButton, 'LEFT', -2, -6)

    self.showGridButton = showGridButton

    Addon:GetParent().RegisterCallback(self, "ALIGNMENT_GRID_ENABLED")

    self:Show()
end

function HelpDialog:ALIGNMENT_GRID_ENABLED(_, enable)
    self.showGridButton:SetChecked(enable)
end

function HelpDialog:OnDragStart()
    self:StartMoving()
end

function HelpDialog:OnDragStop()
    self:StopMovingOrSizing()
end

function HelpDialog:OnExitButtonClicked()
    Addon:GetParent():SetLock(true)
end

function HelpDialog:OnShowGridButtonClicked(button)
    Addon:GetParent():SetAlignmentGridEnabled(button:GetChecked())
end

--------------------------------------------------------------------------------
-- exports
--------------------------------------------------------------------------------

Addon.HelpDialog = HelpDialog
