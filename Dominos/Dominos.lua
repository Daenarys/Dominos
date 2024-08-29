-- Dominos.lua - The main driver for Dominos
local AddonName, AddonTable = ...
local Addon = LibStub('AceAddon-3.0'):NewAddon(AddonTable, AddonName, 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local KeyBound = LibStub('LibKeyBound-1.0')

local ADDON_VERSION = GetAddOnMetadata(AddonName, 'Version')
local CONFIG_ADDON_NAME = AddonName .. '_Config'

-- setup custom callbacks
Addon.callbacks = LibStub('CallbackHandler-1.0'):New(Addon)

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function Addon:OnInitialize()
    -- setup db
    self:CreateDatabase()
    self:UpgradeDatabase()

    -- keybound support
    local kb = KeyBound
    kb.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
    kb.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')

    -- slash command support
    self:RegisterSlashCommands()
end

function Addon:OnEnable()
    self:HideBlizzard()
    self:UpdateUseOverrideUI()
    self:CreateDataBrokerPlugin()
    self:Load()
end

function Addon:CreateDataBrokerPlugin()
    local dataObject = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject(AddonName, {
        type = 'launcher',
        icon = [[Interface\Addons\Dominos\icons\Dominos]],

        OnClick = function(_, button)
            if button == 'LeftButton' then
                if IsShiftKeyDown() then
                    Addon:ToggleBindingMode()
                else
                    Addon:ToggleLockedFrames()
                end
            elseif button == 'RightButton' then
                Addon:ShowOptionsFrame()
            end
        end,

        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then
                return
            end

            GameTooltip_SetTitle(tooltip, AddonName)

            if Addon:Locked() then
                GameTooltip_AddInstructionLine(tooltip, L.ConfigEnterTip)
            else
                GameTooltip_AddInstructionLine(tooltip, L.ConfigExitTip)
            end

            if Addon:IsBindingModeEnabled() then
                GameTooltip_AddInstructionLine(tooltip, L.BindingExitTip)
            else
                GameTooltip_AddInstructionLine(tooltip, L.BindingEnterTip)
            end

            if Addon:IsConfigAddonEnabled() then
                GameTooltip_AddInstructionLine(tooltip, L.ShowOptionsTip)
            end
        end,
    })

    LibStub('LibDBIcon-1.0'):Register(AddonName, dataObject, self.db.profile.minimap)
end

-- configuration events
function Addon:OnUpgradeDatabase(oldVersion, newVersion)
end

function Addon:OnUpgradeAddon(oldVersion, newVersion)
    self:Printf(L.Updated, ADDON_VERSION)
end

-- keybound events
function Addon:LIBKEYBOUND_ENABLED()
    self.Frame:ForAll('KEYBOUND_ENABLED')
end

function Addon:LIBKEYBOUND_DISABLED()
    self.Frame:ForAll('KEYBOUND_DISABLED')
end

-- profile events
function Addon:OnNewProfile(msg, db, name)
    self:Printf(L.ProfileCreated, name)
end

function Addon:OnProfileDeleted(msg, db, name)
    self:Printf(L.ProfileDeleted, name)
end

function Addon:OnProfileChanged(msg, db, name)
    self:Printf(L.ProfileLoaded, name)
    self:Load()
end

function Addon:OnProfileCopied(msg, db, name)
    self:Printf(L.ProfileCopied, name)
    self:Reload()
end

function Addon:OnProfileReset(msg, db)
    self:Printf(L.ProfileReset, db:GetCurrentProfile())
    self:Reload()
end

function Addon:OnProfileShutdown(msg, db, name)
    self:Unload()
end

--------------------------------------------------------------------------------
-- Layout Lifecycle
--------------------------------------------------------------------------------

-- Load is called when the addon is first enabled, and also whenever a profile
-- is loaded
function Addon:Load()
    self.callbacks:Fire('LAYOUT_LOADING')

    local function module_load(module, id)
        if not self.db.profile.modules[id] then
            return
        end

        local f = module.Load
        if type(f) == 'function' then
            f(module)
        end
    end

    for id, module in self:IterateModules() do
        local success, msg = pcall(module_load, module, id)
        if not success then
            self:Printf('Failed to load %s\n%s', module:GetName(), msg)
        end
    end

    self.Frame:ForAll('RestoreAnchor')
    self.callbacks:Fire('LAYOUT_LOADED')
end

-- unload is called when we're switching profiles
function Addon:Unload()
    self.callbacks:Fire('LAYOUT_UNLOADING')

    local function module_unload(module, id)
        if not self.db.profile.modules[id] then
            return
        end

        local f = module.Unload
        if type(f) == 'function' then
            f(module)
        end
    end

    -- unload any module stuff
    for id, module in self:IterateModules() do
        local success, msg = pcall(module_unload, module, id)
        if not success then
            self:Printf('Failed to unload %s\n%s', module:GetName(), msg)
        end
    end

    self.callbacks:Fire('LAYOUT_UNLOADED')
end

function Addon:Reload()
    self:Unload()
    self:Load()
end

--------------------------------------------------------------------------------
-- Database Setup
--------------------------------------------------------------------------------

-- db actions
function Addon:CreateDatabase()
    local dbName = AddonName .. 'DB'
    local dbDefaults = self:GetDatabaseDefaults()
    local defaultProfileName = UnitClass('player')
    local db = LibStub('AceDB-3.0'):New(dbName, dbDefaults, defaultProfileName)

    local LibDualSpec = LibStub('LibDualSpec-1.0', true)

    if LibDualSpec then
        LibDualSpec:EnhanceDatabase(db, dbName)
    end

    db.RegisterCallback(self, 'OnNewProfile')
    db.RegisterCallback(self, 'OnProfileChanged')
    db.RegisterCallback(self, 'OnProfileCopied')
    db.RegisterCallback(self, 'OnProfileDeleted')
    db.RegisterCallback(self, 'OnProfileReset')
    db.RegisterCallback(self, 'OnProfileShutdown')

    self.db = db
end

function Addon:GetDatabaseDefaults()
    return {
        profile = {
            possessBar = 1,
            sticky = true,
            linkedOpacity = false,
            showMacroText = true,
            showBindingText = true,
            showCounts = true,
            showEquippedItemBorders = true,
            showTooltips = true,
            showTooltipsCombat = true,
            useOverrideUI = false,

            minimap = { hide = false },

            ab = { count = 10, showgrid = true, rightClickUnit = 'player' },

            frames = { bags = { point = 'BOTTOMRIGHT', oneBag = true, keyRing = true, spacing = 2 } },

            alignmentGrid = { enabled = true, size = 32 },

            -- what modules are enabled
            -- module[id] = enabled
            modules = { ['**'] = true }
        }
    }
end

function Addon:UpgradeDatabase()
    local configVerison = self.db.global.configVersion
    if configVerison ~= CONFIG_VERSION then
        self:OnUpgradeDatabase(configVerison, CONFIG_VERSION)
        self.db.global.configVersion = CONFIG_VERSION
    end

    local addonVersion = self.db.global.addonVersion
    if addonVersion ~= ADDON_VERSION then
        self:OnUpgradeAddon(addonVersion, ADDON_VERSION)
        self.db.global.addonVersion = ADDON_VERSION
    end
end

--------------------------------------------------------------------------------
-- Profiles
--------------------------------------------------------------------------------

-- profile actions
function Addon:SaveProfile(name)
    local toCopy = self.db:GetCurrentProfile()
    if name and name ~= toCopy then
        self.db:SetProfile(name)
        self.db:CopyProfile(toCopy)
    end
end

function Addon:SetProfile(name)
    local profile = self:MatchProfile(name)
    if profile and profile ~= self.db:GetCurrentProfile() then
        self.db:SetProfile(profile)
    else
        self:Printf(L.InvalidProfile, name or 'null')
    end
end

function Addon:DeleteProfile(name)
    local profile = self:MatchProfile(name)
    if profile and profile ~= self.db:GetCurrentProfile() then
        self.db:DeleteProfile(profile)
    else
        self:Print(L.CantDeleteCurrentProfile)
    end
end

function Addon:CopyProfile(name)
    if name and name ~= self.db:GetCurrentProfile() then
        self.db:CopyProfile(name)
    end
end

function Addon:ResetProfile()
    self.db:ResetProfile()
end

function Addon:ListProfiles()
    self:Print(L.AvailableProfiles)

    local current = self.db:GetCurrentProfile()
    for _, k in ipairs(self.db:GetProfiles()) do
        if k == current then
            print(' - ' .. k, 1, 1, 0)
        else
            print(' - ' .. k)
        end
    end
end

function Addon:MatchProfile(name)
    name = name:lower()

    local nameRealm = name .. ' - ' .. GetRealmName():lower()
    local match

    for _, k in ipairs(self.db:GetProfiles()) do
        local key = k:lower()
        if key == name then
            return k
        elseif key == nameRealm then
            match = k
        end
    end

    return match
end

--------------------------------------------------------------------------------
-- Configuration UI
--------------------------------------------------------------------------------

function Addon:ShowOptionsFrame()
    if InCombatLockdown() then
        self:Printf(_G.ERR_NOT_IN_COMBAT)
        return
    end

    if self:IsConfigAddonEnabled() and LoadAddOn(CONFIG_ADDON_NAME) then
        local dialog = LibStub('AceConfigDialog-3.0')

        dialog:Open(AddonName)
        dialog:SelectGroup(AddonName, "general")

        return true
    end

    return false
end

function Addon:NewMenu()
    if not self:IsConfigAddonEnabled() then
        return
    end

    if not IsAddOnLoaded(CONFIG_ADDON_NAME) then
        LoadAddOn(CONFIG_ADDON_NAME)
    end

    return self.Options.Menu:New()
end

function Addon:IsConfigAddonEnabled()
    if GetAddOnEnableState(UnitName('player'), CONFIG_ADDON_NAME) >= 1 then
        return true
    end
end

--------------------------------------------------------------------------------
-- Configuration API
--------------------------------------------------------------------------------

-- frame settings

function Addon:SetFrameSets(id, sets)
    id = tonumber(id) or id

    self.db.profile.frames[id] = sets

    return self.db.profile.frames[id]
end

function Addon:GetFrameSets(id)
    return self.db.profile.frames[tonumber(id) or id]
end

-- configuration mode
Addon.locked = true

function Addon:SetLock(locked)
    if InCombatLockdown() and (not locked) then
        self:Printf(_G.ERR_NOT_IN_COMBAT)
        return
    end

    if locked and (not self:Locked()) then
        self.locked = true
        self.callbacks:Fire('CONFIG_MODE_DISABLED')
    elseif (not locked) and self:Locked() then
        self.locked = false
        
        if not IsAddOnLoaded(CONFIG_ADDON_NAME) then
            LoadAddOn(CONFIG_ADDON_NAME)
        end

        self.callbacks:Fire('CONFIG_MODE_ENABLED')
    end
end

function Addon:Locked()
    return self.locked
end

function Addon:ToggleLockedFrames()
    self:SetLock(not self:Locked())
end

-- binding mode
function Addon:SetBindingMode(enable)
    if enable and (not self:IsBindingModeEnabled()) then
        self:SetLock(true)
        KeyBound:Activate()
    elseif (not enable) and self:IsBindingModeEnabled() then
        KeyBound:Deactivate()
    end
end

function Addon:IsBindingModeEnabled()
    return KeyBound:IsShown()
end

function Addon:ToggleBindingMode()
    self:SetBindingMode(not self:IsBindingModeEnabled())
end

-- scale
function Addon:ScaleFrames(...)
    local numArgs = select('#', ...)
    local scale = tonumber(select(numArgs, ...))

    if scale and scale > 0 and scale <= 10 then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetFrameScale', scale)
        end
    end
end

-- opacity
function Addon:SetOpacityForFrames(...)
    local numArgs = select('#', ...)
    local alpha = tonumber(select(numArgs, ...))

    if alpha and alpha >= 0 and alpha <= 1 then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetFrameAlpha', alpha)
        end
    end
end

-- faded opacity
function Addon:SetFadeForFrames(...)
    local numArgs = select('#', ...)
    local alpha = tonumber(select(numArgs, ...))

    if alpha and alpha >= 0 and alpha <= 1 then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetFadeMultiplier', alpha)
        end
    end
end

-- columns
function Addon:SetColumnsForFrames(...)
    local numArgs = select('#', ...)
    local cols = tonumber(select(numArgs, ...))

    if cols then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetColumns', cols)
        end
    end
end

-- spacing
function Addon:SetSpacingForFrame(...)
    local numArgs = select('#', ...)
    local spacing = tonumber(select(numArgs, ...))

    if spacing then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetSpacing', spacing)
        end
    end
end

-- padding
function Addon:SetPaddingForFrames(...)
    local numArgs = select('#', ...)
    local pW, pH = select(numArgs - 1, ...)

    if tonumber(pW) and tonumber(pH) then
        for i = 1, numArgs - 2 do
            self.Frame:ForFrame(select(i, ...), 'SetPadding', tonumber(pW), tonumber(pH))
        end
    end
end

-- visibility
function Addon:ShowFrames(...)
    for i = 1, select('#', ...) do
        self.Frame:ForFrame(select(i, ...), 'ShowFrame')
    end
end

function Addon:HideFrames(...)
    for i = 1, select('#', ...) do
        self.Frame:ForFrame(select(i, ...), 'HideFrame')
    end
end

function Addon:ToggleFrames(...)
    for i = 1, select('#', ...) do
        self.Frame:ForFrame(select(i, ...), 'ToggleFrame')
    end
end

-- clickthrough
function Addon:SetClickThroughForFrames(...)
    local numArgs = select('#', ...)
    local enable = select(numArgs - 1, ...)

    for i = 1, numArgs - 2 do
        self.Frame:ForFrame(select(i, ...), 'SetClickThrough', tonumber(enable) == 1)
    end
end

-- empty button display
function Addon:ToggleGrid()
    self:SetShowGrid(not self:ShowGrid())
end

function Addon:SetShowGrid(enable)
    self.db.profile.showgrid = enable or false
    self.Frame:ForAll('UpdateGrid')
end

function Addon:ShowGrid()
    return self.db.profile.showgrid
end

-- right click selfcast
function Addon:SetRightClickUnit(unit)
    self.db.profile.ab.rightClickUnit = unit
    self.Frame:ForAll('SetRightClickUnit', unit)
end

function Addon:GetRightClickUnit()
    return self.db.profile.ab.rightClickUnit
end

-- binding text
function Addon:SetShowBindingText(enable)
    self.db.profile.showBindingText = enable or false
    self.Frame:ForAll('ForButtons', 'UpdateHotkeys')
end

function Addon:ShowBindingText()
    return self.db.profile.showBindingText
end

-- macro text
function Addon:SetShowMacroText(enable)
    self.db.profile.showMacroText = enable or false
    self.Frame:ForAll('ForButtons', 'SetShowMacroText', enable)
end

function Addon:ShowMacroText()
    return self.db.profile.showMacroText
end

-- border
function Addon:SetShowEquippedItemBorders(enable)
    self.db.profile.showEquippedItemBorders = enable or false
    self.Frame:ForAll('ForButtons', 'SetShowEquippedItemBorders', enable)
end

function Addon:ShowEquippedItemBorders()
    return self.db.profile.showEquippedItemBorders
end

-- override ui
function Addon:SetUseOverrideUI(enable)
    self.db.profile.useOverrideUI = enable and true or false
    self:UpdateUseOverrideUI()
end

function Addon:UsingOverrideUI()
    return self.db.profile.useOverrideUI and self:IsBuild('retail', 'wrath')
end

function Addon:UpdateUseOverrideUI()
    if not self.OverrideController then return end

    local useOverrideUi = self:UsingOverrideUI()

    self.OverrideController:SetAttribute('state-useoverrideui', useOverrideUi)

    local oab = _G.OverrideActionBar
    if oab then
        oab:ClearAllPoints()

        if useOverrideUi then
            oab:SetPoint('BOTTOM')
        else
            oab:SetPoint('LEFT', oab:GetParent(), 'RIGHT', 100, 0)
        end
    end
end

-- override action bar selection
function Addon:SetOverrideBar(id)
    local prevBar = self:GetOverrideBar()

    self.db.profile.possessBar = id
    local newBar = self:GetOverrideBar()

    prevBar:UpdateOverrideBar()
    newBar:UpdateOverrideBar()
end

function Addon:GetOverrideBar()
    return self.Frame:Get(self.db.profile.possessBar)
end

-- action bar counts
function Addon:SetNumBars(count)
    count = Clamp(count, 1, self.ACTION_BUTTON_COUNT)

    if count ~= self:NumBars() then
        self.db.profile.ab.count = count
        self.callbacks:Fire('ACTIONBAR_COUNT_UPDATED', count)
    end
end

function Addon:SetNumButtons(count)
    self:SetNumBars(self.ACTION_BUTTON_COUNT / count)
end

function Addon:NumBars()
    return self.db.profile.ab.count
end

-- tooltips
function Addon:ShowTooltips()
    return self.db.profile.showTooltips
end

function Addon:SetShowTooltips(enable)
    self.db.profile.showTooltips = enable or false
    self:GetModule('Tooltips'):SetShowTooltips(enable)
end

function Addon:SetShowCombatTooltips(enable)
    self.db.profile.showTooltipsCombat = enable or false
    self:GetModule('Tooltips'):SetShowTooltipsInCombat(enable)
end

function Addon:ShowCombatTooltips()
    return self.db.profile.showTooltipsCombat
end

-- minimap button
function Addon:SetShowMinimap(enable)
    self.db.profile.minimap.hide = not enable
    self:GetModule('Launcher'):Update()
end

function Addon:ShowingMinimap()
    return not self.db.profile.minimap.hide
end

-- sticky bars
function Addon:SetSticky(enable)
    self.db.profile.sticky = enable or false

    if not enable then
        self.Frame:ForAll('Stick')
        self.Frame:ForAll('Reposition')
    end
end

function Addon:Sticky()
    return self.db.profile.sticky
end

-- linked opacity
function Addon:SetLinkedOpacity(enable)
    self.db.profile.linkedOpacity = enable or false

    self.Frame:ForAll('UpdateWatched')
    self.Frame:ForAll('UpdateAlpha')
end

function Addon:IsLinkedOpacityEnabled()
    return self.db.profile.linkedOpacity
end

-- show counts toggle
function Addon:ShowCounts()
    return self.db.profile.showCounts
end

function Addon:SetShowCounts(enable)
    self.db.profile.showCounts = enable or false
    self.Frame:ForAll('ForButtons', 'SetShowCountText', enable)
end

-- alignment grid
function Addon:SetAlignmentGridEnabled(enable)
    self.db.profile.alignmentGrid.enabled = enable
    self.callbacks:Fire('ALIGNMENT_GRID_ENABLED', self:GetAlignmentGridEnabled())
end

function Addon:GetAlignmentGridEnabled()
    return self.db.profile.alignmentGrid.enabled and true or false
end

function Addon:SetAlignmentGridSize(size)
    self.db.profile.alignmentGrid.size = tonumber(size)
    self.callbacks:Fire('ALIGNMENT_GRID_SIZE_CHANGED', self:GetAlignmentGridSize())
end

function Addon:GetAlignmentGridSize()
    return self.db.profile.alignmentGrid.size
end

function Addon:GetAlignmentGridScale()
    -- due to changes in Dominos_Config\overlay\ui.lua to
    -- function "DrawGrid", grid now displays with perfectly square subdivisions.
    local gridScale = GetScreenHeight() / (Addon:GetAlignmentGridSize() * 2)
    return gridScale, gridScale
end

--------------------------------------------------------------------------------
-- Blizzard Hider
--------------------------------------------------------------------------------

function Addon:HideBlizzard()
    local function purgeKey(t, k)
        t[k] = nil
        local c = 42
        repeat
            if t[c] == nil then
                t[c] = nil
            end
            c = c + 1
        until issecurevariable(t, k)
    end

    local function hideActionBarFrame(frame, clearEvents)
        if frame then
            if clearEvents then
                frame:UnregisterAllEvents()
            end

            if frame.system then
                purgeKey(frame, "isShownExternal")
            end

            if frame.HideBase then
                frame:HideBase()
            else
                frame:Hide()
            end
            frame:SetParent(Addon.ShadowUIParent)
        end
    end

    local function hideActionButton(button)
        if not button then return end

        button:Hide()
        button:UnregisterAllEvents()
        button:SetAttribute("statehidden", true)
    end

    hideActionBarFrame(MainMenuBar, false)
    hideActionBarFrame(MultiBarBottomLeft, true)
    hideActionBarFrame(MultiBarBottomRight, true)
    hideActionBarFrame(MultiBarLeft, true)
    hideActionBarFrame(MultiBarRight, true)
    hideActionBarFrame(MultiBar5, true)
    hideActionBarFrame(MultiBar6, true)
    hideActionBarFrame(MultiBar7, true)

    -- Hide MultiBar Buttons, but keep the bars alive
    for i=1,12 do
        hideActionButton(_G["ActionButton" .. i])
        hideActionButton(_G["MultiBarBottomLeftButton" .. i])
        hideActionButton(_G["MultiBarBottomRightButton" .. i])
        hideActionButton(_G["MultiBarRightButton" .. i])
        hideActionButton(_G["MultiBarLeftButton" .. i])
        hideActionButton(_G["MultiBar5Button" .. i])
        hideActionButton(_G["MultiBar6Button" .. i])
        hideActionButton(_G["MultiBar7Button" .. i])
    end

    hideActionBarFrame(MicroButtonAndBagsBar, false)
    hideActionBarFrame(StanceBar, true)
    hideActionBarFrame(PossessActionBar, true)
    hideActionBarFrame(MultiCastActionBarFrame, false)
    hideActionBarFrame(PetActionBar, false)
    hideActionBarFrame(StatusTrackingBarManager, false)
    hideActionBarFrame(MainMenuBarVehicleLeaveButton, true)
    hideActionBarFrame(BagsBar, true)
    hideActionBarFrame(MicroMenu, true)
    hideActionBarFrame(MicroMenuContainer, true)

    -- these events drive visibility, we want the MainMenuBar to remain invisible
    MainMenuBar:UnregisterEvent("PLAYER_REGEN_ENABLED")
    MainMenuBar:UnregisterEvent("PLAYER_REGEN_DISABLED")
    MainMenuBar:UnregisterEvent("ACTIONBAR_SHOWGRID")
    MainMenuBar:UnregisterEvent("ACTIONBAR_HIDEGRID")

    -- these functions drive visibility so disable them
    MultiActionBar_ShowAllGrids = function() end
    MultiActionBar_HideAllGrids = function() end
end

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

function Addon:RegisterSlashCommands()
    self:RegisterChatCommand('dominos', 'OnCmd')
    self:RegisterChatCommand('dom', 'OnCmd')
end

function Addon:OnCmd(args)
    local cmd = string.split(' ', args):lower() or args:lower()

    if cmd == 'config' or cmd == 'lock' then
        Addon:ToggleLockedFrames()
    elseif cmd == 'bind' then
        Addon:ToggleBindingMode()
    elseif cmd == 'scale' then
        Addon:ScaleFrames(select(2, string.split(' ', args)))
    elseif cmd == 'setalpha' then
        Addon:SetOpacityForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'fade' then
        Addon:SetFadeForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'setcols' then
        Addon:SetColumnsForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'pad' then
        Addon:SetPaddingForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'space' then
        Addon:SetSpacingForFrame(select(2, string.split(' ', args)))
    elseif cmd == 'show' then
        Addon:ShowFrames(select(2, string.split(' ', args)))
    elseif cmd == 'hide' then
        Addon:HideFrames(select(2, string.split(' ', args)))
    elseif cmd == 'toggle' then
        Addon:ToggleFrames(select(2, string.split(' ', args)))
    elseif cmd == 'numbars' then
        Addon:SetNumBars(tonumber(select(2, string.split(' ', args))))
    elseif cmd == 'numbuttons' then
        Addon:SetNumButtons(tonumber(select(2, string.split(' ', args))))
    elseif cmd == 'save' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        Addon:SaveProfile(profileName)
    elseif cmd == 'set' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        Addon:SetProfile(profileName)
    elseif cmd == 'copy' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        Addon:CopyProfile(profileName)
    elseif cmd == 'delete' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        Addon:DeleteProfile(profileName)
    elseif cmd == 'reset' then
        Addon:ResetProfile()
    elseif cmd == 'list' then
        Addon:ListProfiles()
    elseif cmd == 'version' then
        Addon:PrintVersion()
    elseif cmd == 'help' or cmd == '?' then
        self:PrintHelp()
    else
        if not Addon:ShowOptionsFrame() then
            self:PrintHelp()
        end
    end
end

do
    local function printCommand(cmd, desc)
        print((' - |cFF33FF99%s|r: %s'):format(cmd, desc))
    end

    function Addon:PrintHelp(cmd)
        Addon:Print('Commands (/dom, /dominos)')

        printCommand('config', L.ConfigDesc)
        printCommand('scale <frameList> <scale>', L.SetScaleDesc)
        printCommand('setalpha <frameList> <opacity>', L.SetAlphaDesc)
        printCommand('fade <frameList> <opacity>', L.SetFadeDesc)
        printCommand('setcols <frameList> <columns>', L.SetColsDesc)
        printCommand('pad <frameList> <padding>', L.SetPadDesc)
        printCommand('space <frameList> <spacing>', L.SetSpacingDesc)
        printCommand('show <frameList>', L.ShowFramesDesc)
        printCommand('hide <frameList>', L.HideFramesDesc)
        printCommand('toggle <frameList>', L.ToggleFramesDesc)
        printCommand('save <profile>', L.SaveDesc)
        printCommand('set <profile>', L.SetDesc)
        printCommand('copy <profile>', L.CopyDesc)
        printCommand('delete <profile>', L.DeleteDesc)
        printCommand('reset', L.ResetDesc)
        printCommand('list', L.ListDesc)
        printCommand('version', L.PrintVersionDesc)
    end
end

-- display the current addon build being used
function Addon:PrintVersion()
    self:Printf('%s', ADDON_VERSION)
end

--------------------------------------------------------------------------------
-- Utility Methods
--------------------------------------------------------------------------------

-- create a frame, and then hide it
function Addon:CreateHiddenFrame(...)
    local frame = CreateFrame(...)

    frame:Hide()

    return frame
end

-- a hidden frame with the same dimensions as the uiparent
local ShadowUIParent = Addon:CreateHiddenFrame('Frame', nil, UIParent)
ShadowUIParent:SetAllPoints(UIParent)

Addon.ShadowUIParent = ShadowUIParent

-- A utility function for extending blizzard widget types (Frames, Buttons, etc)
do
    -- extend basically just does a post hook of an existing object method
    -- its here so that I can not forget to do class.proto.thing when hooking
    -- thing
    local function class_Extend(class, method, func)
        if not (type(method) == 'string' and type(func) == 'function') then
            error('Usage: Class:Extend("method", func)', 2)
        end

        if type(class.proto[method]) ~= 'function' then
            error(('Parent has no method named %q'):format(method), 2)
        end

        class[method] = function(self, ...)
            class.proto[method](self, ...)

            return func(self, ...)
        end
    end

    function Addon:CreateClass(frameType, prototype)
        local class = self:CreateHiddenFrame(frameType)

        local class_mt = {__index = class}

        class.Bind = function(_, object)
            return setmetatable(object, class_mt)
        end

        if type(prototype) == 'table' then
            class.proto = prototype
            class.Extend = class_Extend

            setmetatable(class, {__index = prototype})
        end

        return class
    end
end

-- returns a function that generates unique names for frames
-- in the format <AddonName>_<Prefix>[1, 2, ...]
function Addon:CreateNameGenerator(prefix)
    local id = 0
    return function()
        id = id + 1
        return ('%s_%s_%d'):format(AddonName, prefix, id)
    end
end

-- A functional way to fade a frame from one opacity to another without constantly
-- creating new animation groups for the frame
do

    local function clouseEnough(value1, value2)
        return _G.Round(value1 * 100) == _G.Round(value2 * 100)
    end

    -- track the time the animation started playing
    -- this is so that we can figure out how long we've been delaying for
    local function animation_OnPlay(self)
        self.start = _G.GetTime()
    end

    local function sequence_OnFinished(self)
        if self.alpha then
            self:GetParent():SetAlpha(self.alpha)
            self.alpha = nil
        end
    end

    local function sequence_Create(frame)
        local sequence = frame:CreateAnimationGroup()
        sequence:SetLooping('NONE')
        sequence:SetScript('OnFinished', sequence_OnFinished)
        sequence.alpha = nil

        local animation = sequence:CreateAnimation('Alpha')
        animation:SetSmoothing('IN_OUT')
        animation:SetOrder(0)
        animation:SetScript('OnPlay', animation_OnPlay)

        return sequence, animation
    end

    Addon.Fade =
        setmetatable(
        {},
        {
            __call = function(self, addon, frame, toAlpha, delay, duration)
                return self[frame](toAlpha, delay, duration)
            end,

            __index = function(self, frame)
                local sequence, animation

                -- handle animation requests
                local function func(toAlpha, delay, duration)
                    -- we're already at target alpha, stop
                    if clouseEnough(frame:GetAlpha(), toAlpha) then
                        if sequence and sequence:IsPlaying() then
                            sequence:Stop()
                            return
                        end
                    end

                    -- create the animation if we've not yet done so
                    if not sequence then
                        sequence, animation = sequence_Create(frame)
                    end

                    local fromAlpha = frame:GetAlpha()

                    -- animation already started, but is in the delay phase
                    -- so shorten the delay by however much time has gone by
                    if animation:IsDelaying() then
                        delay = math.max(delay - (_G.GetTime() - animation.start), 0)
                    -- we're already in the middle of a fade animation
                    elseif animation:IsPlaying() then
                        -- set delay to zero, as we don't want to pause in the
                        -- middle of an animation
                        delay = 0

                        -- figure out what opacity we're currently at
                        -- by using the animation progress
                        local delta = animation:GetFromAlpha() - animation:GetToAlpha()
                        fromAlpha = animation:GetFromAlpha() + (delta * animation:GetSmoothProgress())
                    end

                    -- check that value against our current one
                    -- if so, quit early
                    if clouseEnough(fromAlpha, toAlpha) then
                        frame:SetAlpha(toAlpha)

                        if sequence:IsPlaying() then
                            sequence:Stop()
                            return
                        end
                    end

                    sequence.alpha = toAlpha
                    animation:SetFromAlpha(frame:GetAlpha())
                    animation:SetToAlpha(toAlpha)
                    animation:SetStartDelay(delay)
                    animation:SetDuration(duration)

                    sequence:Restart()
                end

                self[frame] = func
                return func
            end
        }
    )
end

-- somewhere between a debounce and a throttle
function Addon:Defer(func, delay, arg1)
    delay = delay or 0

    local waiting = false

    local function callback()
        func(arg1)

        waiting = false
    end

    return function()
        if not waiting then
            waiting = true

            C_Timer.After(delay or 0, callback)
        end
    end
end

--------------------------------------------------------------------------------
-- Extra's
--------------------------------------------------------------------------------

if not (IsAddOnLoaded("ClassicFrames")) then
    -- load and position the lfg eye
    if (IsAddOnLoaded("SexyMap")) then
        hooksecurefunc(QueueStatusButton, "UpdatePosition", function(self)
            self:SetParent(Minimap)
            self:SetFrameLevel(6)
            self:SetScale(0.6)
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 23, -208)
        end)
    else
        hooksecurefunc(QueueStatusButton, "UpdatePosition", function(self)
            self:SetParent(MinimapBackdrop)
            self:SetFrameLevel(6)
            self:SetScale(0.85)
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", MinimapBackdrop,"TOPLEFT", 45, -217)
        end)
    end

    hooksecurefunc("QueueStatusDropDown_Show", function()
        DropDownList1:ClearAllPoints()
        DropDownList1:SetPoint("BOTTOMLEFT", QueueStatusButton, "BOTTOMLEFT", 0, -62)
    end)

    hooksecurefunc(QueueStatusFrame, "UpdatePosition", function(self)
        self:ClearAllPoints();
        self:SetPoint("TOPRIGHT", QueueStatusButton, "TOPLEFT", -1, 1);
    end)

    -- rare/elite dragon portrait improvements
    hooksecurefunc(TargetFrame, "CheckClassification", function(self)
        local classification = UnitClassification(self.unit)

        local bossPortraitFrameTexture = self.TargetFrameContainer.BossPortraitFrameTexture
        if (classification == "rare") then
            bossPortraitFrameTexture:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver", TextureKitConstants.UseAtlasSize)
            bossPortraitFrameTexture:SetPoint("TOPRIGHT", -11, -8)
            bossPortraitFrameTexture:Show()
        elseif (classification == "elite") then
            bossPortraitFrameTexture:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged", TextureKitConstants.UseAtlasSize)
            bossPortraitFrameTexture:SetPoint("TOPRIGHT", 8, -7)
        end
        self.TargetFrameContent.TargetFrameContentContextual.BossIcon:Hide()
    end)

    -- rare dragon on nameplates
    hooksecurefunc("CompactUnitFrame_UpdateClassificationIndicator", function(frame)
        local classification = UnitClassification(frame.unit);
        if ( classification == "rare" ) then
            frame.classificationIndicator:SetAtlas("nameplates-icon-elite-silver");
            frame.classificationIndicator:Show();
        end
    end)
end

-- exports
_G[AddonName] = Addon