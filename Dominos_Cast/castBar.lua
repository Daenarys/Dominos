--------------------------------------------------------------------------------
-- Cast Bar
-- A dominos based casting bar
--------------------------------------------------------------------------------

local DCB = Dominos:NewModule('CastingBar')
local CastBar, CastingBar

function DCB:Load()
	self.frame = CastBar:New()
end

function DCB:Unload()
	self.frame:Free()
end

--------------------------------------------------------------------------------
-- Frame Object
--------------------------------------------------------------------------------

CastBar = Dominos:CreateClass('Frame', Dominos.Frame)

function CastBar:New()
	local f = self.proto.New(self, 'cast')
	f:SetFrameStrata('HIGH')

	if not f.cast then
		f.cast = CastingBar:New(f)
	end

	f:Layout()

	return f
end

function CastBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = 30
	}
end

function CastBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)

	panel:NewOpacitySlider()
	panel:NewFadeSlider()
	panel:NewScaleSlider()
	panel:NewPaddingSlider()

	self.menu = menu
end

function CastBar:Layout()
	self:SetWidth(max(self.cast:GetWidth() + 4 + self:GetPadding()*2, 8))
	self:SetHeight(max(24 + self:GetPadding()*2, 8))
end

--------------------------------------------------------------------------------
-- CastingBar Object
--------------------------------------------------------------------------------

CastingBar = Dominos:CreateClass('StatusBar')

function CastingBar:New(parent)
	local f = self:Bind(CreateFrame('StatusBar', 'DominosCastingBar', parent, 'DominosCastingBarTemplate'))
	f:SetPoint('CENTER', 0, 5)

	return f
end

DominosCastingBarMixin = {}

function DominosCastingBarMixin:OnLoad()
	local showTradeSkills = true
	local showShieldNo = false
	CastingBarMixin.OnLoad(self, "player", showTradeSkills, showShieldNo)
	self.Icon:Hide()
	self.Text:ClearAllPoints()
	self.Text:SetPoint("TOP", 0, -9)
end

--hide the old casting bar
PlayerCastingBarFrame:UnregisterAllEvents()
PlayerCastingBarFrame:Hide()