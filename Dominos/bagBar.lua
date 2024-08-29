--------------------------------------------------------------------------------
--	Bag Bar - A bar for holding bag buttons
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

-- register buttons for use later
local BagButtons = {}

local BagBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function BagBar:New()
    return BagBar.proto.New(self, 'bags')
end

function BagBar:GetDisplayName()
    return L.BagBarDisplayName
end

function BagBar:GetDefaults()
    return {
        displayLayer = 'LOW',
        point = 'BOTTOMRIGHT',
        oneBag = false,
        spacing = 2
    }
end

function BagBar:SetShowBags(enable)
    self.sets.oneBag = not enable
    self:ReloadButtons()
end

function BagBar:ShowBags()
    return not self.sets.oneBag
end

-- Frame Overrides
function BagBar:AcquireButton(index)
    if self:ShowBags() then
        if index == 1 then
            return BagButtons[#BagButtons]
        end

        return nil
    end
    
    return BagButtons[index]
end

function BagBar:NumButtons()
    if self:ShowBags() then
        return 1
    end

    return #BagButtons
end

function BagBar:OnCreateMenu(menu)
    local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local layoutPanel = menu:NewPanel(L.Layout)

    layoutPanel:NewCheckButton {
        name = L.BagBarShowBags,
        get = function()
            return layoutPanel.owner:ShowBags()
        end,
        set = function(_, enable)
            layoutPanel.owner:SetShowBags(enable)
            layoutPanel.colsSlider:UpdateRange()
            layoutPanel.colsSlider:UpdateValue()
        end
    }

    layoutPanel:AddLayoutOptions()

    menu:AddFadingPanel()
    menu:AddAdvancedPanel()
end

--------------------------------------------------------------------------------
--	module
--------------------------------------------------------------------------------

local BagBarModule = Addon:NewModule('BagBar')

function BagBarModule:OnInitialize()
    for slot = (NUM_BAG_SLOTS - 1), 0, -1 do
        self:RegisterButton(('CharacterBag%dSlot'):format(slot))
    end

    self:RegisterButton('MainMenuBarBackpackButton')

    if not self.frame then
        local noopFunc = function() end

        CharacterReagentBag0Slot.SetBarExpanded = noopFunc
        CharacterBag3Slot.SetBarExpanded = noopFunc
        CharacterBag2Slot.SetBarExpanded = noopFunc
        CharacterBag1Slot.SetBarExpanded = noopFunc
        CharacterBag0Slot.SetBarExpanded = noopFunc
        BagsBar.Layout = noopFunc
    end

    if BagsBar and BagsBar.Layout then
        hooksecurefunc(BagsBar, "Layout", function()
            if InCombatLockdown() then return end

            if self.frame then
                self.frame:Layout()
            end
        end)
        EventRegistry:UnregisterCallback("MainMenuBarManager.OnExpandChanged", BagsBar)
    end

    if BagBarExpandToggle then
        BagBarExpandToggle:Hide()
    end

    if CharacterReagentBag0Slot then
        CharacterReagentBag0Slot:Hide()
    end
end

function BagBarModule:Load()
    self.frame = BagBar:New()
end

function BagBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

function BagBarModule:RegisterButton(name)
    local button = _G[name]
    if not button then
        return
    end

    button:Hide()

    button:SetSize(36, 36)

    if button.CircleMask then
        button.CircleMask:Hide()
    end

    if button.IconBorder then
        button.IconBorder:SetSize(37, 37)
    end

    if button.IconOverlay ~= nil then
        button.IconOverlay:SetSize(37, 37)
    end

    local function UpdateTextures(self)
        self:GetNormalTexture():SetSize(64, 64)
        self:GetNormalTexture():SetTexture("Interface\\Buttons\\UI-Quickslot2")
        self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)
        self:GetNormalTexture():ClearAllPoints()
        self:GetNormalTexture():SetPoint("TOPLEFT", -15, 15)
        self:GetNormalTexture():SetPoint("BOTTOMRIGHT", 15, -15)
        self:GetPushedTexture():SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        self:GetHighlightTexture():SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        self:GetHighlightTexture():SetAlpha(1)
        self.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        self.SlotHighlightTexture:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        self.SlotHighlightTexture:SetBlendMode("ADD")
    end

    for i = 0, 3 do
        local bagSlot = _G["CharacterBag"..i.."Slot"]
        hooksecurefunc(bagSlot, "SetItemButtonQuality", ItemButtonMixin.SetItemButtonQuality)
        hooksecurefunc(bagSlot, "UpdateTextures", UpdateTextures)
    end

    UpdateTextures(CharacterBag0Slot)
    CharacterBag0Slot:ClearAllPoints()
    CharacterBag0Slot:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -4, -4)
    UpdateTextures(CharacterBag1Slot)
    CharacterBag1Slot:ClearAllPoints()
    CharacterBag1Slot:SetPoint("RIGHT", CharacterBag0Slot, "LEFT", -2, 0)
    UpdateTextures(CharacterBag2Slot)
    CharacterBag2Slot:ClearAllPoints()
    CharacterBag2Slot:SetPoint("RIGHT", CharacterBag1Slot, "LEFT", -2, 0)
    UpdateTextures(CharacterBag3Slot)
    CharacterBag3Slot:ClearAllPoints()
    CharacterBag3Slot:SetPoint("RIGHT", CharacterBag2Slot, "LEFT", -2, 0)
    UpdateTextures(MainMenuBarBackpackButton)
    MainMenuBarBackpackButtonIconTexture:SetAtlas("hud-backpack", false)
    MainMenuBarBackpackButtonCount:ClearAllPoints()
    MainMenuBarBackpackButtonCount:SetPoint("CENTER", 0, -10)

    tinsert(BagButtons, button)
end

local function Disable_BagButtons()
    for i, bagButton in MainMenuBarBagManager:EnumerateBagButtons() do
        bagButton:Disable();
        SetDesaturation(bagButton.icon, true);
        SetDesaturation(bagButton.NormalTexture, true);
    end
end

local function Enable_BagButtons()
    for i, bagButton in MainMenuBarBagManager:EnumerateBagButtons() do
        bagButton:Enable();
        SetDesaturation(bagButton.icon, false);
        SetDesaturation(bagButton.NormalTexture, false);
    end
end

GameMenuFrame:HookScript("OnShow", function()
    Disable_BagButtons()
end)

GameMenuFrame:HookScript("OnHide", function()
    Enable_BagButtons()
end)