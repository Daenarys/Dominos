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
    -- post edit mode, grab all of the buttons in order
    for _, button in ipairs { MicroMenu:GetChildren() } do
        -- always reparent the button in retail
        button:SetParent(Addon.ShadowUIParent)

        -- hide the housing button
        if button == HousingMicroButton then
            button:Hide()
        end

        if button:IsShown() then
            MicroButtons[#MicroButtons + 1] = button
        end
    end
end

local MICRO_BUTTON_NAMES = {
    ["CharacterMicroButton"] = CHARACTER_BUTTON,
    ["ProfessionMicroButton"] = PROFESSIONS_BUTTON,
    ["PlayerSpellsMicroButton"] = TALENTS_BUTTON,
    ["AchievementMicroButton"] = ACHIEVEMENT_BUTTON,
    ["QuestLogMicroButton"] = QUESTLOG_BUTTON,
    ["HousingMicroButton"] = HOUSING_MICRO_BUTTON,
    ["GuildMicroButton"] = LOOKINGFORGUILD,
    ["LFDMicroButton"] = DUNGEONS_BUTTON,
    ["CollectionsMicroButton"] = COLLECTIONS,
    ["EJMicroButton"] = ENCOUNTER_JOURNAL,
    ["StoreMicroButton"] = BLIZZARD_STORE,
    ["MainMenuMicroButton"] = MAINMENU_BUTTON
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

MenuBar:Extend('OnCreate', function(self)
    self.activeButtons = {}
end)

function MenuBar:GetDefaults()
    return {
        point = 'BOTTOMRIGHT',
        x = 0,
        y = 48
    }
end

function MenuBar:AcquireButton(index)
    return self.activeButtons[index]
end

function MenuBar:NumButtons()
    return #self.activeButtons
end

function MenuBar:UpdateActiveButtons()
    wipe(self.activeButtons)

    for _, button in ipairs(MicroButtons) do
        if self:IsMenuButtonEnabled(button) then
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

    if OverrideActionBar and OverrideActionBar:IsVisible() then
        for i, button in pairs(MicroButtons) do
            button:ClearAllPoints()
            button:SetParent(OverrideActionBar)
            button:SetScale(0.8)

            if i == 1 then
                local x, y = OverrideActionBar:GetMicroButtonAnchor()
                button:SetPoint('BOTTOMLEFT', x + button:GetWidth(), y + button:GetHeight())
            elseif i == 7 then
                button:SetPoint('TOPLEFT', MicroButtons[1], 'BOTTOMLEFT', 0, 0)
            else
                button:SetPoint('BOTTOMLEFT', MicroButtons[i - 1], 'BOTTOMRIGHT', 0, 0)
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
            button:SetScale(1)
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
    -- the performance bar actually appears under the game menu button if you
    -- move it somewhere else
    local perf = MainMenuMicroButton and MainMenuMicroButton.MainMenuBarPerformanceBar
    if perf then
        perf:ClearAllPoints()
        perf:SetPoint("BOTTOM")
    end

    if FramerateFrame then
        hooksecurefunc(FramerateFrame, "UpdatePosition", function()
            FramerateFrame:ClearAllPoints()
            FramerateFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)
        end)
    end

    hooksecurefunc(MicroMenu, "UpdateHelpTicketButtonAnchor", function()
        if HelpOpenWebTicketButton then
            HelpOpenWebTicketButton:ClearAllPoints()
            HelpOpenWebTicketButton:SetPoint("CENTER", CharacterMicroButton, "CENTER", 0, 20)
        end
    end)

    local layout = Addon:Defer(function()
        local frame = self.frame
        if frame then
            self.frame:Layout()
        end
    end)

    hooksecurefunc("UpdateMicroButtons", layout)

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