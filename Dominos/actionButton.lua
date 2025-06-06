--------------------------------------------------------------------------------
-- ActionButton
-- Additional methods we define on action buttons
--------------------------------------------------------------------------------
local AddonName, Addon = ...
local ActionButton = {}

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
    -- 7-11
    elseif id <= 132 then
        return
    end
end

function ActionButton:OnCreate(id)
    -- initialize secure state
    self:SetAttributeNoHandler("action", 0)
    self:SetAttributeNoHandler("commandName", GetActionButtonCommand(id) or ("CLICK %s:HOTKEY"):format(self:GetName()))
    self:SetAttributeNoHandler("showgrid", 0)
    self:SetAttributeNoHandler("useparent-checkfocuscast", true)
    self:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    self:SetAttributeNoHandler("useparent-checkselfcast", true)

    -- register for clicks on all buttons, and enable mousewheel bindings
    self:EnableMouseWheel()
    self:RegisterForClicks("AnyUp", "AnyDown")

    -- secure handlers
    self:SetAttributeNoHandler('_childupdate-offset', [[
        local offset = message or 0
        local id = self:GetAttribute('index') + offset

        if self:GetAttribute('action') ~= id then
            self:SetAttribute('action', id)
        end
    ]])

    self:SetAttributeNoHandler("SetShowGrid", [[
        local show, reason, force = ...
        local value = self:GetAttribute("showgrid")
        local prevValue = value

        if show then
            if value % (reason * 2) < reason then
                value = value + reason
            end
        elseif value % (reason * 2) >= reason then
            value = value - reason
        end

        if (prevValue ~= value) or force then
            self:SetAttribute("showgrid", value)

            local show = (value > 0 or HasAction(self:GetAttribute("action")))
                and not self:GetAttribute("statehidden")

            if show then
                self:Show(true)
            else
                self:Hide(true)
            end
        end
    ]])

    self:SetAttributeNoHandler("UpdateShown", [[
        local show = (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
            and not self:GetAttribute("statehidden")

        if show then
            self:Show(true)
        else
            self:Hide(true)
        end
    ]])

    -- ...and the rest
    Addon.BindableButton:AddQuickBindingSupport(self)
end

function ActionButton:UpdateIcon()
    local icon = GetActionTexture(self.action)
    if icon then
        self.icon:SetTexture(icon)
        self.icon:Show()
    else
        self.icon:Hide()
    end
end

function ActionButton:UpdateOverrideBindings()
    if InCombatLockdown() then return end

    self.bind:SetOverrideBindings(GetBindingKey(self:GetAttribute("commandName")))
end

function ActionButton:UpdateShown()
    if InCombatLockdown() then return end

    self:SetShown(
        (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
        and not self:GetAttribute("statehidden")
    )
end

--------------------------------------------------------------------------------
-- configuration
--------------------------------------------------------------------------------

function ActionButton:SetFlyoutDirectionInsecure(direction)
    if InCombatLockdown() then return end

    self:SetAttribute("flyoutDirection", direction)
    self:UpdateFlyout()
end

-- the stock UI shows and hides hotkeys based on if there's a binding or not
-- so we simply make our hotkeys transparent when we don't want them shown
function ActionButton:SetShowBindingText(show)
    local parent = (show and self) or Addon.ShadowUIParent

    if self.HotKey:GetParent() ~= parent then
        self.HotKey:SetParent(parent)
    end
end

-- we hide cooldowns when action buttons are transparent
-- so that the sparks don't appear
function ActionButton:SetShowCooldowns(show)
    if show then
        if self.cooldown:GetParent() ~= self then
            self.cooldown:SetParent(self)
            ActionButton_UpdateCooldown(self)
        end
    else
        self.cooldown:SetParent(Addon.ShadowUIParent)
    end
end

function ActionButton:SetShowCounts(show)
    self.Count:SetShown(show)
end

function ActionButton:SetShowEquippedItemBorders(show)
    local parent = (show and self) or Addon.ShadowUIParent

    if self.Border:GetParent() ~= parent then
        self.Border:SetParent(parent)
    end
end

function ActionButton:SetShowEmptyButtons(show, force)
    self:SetShowGridInsecure(show, Addon.ActionButtons.ShowGridReasons.SHOW_EMPTY_BUTTONS_PER_BAR, force)
end

function ActionButton:SetShowGridInsecure(show, reason, force)
    if InCombatLockdown() then return end

    if type(reason) ~= "number" then
        error("Usage: ActionButton:SetShowGridInsecure(show, reason, force?)", 2)
    end

    local value = self:GetAttribute("showgrid") or 0
    local prevValue = value

    if show then
        value = bit.bor(value, reason)
    else
        value = bit.band(value, bit.bnot(reason))
    end

    if (value ~= prevValue) or force then
        self:SetAttribute("showgrid", value)
        self:UpdateShown()
    end
end

function ActionButton:SetShowMacroText(show)
    self.Name:SetShown(show and true)
end

-- exports
Addon.ActionButton = ActionButton

--------------------------------------------------------------------------------
-- Action Button 
-- A pool of action buttons
--------------------------------------------------------------------------------
local ActionButtons = CreateFrame('Frame', nil, nil, 'SecureHandlerAttributeTemplate')

-- constants
local ACTION_BUTTON_NAME_TEMPLATE = AddonName .. "ActionButton%d"

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- global showgrid event reasons
ActionButtons.ShowGridReasons = {
    -- CVAR = 1,
    GAME_EVENT = 2,
    SPELLBOOK_SHOWN = 4,

    KEYBOUND_EVENT = 16,
    SHOW_EMPTY_BUTTONS_PER_BAR = 32
}

-- states
-- [button] = action
ActionButtons.buttons = {}

ActionButtons:Execute([[
    ActionButtons = table.new()
    DirtyButtons = table.new()
]])

--------------------------------------------------------------------------------
-- Event and Callback Handling
--------------------------------------------------------------------------------

function ActionButtons:Initialize()
    -- register game events
    self:SetScript("OnEvent", function(f, event, ...) f[event](f, ...); end)
    self:RegisterEvent("ACTIONBAR_HIDEGRID")
    self:RegisterEvent("ACTIONBAR_SHOWGRID")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("SPELLS_CHANGED")

    -- library callbacks
    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
        self:SetShowGrid(keybound:IsShown(), self.ShowGridReasons.KEYBOUND_EVENT)
    end

    -- secure methods
    self:SetAttributeNoHandler("SetShowGrid", [[
        local show, reason, force = ...
        local value = self:GetAttribute("showgrid") or 0
        local prevValue = value

        if show then
            if value % (reason * 2) < reason then
                value = value + reason
            end
        elseif value % (reason * 2) >= reason then
            value = value - reason
        end

        if (prevValue ~= value) or force then
            self:SetAttribute("showgrid", value)

            for button in pairs(ActionButtons) do
                button:RunAttribute("SetShowGrid", show, reason)
            end
        end
    ]])

    self:SetAttributeNoHandler("ForActionSlot", [[
        local id, method = ...
        for button, action in pairs(ActionButtons) do
            if action == id then
                button:RunAttribute(method)
            end
        end
    ]])

    -- commit hack:
    -- we can leverage and attribute or secure state driver driver in order to
    -- cause something to happen on the next frame or so. We do this by marking
    -- buttons as dirty when something changes that we want to handle later, and
    -- then setting the commit attribute to 0. After STATE_DRIVER_UPDATE_THROTTLE
    -- duration (200ms), the value of commit will reset to our constant value of
    -- 1 and we'll apply the visibility change
    RegisterAttributeDriver(self, "commit", 1)

    self:SetAttributeNoHandler("_onattributechanged", [[
        if name == "commit" and value == 1 then
            for button in pairs(DirtyButtons) do
                button:RunAttribute("UpdateShown")
                DirtyButtons[button] = nil
            end
        end
    ]])

    -- showgrid hack:
    -- monitor ActionButton1's attribute changes to its showgrid attribute.
    -- When it changes, update the controller's show grid attribute for any of
    -- of the reasons only triggered by game events (like ACTIONBAR_SHOWGRID).
    -- Propagate those changes to all the buttons managed by the controller.
    -- This allows us to properly show and hide action buttons in combat
    -- when the player is attempting to drag and drop abilities
    self:WrapScript(ActionButton1, "OnAttributeChanged", [[
        if name ~= "showgrid" then return end

        for reason = 2, 4, 2 do
            local show = value % (reason * 2) >= reason
            control:RunAttribute("SetShowGrid", show, reason)
        end
    ]])

    self.Initialize = nil
end

function ActionButtons:ACTIONBAR_SHOWGRID()
    self:SetShowGrid(true, self.ShowGridReasons.GAME_EVENT)
end

function ActionButtons:ACTIONBAR_HIDEGRID()
    self:SetShowGrid(false, self.ShowGridReasons.GAME_EVENT)
end

function ActionButtons:ACTIONBAR_SLOT_CHANGED(slot)
    if slot == 0 or slot == nil then
        self:ForAll("UpdateIcon")
    else
        self:ForActionSlot(slot, "UpdateIcon")
    end
end

function ActionButtons:PLAYER_ENTERING_WORLD()
    self:ForAll("UpdateShown")
end

-- reset grid state at login. This covers waiting for the game to apply the
-- always show buttons state to the main bar
function ActionButtons:PLAYER_LOGIN()
    ActionButton1:SetAttribute("showgrid", 0)
end

-- force a visibility updates when spells changed (typically called when
-- switching talents)
function ActionButtons:SPELLS_CHANGED()
    self:ForAll("UpdateShown")
end

-- addon callbacks
function ActionButtons:LIBKEYBOUND_ENABLED()
    self:SetShowGrid(true, self.ShowGridReasons.KEYBOUND_EVENT)
end

function ActionButtons:LIBKEYBOUND_DISABLED()
    self:SetShowGrid(false, self.ShowGridReasons.KEYBOUND_EVENT)
end


function ActionButtons:OnActionChanged(buttonName, action)
    local button = _G[buttonName]
    if button ~= nil then
        self.buttons[button] = action
    end
end

--------------------------------------------------------------------------------
-- Action Button Constrution
--------------------------------------------------------------------------------

-- keep track of the current action associated with a button
-- mark the button as dirty when the action changes, so that we can make sure
-- it is properly shown later
local ActionButton_AttributeChanged = [[
    if name == "action" then
        local prevValue = ActionButtons[self]
        if prevValue ~= value then
            ActionButtons[self] = value

            DirtyButtons[self] = value
            control:SetAttribute("commit", 0)

            control:CallMethod("OnActionChanged", self:GetName(), value, prevValue)
        end
    end
]]

-- after clicking a button, or after dragging something onto a button, update
-- the visibility of any button with the same action. This is to handle placing
-- new actions on a button
local ActionButton_PostClick = [[
    control:RunAttribute("ForActionSlot", self:GetAttribute("action"), "UpdateShown")
]]

-- if we're dragging something onto a button, make sure to update the visibil;it
local ActionButton_ReceiveDragBefore = [[
    if kind then
        return "message", kind
    end
]]

local ActionButton_ReceiveDragAfter = [[
    control:RunAttribute("ForActionSlot", self:GetAttribute("action"), "UpdateShown")
]]

-- when showing or hiding a button, reapply the visibility of the button to
-- work around delayed updates and help mitigate flashing
local ActionButton_OnShowHide = [[
    self:RunAttribute("UpdateShown")
]]

local function GetActionButtonName(id)
    if id <= 0 then
        return
    -- 1, 2
    elseif id <= 24 then
        return ACTION_BUTTON_NAME_TEMPLATE:format(id)
    -- 3
    elseif id <= 36 then
        return ("MultiBarRightActionButton%d"):format(id - 24)
    -- 4
    elseif id <= 48 then
        return ("MultiBarLeftActionButton%d"):format(id - 36)
    -- 5
    elseif id <= 60 then
        return ("MultiBarBottomRightActionButton%d"):format(id - 48)
    -- 6
    elseif id <= 72 then
        return ("MultiBarBottomLeftActionButton%d"):format(id - 60)
    -- 7-11
    elseif id <= 132 then
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

function ActionButtons:GetOrCreateActionButton(id, parent)
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
        SafeMixin(button, Addon.ActionButton)

        -- initialize the button
        button:OnCreate(id)
        created = true
    -- button found, but not yet registered, reuse
    elseif self.buttons[button] == nil then
        -- add custom methods
        SafeMixin(button, Addon.ActionButton)

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
        self:WrapScript(button, "OnAttributeChanged", ActionButton_AttributeChanged)
        self:WrapScript(button, "PostClick", ActionButton_PostClick)
        self:WrapScript(button, "OnReceiveDrag", ActionButton_ReceiveDragBefore, ActionButton_ReceiveDragAfter)
        self:WrapScript(button, "OnShow", ActionButton_OnShowHide)
        self:WrapScript(button, "OnHide", ActionButton_OnShowHide)

        self:AddCastOnKeyPressSupport(button)

        -- register the button with the controller
        self:SetFrameRef("add", button)

        self:Execute([[
            local b = self:GetFrameRef("add")
            ActionButtons[b] = b:GetAttribute("action") or 0
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

-- cast on keypress support is implemented by using a second hidden button
-- that mirrors all ofthe attributes of its parent button. This is to work
-- around inconsistent handling of drag and drop if we just use the
-- SecureActionButtonTemplate for buttons, as well as the OnClick handler
-- for action buttons only triggering actions on key release.
function ActionButtons:AddCastOnKeyPressSupport(button)
    local bind = CreateFrame("Button", "$parentHotkey", button, "SecureActionButtonTemplate")

    bind:SetAttributeNoHandler("type", "action")
    bind:SetAttributeNoHandler("typerelease", "actionrelease")
    bind:SetAttributeNoHandler("useparent-action", true)
    bind:SetAttributeNoHandler("useparent-checkfocuscast", true)
    bind:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    bind:SetAttributeNoHandler("useparent-checkselfcast", true)
    bind:SetAttributeNoHandler("useparent-flyoutDirection", true)
    bind:SetAttributeNoHandler("useparent-pressAndHoldAction", true)
    bind:SetAttributeNoHandler("useparent-unit", true)
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

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

function ActionButtons:SetShowGrid(show, reason, force)
    self:ForAll("SetShowGridInsecure", show, reason, force)
end

--------------------------------------------------------------------------------
-- Collection Methods
--------------------------------------------------------------------------------

function ActionButtons:ForAll(method, ...)
    for button in pairs(self.buttons) do
        button[method](button, ...)
    end
end

function ActionButtons:ForActionSlot(slot, method, ...)
    for button, action in pairs(self.buttons) do
        if action == slot then
            button[method](button, ...)
        end
    end
end

function ActionButtons:GetAll()
    return pairs(self.buttons)
end

-- startup and export
ActionButtons:Initialize()

Addon.ActionButtons = ActionButtons