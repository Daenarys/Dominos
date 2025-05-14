--------------------------------------------------------------------------------
-- ActionButtonMixin
-- Additional methods we define on action buttons
--------------------------------------------------------------------------------
local AddonName, Addon = ...
local ActionButtonMixin = {}

local function GetActionButtonCommand(id)
    -- 0
    if id <= 0 then
        return
    -- 1
    elseif id <= 12 then
        return "ACTIONBUTTON" .. id
    -- 2
    elseif id <= 24 then
        return
    -- 3
    elseif id <= 36 then
        return "MULTIACTIONBAR3BUTTON" .. (id - 24)
    -- 4
    elseif id <= 48 then
        return "MULTIACTIONBAR4BUTTON" .. (id - 36)
    -- 5
    elseif id <= 60 then
        return "MULTIACTIONBAR2BUTTON" .. (id - 48)
    -- 6
    elseif id <= 72 then
        return "MULTIACTIONBAR1BUTTON" .. (id - 60)
    -- 7-10
    elseif id <= 120 then
        return
    end
end

function ActionButtonMixin:OnCreate(id)
    -- initialize secure state
    self:SetAttribute("action", 0)
    self:SetAttribute("commandName", GetActionButtonCommand(id) or self:GetName())
    self:SetAttribute("useparent-checkfocuscast", true)
    self:SetAttribute("useparent-checkmouseovercast", true)
    self:SetAttribute("useparent-checkselfcast", true)

    -- register for clicks on all buttons, and enable mousewheel bindings
    self:EnableMouseWheel()
    self:RegisterForClicks("AnyUp", "AnyDown")

    -- secure handlers
    self:SetAttribute('_childupdate-offset', [[
        local offset = message or 0
        local id = self:GetAttribute('index') + offset

        if self:GetAttribute('action') ~= id then
            self:SetAttribute('action', id)
            self:RunAttribute("UpdateShown")
        end
    ]])

    self:SetAttribute("UpdateShown", [[
        local show = (HasAction(self:GetAttribute("action")))
            and not self:GetAttribute("statehidden")

        if show then
            self:SetAlpha(1)
        else
            self:SetAlpha(0)
        end
    ]])

    -- apply hooks for quick binding
    Addon.BindableButton:AddQuickBindingSupport(self)
end

function ActionButtonMixin:UpdateOverrideBindings()
    if InCombatLockdown() then return end

    self.bind:SetOverrideBindings(GetBindingKey(self:GetAttribute("commandName")))
end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

function ActionButtonMixin:SetFlyoutDirection(direction)
    if InCombatLockdown() then return end

    self:SetAttribute("flyoutDirection", direction)
    self:UpdateFlyout()
end

function ActionButtonMixin:SetShowBindingText(show)
    self.HotKey:SetAlpha(show and 1 or 0)
end

function ActionButtonMixin:SetShowCountText(show)
    if show then
        self.Count:Show()
    else
        self.Count:Hide()
    end
end


function ActionButtonMixin:SetShowMacroText(show)
    self.Name:SetShown(show and true)
end

function ActionButtonMixin:SetShowEquippedItemBorders(show)
    if show then
        self.Border:SetParent(self)
    else
        self.Border:SetParent(Addon.ShadowUIParent)
    end
end

-- exports
Addon.ActionButtonMixin = ActionButtonMixin

--------------------------------------------------------------------------------
-- Action Button 
-- A pool of action buttons
--------------------------------------------------------------------------------
local ActionButton = CreateFrame('Frame', nil, nil, 'SecureHandlerAttributeTemplate')

-- constants
local ACTION_BUTTON_NAME_TEMPLATE = AddonName .. "ActionButton%d"

ActionButton.buttons = {}

ActionButton:Execute([[
    ActionButton = table.new()
]])

--------------------------------------------------------------------------------
-- Action Button Construction
--------------------------------------------------------------------------------

local function GetActionButtonName(id)
    if id <= 0 then
        return
    else
        return ACTION_BUTTON_NAME_TEMPLATE:format(id)
    end
end

local function SafeMixin(button, trait)
    for k, v in pairs(trait) do
        if rawget(button, k) ~= nil then
            error(("%s[%q] has alrady been set"):format(button:GetName(), k), 2)
        end

        button[k] = v
    end
end

function ActionButton:GetOrCreateActionButton(id, parent)
    local name = GetActionButtonName(id)
    if name == nil then
        error(("Invalid Action ID %q"):format(id))
    end

    local button = _G[name]
    local created = false

    -- button not found, create a new one
    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")

        -- add custom methods
        SafeMixin(button, Addon.ActionButtonMixin)

        -- initialize the button
        button:OnCreate(id)
        created = true
    -- button found, but not yet registered, reuse
    elseif self.buttons[button] == nil then
        -- add custom methods
        SafeMixin(button, Addon.ActionButtonMixin)

        -- reset the id of a button to zero to avoid triggering the paging
        -- logic of the standard UI
        button:SetParent(parent)
        button:SetID(0)

        -- drop the reference to the bar's original parent, which would otherwise
        -- call thing we do not want
        button.Bar = nil

        -- initialize the button
        button:OnCreate(id)
        created = true
    end

    if created then
        -- add secure handlers
        self:AddCastOnKeyPressSupport(button)

        -- register the button with the controller
        self:SetFrameRef("add", button)

        self:Execute([[
            local b = self:GetFrameRef("add")
            ActionButton[b] = b:GetAttribute("action") or 0
        ]])

        self.buttons[button] = 0
    end

    return button
end

-- update the pushed state of our parent button when pressing and releasing
-- the button's hotkey
local function bindButton_PreClick(self, _, down)
    local owner = self:GetParent()

    if down then
        if owner:GetButtonState() == "NORMAL" then
            owner:SetButtonState("PUSHED")
        end
    else
        if owner:GetButtonState() == "PUSHED" then
            owner:SetButtonState("NORMAL")
        end
    end
end

local function bindButton_SetOverrideBindings(self, ...)
    ClearOverrideBindings(self)

    local name = self:GetName()
    for i = 1, select("#", ...) do
        SetOverrideBindingClick(self, false, select(i, ...), name, "HOTKEY")
    end
end

function ActionButton:AddCastOnKeyPressSupport(button)
    local bind = CreateFrame("Button", "$parentHotkey", button, "SecureActionButtonTemplate")

    bind:SetAttribute("type", "action")
    bind:SetAttribute("typerelease", "actionrelease")
    bind:SetAttribute("useparent-action", true)
    bind:SetAttribute("useparent-checkfocuscast", true)
    bind:SetAttribute("useparent-checkmouseovercast", true)
    bind:SetAttribute("useparent-checkselfcast", true)
    bind:SetAttribute("useparent-flyoutDirection", true)
    bind:SetAttribute("useparent-pressAndHoldAction", true)
    bind:SetAttribute("useparent-unit", true)
    SecureHandlerSetFrameRef(bind, "owner", button)

    bind:EnableMouseWheel()
    bind:RegisterForClicks("AnyUp", "AnyDown")

    bind:SetScript("PreClick", bindButton_PreClick)

    bind.SetOverrideBindings = bindButton_SetOverrideBindings

    -- translate HOTKEY button "clicks" into LeftButton
    self:WrapScript(bind, "OnClick", [[
        if button == "HOTKEY" then
            return "LeftButton"
        end
    ]])

    button.bind = bind
    button:UpdateOverrideBindings()
end

-- exports
Addon.ActionButton = ActionButton