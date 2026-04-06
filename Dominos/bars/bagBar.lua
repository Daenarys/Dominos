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
    self:UpdateBagSlots()
    self:ReloadButtons()
end

function BagBar:ShowBags()
    return not self.sets.oneBag
end

-- Frame Overrides
BagBar:Extend(
    'OnCreate',
    function(self)
        self.bagSlots = {}
    end
)

BagBar:Extend(
    'OnLoadSettings',
    function(self)
        self:UpdateBagSlots()
    end
)

do
    local function maybeAddBagSlot(bagSlots, buttonName)
        local button = _G[buttonName]
        if button then
            bagSlots[#bagSlots+1] = button
        end
    end

    function BagBar:UpdateBagSlots()
        local slots = self.bagSlots

        table.wipe(slots)

        if self:ShowBags() then
            maybeAddBagSlot(slots, 'CharacterReagentBag0Slot')

            for slot = (NUM_BAG_SLOTS - 1), 0, -1 do
                maybeAddBagSlot(slots, ('CharacterBag%dSlot'):format(slot))
            end
        end

        maybeAddBagSlot(slots, 'MainMenuBarBackpackButton')
    end
end

function BagBar:AcquireButton(index)
    return self.bagSlots[index]
end

function BagBar:OnAttachButton(button)
    button:Show()
end

function BagBar:NumButtons()
    return #self.bagSlots
end

function BagBar:GetButtonSize()
    local w, h = MainMenuBarBackpackButton:GetSize()
    local l, r, t, b = self:GetButtonInsets()

    return w - (l + r), h - (t + b)
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

local BagBarModule = Addon:NewModule('BagBar', 'AceEvent-3.0')

function BagBarModule:Load()
    if self.frame == nil then
        self.frame = BagBar:New()
    end
end

function BagBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

function BagBarModule:OnFirstLoad()
    if BagsBar then
        BagsBar:SetParent(Addon.ShadowUIParent)
    end

    -- use our own handling for the blizzard bag bar
    if MainMenuBarManager then
        EventRegistry:UnregisterCallback("MainMenuBarManager.OnExpandChanged", MainMenuBarManager)
        EventRegistry:UnegisterFrameEventAndCallback("VARIABLES_LOADED", MainMenuBarManager)
    elseif BagsBar then
        EventRegistry:UnregisterCallback("MainMenuBarManager.OnExpandChanged", BagsBar)
        hooksecurefunc(BagsBar, "Layout", function() self:LayoutBagBar() end)
    end

    if BagBarExpandToggle then
        BagBarExpandToggle:Hide()
    end

    self:RegisterButton('CharacterReagentBag0Slot')

    for slot = (NUM_BAG_SLOTS - 1), 0, -1 do
        self:RegisterButton(('CharacterBag%dSlot'):format(slot))
    end

    self:RegisterButton('MainMenuBarBackpackButton')

    self.RegisterButton = nil

    self:RegisterEvent("PLAYER_REGEN_ENABLED", "LayoutBagBar")

    for _, button in pairs(BagButtons) do
        Addon:GetModule('ButtonThemer'):Register(
            button,
            'Bag Bar',
            {
                Icon = button.icon
            }
        )
    end
end

function BagBarModule:LayoutBagBar()
    if InCombatLockdown() then
        self.needsUpdate = true
        return
    end

    if self.frame then
        self.frame:Layout()
    end

    self.needsUpdate = nil
end

function BagBarModule:RegisterButton(name)
    local button = _G[name]
    if not button then
        return
    end

    button:SetSize(MainMenuBarBackpackButton:GetSize())
    button:Hide()

    if button.SetBarExpanded then
        button.SetBarExpanded = function() end
    end

    BagButtons[#BagButtons + 1] = button
end
