--------------------------------------------------------------------------------
-- Menu Bar
-- A movable bar for the micro menu buttons
-- Things get a bit trickier with this one, as the buttons shift around when
-- entering a pet battle, or using the override UI
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local MICRO_BUTTONS = {
    "CharacterMicroButton",
    "ProfessionMicroButton",
    "PlayerSpellsMicroButton",
    "AchievementMicroButton",
    "QuestLogMicroButton",
    "GuildMicroButton",
    "LFDMicroButton",
    "CollectionsMicroButton",
    "EJMicroButton",
    "StoreMicroButton",
    "MainMenuMicroButton"
}

local MICRO_BUTTON_NAMES = {
    ['CharacterMicroButton'] = CHARACTER_BUTTON,
    ['ProfessionMicroButton'] = PROFESSIONS_BUTTON,
    ['PlayerSpellsMicroButton'] = TALENTS_BUTTON,
    ['AchievementMicroButton'] = ACHIEVEMENT_BUTTON,
    ['QuestLogMicroButton'] = QUESTLOG_BUTTON,
    ['GuildMicroButton'] = LOOKINGFORGUILD,
    ['LFDMicroButton'] = DUNGEONS_BUTTON,
    ['EJMicroButton'] = ENCOUNTER_JOURNAL,
    ['MainMenuMicroButton'] = MAINMENU_BUTTON,
    ['StoreMicroButton'] = BLIZZARD_STORE,
    ['CollectionsMicroButton'] = COLLECTIONS
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

    local buttons = {
        {button = CharacterMicroButton, name = "Character"},
        {button = ProfessionMicroButton, name = "Spellbook"},
        {button = PlayerSpellsMicroButton, name = "Talents"},
        {button = AchievementMicroButton, name = "Achievement"},
        {button = QuestLogMicroButton, name = "Quest"},
        {button = GuildMicroButton, name = "Socials"},
        {button = LFDMicroButton, name = "LFG"},
        {button = CollectionsMicroButton, name = "Mounts"},
        {button = EJMicroButton, name = "EJ"},
        {button = StoreMicroButton, name = "BStore"},  
        {button = MainMenuMicroButton, name = "MainMenu"}
    }

    local function replaceAtlases(self, name)
        local prefix = "hud-microbutton-";
        self:SetNormalAtlas(prefix..name.."-Up", true)
        self:SetPushedAtlas(prefix..name.."-Down", true)
        if self:GetDisabledTexture() then
            self:SetDisabledAtlas(prefix..name.."-Disabled", true)
        end
    end

    local function replaceAllAtlases()
        for _, data in pairs(buttons) do
            replaceAtlases(data.button, data.name)
        end
    end
    replaceAllAtlases()

    button:HookScript("OnUpdate", function(self)
        local normalTexture = self:GetNormalTexture()
        if (normalTexture) then
            normalTexture:SetAlpha(1)
        end
        local highlightTexture = self:GetHighlightTexture()
        if (highlightTexture) then
            highlightTexture:SetAlpha(1)
        end
        if self.Background then
            self.Background:Hide()
        end
        if self.PushedBackground then
            self.PushedBackground:Hide()
        end
        if self.Shadow then
            self.Shadow:Hide()
        end
        if self.PushedShadow then
            self.PushedShadow:Hide()
        end
        if self.FlashBorder then
            self.FlashBorder:SetAtlas("hud-microbutton-highlightalert", true)
            self.FlashBorder:ClearAllPoints()
            self.FlashBorder:SetPoint("TOPLEFT", -2, 2)
        end
        if self.FlashContent then
            UIFrameFlashStop(self.FlashContent)
        end
        if self.Emblem then
            self.Emblem:Hide()
        end
        if self.HighlightEmblem then
            self.HighlightEmblem:Hide()
        end
        self:SetHighlightAtlas("hud-microbutton-highlight")
    end)

    if not MicroButtonPortrait then
        local portrait = CharacterMicroButton:CreateTexture("MicroButtonPortrait", "OVERLAY")
        portrait:SetSize(16, 22)
        portrait:SetPoint("TOP", 0, -8)
        portrait:SetTexCoord(0.2, 0.8, 0.0666, 0.9)
    end

    CharacterMicroButton:HookScript("OnEvent", function(self, event, ...)
        if ( event == "UNIT_PORTRAIT_UPDATE" ) then
            local unit = ...;
            if ( unit == "player" ) then
                SetPortraitTexture(MicroButtonPortrait, "player")
            end
        elseif ( event == "PORTRAITS_UPDATED" ) then
            SetPortraitTexture(MicroButtonPortrait, "player")
        elseif ( event == "PLAYER_ENTERING_WORLD" ) then
            SetPortraitTexture(MicroButtonPortrait, "player")
        end
    end)

    local function CharacterMicroButton_SetPushed()
        MicroButtonPortrait:SetTexCoord(0.2666, 0.8666, 0, 0.8333)
        MicroButtonPortrait:SetAlpha(0.5)
    end

    local function CharacterMicroButton_SetNormal()
        MicroButtonPortrait:SetTexCoord(0.2, 0.8, 0.0666, 0.9)
        MicroButtonPortrait:SetAlpha(1.0)
    end

    CharacterMicroButton:HookScript("OnMouseDown", function(self)
        if ( not KeybindFrames_InQuickKeybindMode() and self:IsEnabled() ) then
            MicroButtonPortrait:SetTexCoord(0.2666, 0.8666, 0, 0.8333)
            MicroButtonPortrait:SetAlpha(0.5)
        end
    end)

    CharacterMicroButton:HookScript("OnMouseUp", function(self)
        if ( not KeybindFrames_InQuickKeybindMode() and self:IsEnabled() ) then
            MicroButtonPortrait:SetTexCoord(0.2, 0.8, 0.0666, 0.9)
            MicroButtonPortrait:SetAlpha(1.0)
        end
    end)

    if not MainMenuBarDownload then
        MainMenuBarDownload = MainMenuMicroButton:CreateTexture("MainMenuBarDownload", "OVERLAY")
        MainMenuBarDownload:SetSize(28, 28)
        MainMenuBarDownload:SetPoint("BOTTOM", MainMenuMicroButton, "BOTTOM", 0, -7)
    end
    
    MainMenuMicroButton:HookScript("OnUpdate", function(self, elapsed)
        local status = GetFileStreamingStatus();
        if ( status == 0 ) then
            MainMenuBarDownload:Hide()
            self:SetNormalAtlas("hud-microbutton-MainMenu-Up", true)
            self:SetPushedAtlas("hud-microbutton-MainMenu-Down", true)
            self:SetDisabledAtlas("hud-microbutton-MainMenu-Disabled", true)
        else
            self:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonStreamDL-Up")
            self:SetPushedTexture("Interface\\Buttons\\UI-MicroButtonStreamDL-Down")
            self:SetDisabledTexture("Interface\\Buttons\\UI-MicroButtonStreamDL-Up")
        if ( status == 1 ) then
            MainMenuBarDownload:SetTexture("Interface\\BUTTONS\\UI-MicroStream-Green")
        elseif ( status == 2 ) then
            MainMenuBarDownload:SetTexture("Interface\\BUTTONS\\UI-MicroStream-Yellow")
        elseif ( status == 3 ) then
            MainMenuBarDownload:SetTexture("Interface\\BUTTONS\\UI-MicroStream-Red")
        end
            MainMenuBarDownload:Show()
        end
    end)

    if not GuildMicroButtonTabard then
        local GuildMicroButtonTabard = CreateFrame("Frame", "GuildMicroButtonTabard", GuildMicroButton)
        GuildMicroButtonTabard:SetSize(28, 36)
        GuildMicroButtonTabard:SetPoint("TOPLEFT")
        GuildMicroButtonTabard:Hide()
    end

    if not GuildMicroButtonTabardBackground then
        GuildMicroButtonTabard.background = GuildMicroButtonTabard:CreateTexture("GuildMicroButtonTabardBackground", "ARTWORK")
        GuildMicroButtonTabardBackground:SetAtlas("hud-microbutton-Guild-Banner", true)
        GuildMicroButtonTabardBackground:SetPoint("CENTER", 0, 0)
    end

    if not GuildMicroButtonTabardEmblem then
        GuildMicroButtonTabard.emblem = GuildMicroButtonTabard:CreateTexture("GuildMicroButtonTabardEmblem", "OVERLAY")
        GuildMicroButtonTabardEmblem:SetSize(14, 14)
        GuildMicroButtonTabardEmblem:SetTexture("Interface\\GuildFrame\\GuildEmblems_01")
        GuildMicroButtonTabardEmblem:SetPoint("CENTER", 0, 0)
    end

    GuildMicroButton:HookScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            GuildMicroButtonTabard:SetPoint("TOPLEFT", -1, -1)
            GuildMicroButtonTabard:SetAlpha(0.5)
        end
    end)

    GuildMicroButton:HookScript("OnMouseUp", function(self)
        if self:IsEnabled() then
            GuildMicroButtonTabard:SetPoint("TOPLEFT", 0, 0)
            GuildMicroButtonTabard:SetAlpha(1.0)
        end
    end)

    hooksecurefunc(GuildMicroButton, "UpdateNotificationIcon", function(self)
        self.NotificationOverlay:Hide()
    end)

    hooksecurefunc(GuildMicroButton, "UpdateTabard", function()
        local tabard = GuildMicroButtonTabard;
        if ( not tabard.needsUpdate ) then
            return;
        end
        -- switch textures if the guild has a custom tabard
        local emblemFilename = select(10, GetGuildLogoInfo())
        if ( emblemFilename ) then
            if ( not tabard:IsShown() ) then
                local button = GuildMicroButton;
                button:SetNormalAtlas("hud-microbutton-Character-Up", true)
                button:SetPushedAtlas("hud-microbutton-Character-Down", true)
                button:SetDisabledAtlas("hud-microbutton-Character-Up", true)
                tabard:Show()
            end
            SetSmallGuildTabardTextures("player", tabard.emblem, tabard.background)
        else
            if ( tabard:IsShown() ) then
                local button = GuildMicroButton;
                button:SetNormalAtlas("hud-microbutton-Socials-Up", true)
                button:SetPushedAtlas("hud-microbutton-Socials-Down", true)
                button:SetDisabledAtlas("hud-microbutton-Socials-Disabled", true)
                tabard:Hide()
            end
        end
        tabard.needsUpdate = nil;
    end)

    GuildMicroButton:HookScript("OnEvent", function(self, event, ...)
        if ( event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_GUILD_UPDATE" or event == "NEUTRAL_FACTION_SELECT_RESULT" ) then
            GuildMicroButtonTabard.needsUpdate = true;
        end
    end)

    hooksecurefunc("UpdateMicroButtons", function()
        if AchievementMicroButton:IsEnabled() then
            AchievementMicroButton.tooltipText = MicroButtonTooltipText(ACHIEVEMENT_BUTTON, "TOGGLEACHIEVEMENT");
        end
        if CharacterMicroButton.Portrait then
            CharacterMicroButton.Portrait:Hide()
        end
        if CharacterMicroButton.PortraitMask then
            CharacterMicroButton.PortraitMask:Hide()
        end
        if ( CharacterFrame and CharacterFrame:IsShown() ) then
            CharacterMicroButton_SetPushed()
        else
            CharacterMicroButton_SetNormal()
        end
        if not CharacterMicroButton:IsEnabled() then
            SetDesaturation(MicroButtonPortrait, true)
        else
            SetDesaturation(MicroButtonPortrait, false)
        end
        GuildMicroButton:GetNormalTexture():SetVertexColor(1, 1, 1)
        GuildMicroButton:GetPushedTexture():SetVertexColor(1, 1, 1)
        GuildMicroButton:GetDisabledTexture():SetVertexColor(1, 1, 1)
        GuildMicroButton:GetHighlightTexture():SetVertexColor(1, 1, 1)
        if ( CommunitiesFrame and CommunitiesFrame:IsShown() ) or ( GuildFrame and GuildFrame:IsShown() ) then
            GuildMicroButtonTabard:SetPoint("TOPLEFT", -1, -1)
            GuildMicroButtonTabard:SetAlpha(0.70)
        else
            GuildMicroButtonTabard:SetPoint("TOPLEFT", 0, 0)
            GuildMicroButtonTabard:SetAlpha(1)
        end
    end)

    hooksecurefunc("LoadMicroButtonTextures", function()
        local button = GuildMicroButton
        local emblemFilename = select(10, GetGuildLogoInfo())
        if ( emblemFilename ) then
            button:SetNormalAtlas("hud-microbutton-Character-Up", true)
            button:SetPushedAtlas("hud-microbutton-Character-Down", true)
            button:SetDisabledAtlas("hud-microbutton-Character-Up", true)
        else
            button:SetNormalAtlas("hud-microbutton-Socials-Up", true)
            button:SetPushedAtlas("hud-microbutton-Socials-Down", true)
            button:SetDisabledAtlas("hud-microbutton-Socials-Disabled", true)
        end
    end)

    hooksecurefunc("HelpOpenWebTicketButton_OnUpdate", function(self)
        self:SetParent(MainMenuMicroButton)
        self:ClearAllPoints()
        self:SetPoint("CENTER", MainMenuMicroButton, "TOPRIGHT", -3, -26)
    end)

    button.skinned = true
end

MenuBar:Extend(
    'OnCreate',
    function(self)
        self.activeButtons = {}
        self.overrideButtons = {}

        local function getOrHook(frame, script, action)
            if frame:GetScript(script) then
                frame:HookScript(script, action)
            else
                frame:SetScript(script, action)
            end
        end

        local requestLayoutUpdate = Addon:Defer(function() self:Layout() end, 0)

        hooksecurefunc('UpdateMicroButtons', requestLayoutUpdate)

        if PetBattleFrame and PetBattleFrame.BottomFrame and PetBattleFrame.BottomFrame.MicroButtonFrame then
            local petMicroButtons = PetBattleFrame.BottomFrame.MicroButtonFrame

            getOrHook(
                petMicroButtons,
                'OnShow',
                function()
                    self.isPetBattleUIShown = true
                    requestLayoutUpdate()
                end
            )

            getOrHook(
                petMicroButtons,
                'OnHide',
                function()
                    self.isPetBattleUIShown = nil
                    requestLayoutUpdate()
                end
            )
        end

        if OverrideActionBar then
            getOrHook(
                OverrideActionBar,
                'OnShow',
                function()
                    self.isOverrideUIShown = Addon:UsingOverrideUI()
                    requestLayoutUpdate()
                end
            )

            getOrHook(
                OverrideActionBar,
                'OnHide',
                function()
                    self.isOverrideUIShown = nil
                    requestLayoutUpdate()
                end
            )
        end
    end
)

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

    for _, name in ipairs(MICRO_BUTTONS) do
        local button = _G[name]
        self:Skin(button)
        if not self:IsMenuButtonDisabled(button) then
            tinsert(self.activeButtons, button)
        end
    end
end

function MenuBar:UpdateOverrideBarButtons()
    wipe(self.overrideButtons)

    local isStoreEnabled = C_StorePublic.IsEnabled()

    for _, buttonName in ipairs(MICRO_BUTTONS) do
        local shouldAddButton

        if buttonName == 'HelpMicroButton' then
            shouldAddButton = not isStoreEnabled
        elseif buttonName == 'StoreMicroButton' then
            shouldAddButton = isStoreEnabled
        else
            shouldAddButton = true
        end

        if shouldAddButton then
            tinsert(self.overrideButtons, _G[buttonName])
        end
    end
end

function MenuBar:ReloadButtons()
    self:UpdateActiveButtons()

    MenuBar.proto.ReloadButtons(self)
end

function MenuBar:DisableMenuButton(button, disabled)
    local disabledButtons = self.sets.disabled or {}

    disabledButtons[button:GetName()] = disabled or false
    self.sets.disabled = disabledButtons

    self:ReloadButtons()
end

function MenuBar:IsMenuButtonDisabled(button)
    local disabledButtons = self.sets.disabled

    if disabledButtons then
        return disabledButtons[button:GetName()]
    end

    return false
end

function MenuBar:Layout()
    if self.isPetBattleUIShown then
        self:LayoutPetBattle()
    elseif self.isOverrideUIShown then
        self:LayoutOverrideUI()
    else
        self:LayoutNormal()
    end
end

function MenuBar:LayoutNormal()
    for _, name in pairs(MICRO_BUTTONS) do
        local button = _G[name]
        if button then
            button:Hide()
        end
    end

    for _, button in pairs(self.buttons) do
        button:Show()
    end

    MenuBar.proto.Layout(self)
end

function MenuBar:LayoutPetBattle()
    self:FixButtonPositions()
end

function MenuBar:LayoutOverrideUI()
    self:FixButtonPositions()
end

function MenuBar:FixButtonPositions()
    self:UpdateOverrideBarButtons()

    local l, r, t, b = self:GetButtonInsets()

    for i, button in ipairs(self.overrideButtons) do
        if i > 1 then
            button:ClearAllPoints()

            if i == 7 then
                button:SetPoint('TOPLEFT', self.overrideButtons[1], 'BOTTOMLEFT', 0, (t - b) - 3)
            else
                button:SetPoint('BOTTOMLEFT', self.overrideButtons[i - 1], 'BOTTOMRIGHT', (l - r) - 1, 0)
            end
        end

        button:Show()
    end
end

-- exports
Addon.MenuBar = MenuBar

--------------------------------------------------------------------------------
-- context menu
--------------------------------------------------------------------------------

local function MenuButtonCheckbox_Create(panel, button, name)
    if not button then
        return
    end

    return panel:NewCheckButton {
        name = name or button:GetName(),
        get = function()
            return not panel.owner:IsMenuButtonDisabled(button)
        end,
        set = function(_, enable)
            panel.owner:DisableMenuButton(button, not enable)
        end
    }
end

local function Menu_AddDisableMenuButtonsPanel(menu)
    local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local panel = menu:NewPanel(L.Buttons)
    local prev = nil
    local width, height = 0, 0

    for _, buttonName in ipairs(MICRO_BUTTONS) do
        local button = MenuButtonCheckbox_Create(panel, _G[buttonName], MICRO_BUTTON_NAMES[buttonName])
        if button then
            if prev then
                button:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -2)
            else
                button:SetPoint('TOPLEFT', 0, -2)
            end

            local bWidth, bHeight = button:GetEffectiveSize()
            width = math.max(width, bWidth)
            height = height + (bHeight + 2)
            prev = button
        end
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
    local perf = MainMenuMicroButton and MainMenuMicroButton.MainMenuBarPerformanceBar
    if perf then
        perf:SetSize(28, 58)
        perf:ClearAllPoints()
        perf:SetPoint('BOTTOM')
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
