--------------------------------------------------------------------------------
-- Pet Bar
-- A movable action bar for pets
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

--------------------------------------------------------------------------------
-- Button Setup
--------------------------------------------------------------------------------

local function getPetButton(id)
	return _G[('PetActionButton%d'):format(id)]
end

local function skinPetButton(self)
	self.AutoCastOverlay:ClearAllPoints()
	self.AutoCastOverlay:SetPoint("CENTER")
	self.AutoCastOverlay.Corners:SetSize(80, 80)
	self.AutoCastOverlay.Corners:SetTexture([[Interface\Buttons\UI-AutoCastableOverlay]])
	self.AutoCastOverlay.Corners:ClearAllPoints()
	self.AutoCastOverlay.Corners:SetPoint("CENTER")
	self.AutoCastOverlay.Mask:ClearAllPoints()
	self.AutoCastOverlay.Mask:SetAllPoints()
	self.cooldown:SetSwipeColor(0, 0, 0, 0.8)
	self.lossOfControlCooldown:SetSwipeColor(0.17, 0, 0, 0.8)
end

for id = 1, NUM_PET_ACTION_SLOTS do
	local button = getPetButton(id)

	-- set the buttontype
	button:SetAttribute("commandName", "BONUSACTIONBUTTON" .. id)

	-- apply hooks for quick binding
	Addon.BindableButton:AddQuickBindingSupport(button)

	-- apply button skin
	skinPetButton(button)
end

--------------------------------------------------------------------------------
-- The Pet Bar
--------------------------------------------------------------------------------

local PetBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function PetBar:New()
	return PetBar.proto.New(self, 'pet')
end

function PetBar:GetDisplayName()
	return L.PetBarDisplayName
end

function PetBar:IsOverrideBar()
	return Addon.db.profile.possessBar == self.id
end

function PetBar:UpdateOverrideBar()
	self:UpdateDisplayConditions()
end

function PetBar:GetDisplayConditions()
	return '[@pet,exists,novehicleui,nooverridebar,nopossessbar]show;hide'
end

function PetBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = -32,
		spacing = 6
	}
end

function PetBar:NumButtons()
	return NUM_PET_ACTION_SLOTS
end

function PetBar:AcquireButton(index)
	return getPetButton(index)
end

function PetBar:OnAttachButton(button)
	button:UpdateHotkeys()
	Addon:GetModule('Tooltips'):Register(button)
end

function PetBar:OnDetachButton(button)
	Addon:GetModule('Tooltips'):Unregister(button)
end

-- keybound events
function PetBar:KEYBOUND_ENABLED()
	self:ForButtons("Show")
end

function PetBar:KEYBOUND_DISABLED()
	local petBarShown = PetHasActionBar()

	for _, button in pairs(self.buttons) do
		if petBarShown and GetPetActionInfo(button:GetID()) then
			button:Show()
		else
			button:Hide()
		end
	end
end

--------------------------------------------------------------------------------
-- the module
--------------------------------------------------------------------------------

local PetBarModule = Addon:NewModule('PetBar', 'AceEvent-3.0')

function PetBarModule:Load()
	self.bar = PetBar:New()

	self:RegisterEvent('UPDATE_BINDINGS')
end

function PetBarModule:Unload()
	self:UnregisterAllEvents()

	if self.bar then
		self.bar:Free()
		self.bar = nil
	end
end

function PetBarModule:UPDATE_BINDINGS()
	self.bar:ForButtons('UpdateHotkeys')
end