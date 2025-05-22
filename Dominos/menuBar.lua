--------------------------------------------------------------------------------
-- Menu Bar
-- A movable bar for the micro menu buttons
-- Things get a bit trickier with this one, as the buttons shift around when
-- entering a pet battle, or using the override UI
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local MicroButtons = {}
local PetMicroButtonFrame = PetBattleFrame and PetBattleFrame.BottomFrame.MicroButtonFrame

if MicroMenu then
    local function registerButtons(t, ...)
        for i = 1, select('#', ...) do
            local button = select(i, ...)

            -- always reparent the button
            button:SetParent(Addon.ShadowUIParent)

            -- ...but only display it on our bar if it was already enabled
            if button:IsShown() then
                t[#t + 1] = button
            end
        end
    end

    registerButtons(MicroButtons, MicroMenu:GetChildren())
end

local MICRO_BUTTON_NAMES = {
    ['CharacterMicroButton'] = CHARACTER_BUTTON,
    ['ProfessionMicroButton'] = PROFESSIONS_BUTTON,
    ['PlayerSpellsMicroButton'] = TALENTS_BUTTON,
    ['AchievementMicroButton'] = ACHIEVEMENT_BUTTON,
    ['QuestLogMicroButton'] = QUESTLOG_BUTTON,
    ['GuildMicroButton'] = LOOKINGFORGUILD,
    ['LFDMicroButton'] = DUNGEONS_BUTTON,
    ['CollectionsMicroButton'] = COLLECTIONS,
    ['EJMicroButton'] = ENCOUNTER_JOURNAL,
    ['StoreMicroButton'] = BLIZZARD_STORE,
    ['MainMenuMicroButton'] = MAINMENU_BUTTON
}

--------------------------------------------------------------------------------
-- bar
--------------------------------------------------------------------------------

local MenuBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function MenuBar:New()
    return MenuBar.proto.New(self, 'menu')
end

function MenuBar:GetDisplayName()
    return L.MenuBarDisplayName
end

function MenuBar:Skin(button)
    if button.skinned then return end

    button:SetSize(28, 36)

    hooksecurefunc("HelpOpenWebTicketButton_OnUpdate", function(self)
        self:SetParent(MainMenuMicroButton)
        self:ClearAllPoints()
        self:SetPoint("CENTER", MainMenuMicroButton, "TOPRIGHT", -3, -26)
    end)

    button.skinned = true
end

MenuBar:Extend('OnCreate', function(self)
    self.activeButtons = {}
end)

function MenuBar:GetDefaults()
    return {
        displayLayer = 'LOW',
        point = 'BOTTOMRIGHT',
        x = -244,
        y = 0
    }
end

function MenuBar:AcquireButton(index)
    return self.activeButtons[index]
end

function MenuBar:NumButtons()
    return #self.activeButtons
end

function MenuBar:GetButtonInsets()
    local l, r, t, b = MenuBar.proto.GetButtonInsets(self)

    return l, r + 1, t + 3, b
end

function MenuBar:UpdateActiveButtons()
    wipe(self.activeButtons)

    for _, button in ipairs(MicroButtons) do
        if self:IsMenuButtonEnabled(button) then
            self:Skin(button)
            self.activeButtons[#self.activeButtons + 1] = button
        end
    end
end

function MenuBar:ReloadButtons()
    self:UpdateActiveButtons()

    MenuBar.proto.ReloadButtons(self)
end


function MenuBar:SetEnableMenuButton(button, enabled)
    enabled = enabled and true

    if enabled then
        local disabled = self.sets.disabled

        if disabled then
            disabled[button:GetName()] = false
        end
    else
        local disabled = self.sets.disabled

        if not disabled then
            disabled = {}
            self.sets.disabled = disabled
        end

        disabled[button:GetName()] = true
    end

    self:ReloadButtons()
end

function MenuBar:IsMenuButtonEnabled(button)
    local disabled = self.sets.disabled

    return not (disabled and disabled[button:GetName()])
end

function MenuBar:Layout()
    for _, button in pairs(MicroButtons) do
        button:Hide()
    end

    self:UpdateActiveButtons()

    if OverrideActionBar and OverrideActionBar:IsVisible() then
        local l, r, t, b = self:GetButtonInsets()

        for i, button in pairs(MicroButtons) do
            button:ClearAllPoints()
            button:SetParent(OverrideActionBar)
            if i == 1 then
                button:SetPoint('BOTTOMLEFT', 543, 40)
            elseif i == 7 then
                button:SetPoint('TOPLEFT', MicroButtons[1], 'BOTTOMLEFT', 0, (t - b) + 3)
            else
                button:SetPoint('BOTTOMLEFT', MicroButtons[i - 1], 'BOTTOMRIGHT', (l - r) - 1, 0)
            end

            button:Show()
        end
    elseif PetMicroButtonFrame and PetMicroButtonFrame:IsVisible() then
        for i, button in ipairs(MicroButtons) do
            button:ClearAllPoints()
            button:SetParent(PetMicroButtonFrame)
            button:SetScale(1)

            if i == 1 then
                button:SetPoint('TOPLEFT', -17, 9)
            elseif i == 7 then
                button:SetPoint('TOPLEFT', MicroButtons[1], 'BOTTOMLEFT', 0, 6)
            else
                button:SetPoint('TOPLEFT', MicroButtons[i - 1], 'TOPRIGHT', -5, 0)
            end

            button:Show()
        end
    else
        for _, button in pairs(self.buttons) do
            button:Show()
        end

        MenuBar.proto.Layout(self)
    end
end

-- exports
Addon.MenuBar = MenuBar

--------------------------------------------------------------------------------
-- context menu
--------------------------------------------------------------------------------

local function Menu_AddDisableMenuButtonsPanel(menu)
    local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local panel = menu:NewPanel(L.Buttons)
    local width, height = 0, 0
    local prev = nil

    for _, button in ipairs(MicroButtons) do
        local toggle = panel:NewCheckButton({
            name = MICRO_BUTTON_NAMES[button:GetName()] or button:GetName(),

            get = function()
                return panel.owner:IsMenuButtonEnabled(button)
            end,

            set = function(_, enable)
                panel.owner:SetEnableMenuButton(button, enable)
            end
        })

        if prev then
            toggle:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -2)
        else
            toggle:SetPoint('TOPLEFT', 0, -2)
        end

        local bWidth, bHeight = toggle:GetEffectiveSize()

        width = math.max(width, bWidth)
        height = height + (bHeight + 2)

        prev = toggle
    end

    panel.width = width
    panel.height = height

    return panel
end

function MenuBar:OnCreateMenu(menu)
    menu:AddLayoutPanel()
    Menu_AddDisableMenuButtonsPanel(menu)
    menu:AddFadingPanel()
    menu:AddAdvancedPanel()
end

--------------------------------------------------------------------------------
-- module
--------------------------------------------------------------------------------

local MenuBarModule = Addon:NewModule('MenuBar')

function MenuBarModule:OnInitialize()
    local layout = Addon:Defer(function()
        local frame = self.frame
        if frame then
            self.frame:Layout()
        end
    end)

    if OverrideActionBar then
        local f = CreateFrame("Frame", nil, OverrideActionBar)
        f:SetScript("OnShow", layout)
        f:SetScript("OnHide", layout)
    end

    if PetMicroButtonFrame then
        local f = CreateFrame("Frame", nil, PetMicroButtonFrame)
        f:SetScript("OnShow", layout)
        f:SetScript("OnHide", layout)
    end
end

function MenuBarModule:Load()
    self.frame = MenuBar:New()
end

function MenuBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end
