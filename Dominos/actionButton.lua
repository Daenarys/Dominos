--------------------------------------------------------------------------------
-- ActionButtonMixin
-- Additional methods we define on action buttons
--------------------------------------------------------------------------------
local AddonName, Addon = ...
local ActionButtonMixin = {}

function ActionButtonMixin:SetActionOffsetInsecure(offset)
    if InCombatLockdown() then
        return
    end

    local oldActionId = self:GetAttribute('action')
    local newActionId = self:GetAttribute('index') + (offset or 0)

    if oldActionId ~= newActionId then
        self:SetAttribute('action', newActionId)
        self:UpdateState()
    end
end

-- configuration commands
function ActionButtonMixin:SetFlyoutDirection(direction)
    if InCombatLockdown() then
        return
    end

    self:SetAttribute("flyoutDirection", direction)
    self:UpdateFlyout()
end

function ActionButtonMixin:SetShowCountText(show)
    if show then
        self.Count:Show()
    else
        self.Count:Hide()
    end
end

function ActionButtonMixin:SetShowMacroText(show)
    if show then
        self.Name:Show()
    else
        self.Name:Hide()
    end
end

function ActionButtonMixin:SetShowEquippedItemBorders(show)
    if show then
        self.Border:SetParent(self)
    else
        self.Border:SetParent(Addon.ShadowUIParent)
    end
end

-- we hide cooldowns when action buttons are transparent
-- so that the sparks don't appear
function ActionButtonMixin:SetShowCooldowns(show)
    if show then
        if self.cooldown:GetParent() ~= self then
            self.cooldown:SetParent(self)
            ActionButton_UpdateCooldown(self)
        end
    else
        self.cooldown:SetParent(Addon.ShadowUIParent)
    end
end

-- exports
Addon.ActionButtonMixin = ActionButtonMixin

--------------------------------------------------------------------------------
-- ActionButtons - A pool of action buttons
--------------------------------------------------------------------------------
local ACTION_BUTTON_COUNT = 120

local function createActionButton(id)
    local name = ('%sActionButton%d'):format(AddonName, id)
    local button = CreateFrame('CheckButton', name, nil, 'ActionBarButtonTemplate')

    Addon.BindableButton:AddCastOnKeyPressSupport(button)

    return button
end

local function acquireActionButton(id)
    if id <= 12 then
        return _G[('ActionButton%d'):format(id)]
    elseif id <= 24 then
        return _G[('MultiBar5Button%d'):format(id - 12)]
    elseif id <= 36 then
        return _G[('MultiBarRightButton%d'):format(id - 24)]
    elseif id <= 48 then
        return _G[('MultiBarLeftButton%d'):format(id - 36)]
    elseif id <= 60 then
        return _G[('MultiBarBottomRightButton%d'):format(id - 48)]
    elseif id <= 72 then
        return _G[('MultiBarBottomLeftButton%d'):format(id - 60)]
    elseif id <= 84 then
        return _G[('MultiBar6Button%d'):format(id - 72)]
    elseif id <= 96 then
        return _G[('MultiBar7Button%d'):format(id - 84)]
    else
        return createActionButton(id - 96)
    end
end

local function getBindingAction(button)
    local id = button:GetID()

    if id > 0 then
        return (button.buttonType or 'ACTIONBUTTON') .. id
    end
end

local function skinActionButton(self)
    self.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    self.NormalTexture:SetTexture([[Interface\Buttons\UI-Quickslot2]])
    self.NormalTexture:ClearAllPoints()
    self.NormalTexture:SetPoint("TOPLEFT", -15, 15)
    self.NormalTexture:SetPoint("BOTTOMRIGHT", 15, -15)
    self.NormalTexture:SetVertexColor(1, 1, 1, 0.5)
    self.PushedTexture:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
    self.PushedTexture:SetSize(36, 36)
    self.HighlightTexture:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
    self.HighlightTexture:SetSize(36, 36)
    self.HighlightTexture:SetBlendMode("ADD")
    self.CheckedTexture:SetTexture([[Interface\Buttons\CheckButtonHilight]])
    self.CheckedTexture:ClearAllPoints()
    self.CheckedTexture:SetAllPoints()
    self.CheckedTexture:SetBlendMode("ADD")
    self.NewActionTexture:SetSize(44, 44)
    self.NewActionTexture:SetAtlas("bags-newitem")
    self.NewActionTexture:ClearAllPoints()
    self.NewActionTexture:SetPoint("CENTER")
    self.NewActionTexture:SetBlendMode("ADD")
    self.SpellHighlightTexture:SetSize(44, 44)
    self.SpellHighlightTexture:SetAtlas("bags-newitem")
    self.SpellHighlightTexture:ClearAllPoints()
    self.SpellHighlightTexture:SetPoint("CENTER")
    self.SpellHighlightTexture:SetBlendMode("ADD")
    self.QuickKeybindHighlightTexture:SetAtlas("bags-newitem")
    self.QuickKeybindHighlightTexture:ClearAllPoints()
    self.QuickKeybindHighlightTexture:SetPoint("TOPLEFT", -2, 2)
    self.QuickKeybindHighlightTexture:SetPoint("BOTTOMRIGHT", 2, -2)
    self.QuickKeybindHighlightTexture:SetBlendMode("ADD")
    self.QuickKeybindHighlightTexture:SetAlpha(0.5)
    self.Border:ClearAllPoints()
    self.Border:SetPoint("TOPLEFT", -3, 3)
    self.Border:SetPoint("BOTTOMRIGHT", 3, -3)
    self.cooldown:ClearAllPoints()
    self.cooldown:SetAllPoints()
    self.Flash:SetTexture([[Interface\Buttons\UI-QuickslotRed]])
    self.Flash:ClearAllPoints()
    self.Flash:SetAllPoints()
    self.Count:ClearAllPoints()
    self.Count:SetPoint("BOTTOMRIGHT", -2, 2)

    if (self.RightDivider:IsShown()) then
        self.RightDivider:Hide()
    end
    if (self.BottomDivider:IsShown()) then
        self.BottomDivider:Hide()
    end
    if (self.SlotArt:IsShown()) then
        self.SlotArt:Hide()
    end
    if (self.SlotBackground:IsShown()) then
        self.SlotBackground:Hide()
    end

    if not self.FlyoutContainer then
        self.FlyoutContainer = CreateFrame("Frame", nil, self)
        self.FlyoutContainer:SetAllPoints()
        self.FlyoutContainer:Hide()
    end

    if not self.FlyoutArrow then
        self.FlyoutArrow = self.FlyoutContainer:CreateTexture()
        self.FlyoutArrow:SetSize(23, 11)
        self.FlyoutArrow:SetDrawLayer("ARTWORK", 2)
        self.FlyoutArrow:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
        self.FlyoutArrow:SetTexCoord(0.62500000, 0.98437500, 0.74218750, 0.82812500)
        self.FlyoutArrow:Hide()
    end

    hooksecurefunc(self, "UpdateFlyout", function()
        if not self.FlyoutArrowContainer then return end

        local actionType = GetActionInfo(self.action);
        if (actionType == "flyout") then
            self.FlyoutContainer:Show()
            self.FlyoutArrow:Show()
            self.FlyoutArrow:ClearAllPoints()
            local direction = self:GetAttribute("flyoutDirection")
            if (direction == "LEFT") then
                self.FlyoutArrow:SetPoint("LEFT", self, "LEFT", -5, 0)
                SetClampedTextureRotation(self.FlyoutArrow, 270)
            elseif (direction == "RIGHT") then
                self.FlyoutArrow:SetPoint("RIGHT", self, "RIGHT", -5, 0)
                SetClampedTextureRotation(self.FlyoutArrow, 90)
            elseif (direction == "DOWN") then
                self.FlyoutArrow:SetPoint("BOTTOM", self, "BOTTOM", 0, 5)
                SetClampedTextureRotation(self.FlyoutArrow, 180)
            else
                self.FlyoutArrow:SetPoint("TOP", self, "TOP", 0, 5)
            end
        else
            self.FlyoutContainer:Hide()
            self.FlyoutArrow:Hide()
        end
        self.FlyoutArrowContainer:Hide()
        self.FlyoutBorderShadow:Hide()
    end)
end

if (ActionBarActionEventsFrame) then
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_START")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_STOP")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_RETICLE_TARGET")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_RETICLE_CLEAR")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_START")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_SENT")
    ActionBarActionEventsFrame:UnregisterEvent("UNIT_SPELLCAST_FAILED")
end

local function OverlayGlowAnimOutFinished(animGroup)
    local overlay = animGroup:GetParent()
    local frame = overlay:GetParent()
    overlay:Hide()
    frame.ActionButtonOverlay = nil
end

local function OverlayGlow_OnHide(self)
    if self.animOut:IsPlaying() then
        self.animOut:Stop()
        OverlayGlowAnimOutFinished(self.animOut)
    end
end

local function OverlayGlow_OnUpdate(self, elapsed)
    AnimateTexCoords(self.ants, 256, 256, 48, 48, 22, elapsed, 0.01)
    local cooldown = self:GetParent().cooldown
    if cooldown and cooldown:IsShown() and cooldown:GetCooldownDuration() > 3000 then
        self:SetAlpha(0.5)
    else
        self:SetAlpha(1.0)
    end
end

local function CreateScaleAnim(group, target, order, duration, x, y, delay)
    local scale = group:CreateAnimation("Scale")
    scale:SetTarget(target)
    scale:SetOrder(order)
    scale:SetDuration(duration)
    scale:SetScale(x, y)

    if delay then
        scale:SetStartDelay(delay)
    end
end

local function CreateAlphaAnim(group, target, order, duration, fromAlpha, toAlpha, delay)
    local alpha = group:CreateAnimation("Alpha")
    alpha:SetTarget(target)
    alpha:SetOrder(order)
    alpha:SetDuration(duration)
    alpha:SetFromAlpha(fromAlpha)
    alpha:SetToAlpha(toAlpha)

    if delay then
        alpha:SetStartDelay(delay)
    end
end

local function AnimIn_OnPlay(group)
    local frame = group:GetParent()
    local frameWidth, frameHeight = frame:GetSize()
    frame.spark:SetSize(frameWidth, frameHeight)
    frame.spark:SetAlpha(0.3)
    frame.innerGlow:SetSize(frameWidth / 2, frameHeight / 2)
    frame.innerGlow:SetAlpha(1.0)
    frame.innerGlowOver:SetAlpha(1.0)
    frame.outerGlow:SetSize(frameWidth * 2, frameHeight * 2)
    frame.outerGlow:SetAlpha(1.0)
    frame.outerGlowOver:SetAlpha(1.0)
    frame.ants:SetSize(frameWidth * 0.85, frameHeight * 0.85)
    frame.ants:SetAlpha(0)
    frame:Show()
end

local function AnimIn_OnFinished(group)
    local frame = group:GetParent()
    local frameWidth, frameHeight = frame:GetSize()
    frame.spark:SetAlpha(0)
    frame.innerGlow:SetAlpha(0)
    frame.innerGlow:SetSize(frameWidth, frameHeight)
    frame.innerGlowOver:SetAlpha(0.0)
    frame.outerGlow:SetSize(frameWidth, frameHeight)
    frame.outerGlowOver:SetAlpha(0.0)
    frame.outerGlowOver:SetSize(frameWidth, frameHeight)
    frame.ants:SetAlpha(1.0)
end

hooksecurefunc("ActionButton_SetupOverlayGlow", function(button)
    if button.SpellActivationAlert then
        button.SpellActivationAlert:SetAlpha(0)
    end

    if button.ActionButtonOverlay then
        return;
    end

    local name = button:GetName()
    local overlay = CreateFrame("Frame", name, UIParent)

    -- spark
    overlay.spark = overlay:CreateTexture(name .. "Spark", "BACKGROUND")
    overlay.spark:SetPoint("CENTER")
    overlay.spark:SetAlpha(0)
    overlay.spark:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
    overlay.spark:SetTexCoord(0.00781250, 0.61718750, 0.00390625, 0.26953125)

    -- inner glow
    overlay.innerGlow = overlay:CreateTexture(name .. "InnerGlow", "ARTWORK")
    overlay.innerGlow:SetPoint("CENTER")
    overlay.innerGlow:SetAlpha(0)
    overlay.innerGlow:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
    overlay.innerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

    -- inner glow over
    overlay.innerGlowOver = overlay:CreateTexture(name .. "InnerGlowOver", "ARTWORK")
    overlay.innerGlowOver:SetPoint("TOPLEFT", overlay.innerGlow, "TOPLEFT")
    overlay.innerGlowOver:SetPoint("BOTTOMRIGHT", overlay.innerGlow, "BOTTOMRIGHT")
    overlay.innerGlowOver:SetAlpha(0)
    overlay.innerGlowOver:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
    overlay.innerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

    -- outer glow
    overlay.outerGlow = overlay:CreateTexture(name .. "OuterGlow", "ARTWORK")
    overlay.outerGlow:SetPoint("CENTER")
    overlay.outerGlow:SetAlpha(0)
    overlay.outerGlow:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
    overlay.outerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

    -- outer glow over
    overlay.outerGlowOver = overlay:CreateTexture(name .. "OuterGlowOver", "ARTWORK")
    overlay.outerGlowOver:SetPoint("TOPLEFT", overlay.outerGlow, "TOPLEFT")
    overlay.outerGlowOver:SetPoint("BOTTOMRIGHT", overlay.outerGlow, "BOTTOMRIGHT")
    overlay.outerGlowOver:SetAlpha(0)
    overlay.outerGlowOver:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
    overlay.outerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

    -- ants
    overlay.ants = overlay:CreateTexture(name .. "Ants", "OVERLAY")
    overlay.ants:SetPoint("CENTER")
    overlay.ants:SetAlpha(0)
    overlay.ants:SetTexture([[Interface\SpellActivationOverlay\IconAlertAnts]])

    -- setup antimations
    overlay.animIn = overlay:CreateAnimationGroup()
    CreateScaleAnim(overlay.animIn, overlay.spark,          1, 0.2, 1.5, 1.5)
    CreateAlphaAnim(overlay.animIn, overlay.spark,          1, 0.2, 0, 1)
    CreateScaleAnim(overlay.animIn, overlay.innerGlow,      1, 0.3, 2, 2)
    CreateScaleAnim(overlay.animIn, overlay.innerGlowOver,  1, 0.3, 2, 2)
    CreateAlphaAnim(overlay.animIn, overlay.innerGlowOver,  1, 0.3, 1, 0)
    CreateScaleAnim(overlay.animIn, overlay.outerGlow,      1, 0.3, 0.5, 0.5)
    CreateScaleAnim(overlay.animIn, overlay.outerGlowOver,  1, 0.3, 0.5, 0.5)
    CreateAlphaAnim(overlay.animIn, overlay.outerGlowOver,  1, 0.3, 1, 0)
    CreateScaleAnim(overlay.animIn, overlay.spark,          1, 0.2, 2/3, 2/3, 0.2)
    CreateAlphaAnim(overlay.animIn, overlay.spark,          1, 0.2, 1, 0, 0.2)
    CreateAlphaAnim(overlay.animIn, overlay.innerGlow,      1, 0.2, 1, 0, 0.3)
    CreateAlphaAnim(overlay.animIn, overlay.ants,           1, 0.2, 0, 1, 0.3)
    overlay.animIn:SetScript("OnPlay", AnimIn_OnPlay)
    overlay.animIn:SetScript("OnFinished", AnimIn_OnFinished)

    overlay.animOut = overlay:CreateAnimationGroup()
    CreateAlphaAnim(overlay.animOut, overlay.outerGlowOver, 1, 0.2, 0, 1)
    CreateAlphaAnim(overlay.animOut, overlay.ants,          1, 0.2, 1, 0)
    CreateAlphaAnim(overlay.animOut, overlay.outerGlowOver, 2, 0.2, 1, 0)
    CreateAlphaAnim(overlay.animOut, overlay.outerGlow,     2, 0.2, 1, 0)
    overlay.animOut:SetScript("OnFinished", OverlayGlowAnimOutFinished)

    -- scripts
    overlay:SetScript("OnUpdate", OverlayGlow_OnUpdate)
    overlay:SetScript("OnHide", OverlayGlow_OnHide)

    local frameWidth, frameHeight = button:GetSize()
    overlay:SetParent(button)
    overlay:SetFrameLevel(button:GetFrameLevel() + 5)
    overlay:ClearAllPoints()
    overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2)
    overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2)
    overlay.animIn:Play()
    button.ActionButtonOverlay = overlay
end)

hooksecurefunc("ActionButton_ShowOverlayGlow", function(button)
    if button.ActionButtonOverlay then
        if button.ActionButtonOverlay.animOut:IsPlaying() then
            button.ActionButtonOverlay.animOut:Stop()
            button.ActionButtonOverlay.animIn:Play()
        end
    end
end)

hooksecurefunc("ActionButton_HideOverlayGlow", function(button)
    if button.ActionButtonOverlay then
        if button.ActionButtonOverlay.animIn:IsPlaying() then
            button.ActionButtonOverlay.animIn:Stop()
        end
        if button:IsVisible() then
            button.ActionButtonOverlay.animOut:Play()
        else
            OverlayGlowAnimOutFinished(button.ActionButtonOverlay.animOut)
        end
    end
end)

hooksecurefunc("StartChargeCooldown", function(parent)
    parent.chargeCooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
    parent.chargeCooldown:SetAllPoints(parent)
end)

-- handle notifications from our parent bar about whate the action button
-- ID offset should be
local actionButton_OnUpdateOffset = [[
    local offset = message or 0
    local id = self:GetAttribute('index') + offset

    if self:GetAttribute('action') ~= id then
        self:SetAttribute('action', id)
        self:RunAttribute("UpdateShown")
        self:CallMethod('UpdateState')
    end
]]

local actionButton_UpdateShown = [[
    local show = (HasAction(self:GetAttribute("action")))
                 and not self:GetAttribute("statehidden")
    if show then
        self:SetAlpha(1.0)
    else
        self:SetAlpha(0.0)
    end
]]

-- action button creation is deferred so that we can avoid creating buttons for
-- bars set to show less than the maximum
local ActionButtons = setmetatable({}, {
    -- index creates & initializes buttons as we need them
    __index = function(self, id)
        -- validate the ID of the button we're getting is within an
        -- our expected range
        id = tonumber(id) or 0
        if id < 1 or id > ACTION_BUTTON_COUNT then
            error(('Usage: %s.ActionButtons[1-%d]'):format(AddonName, ACTION_BUTTON_COUNT), 2)
        end

        local button = acquireActionButton(id)
        
        -- apply our extra action button methods
        Mixin(button, Addon.ActionButtonMixin)

        -- apply hooks for quick binding
        -- this must be done before we reset the button ID, as we use it
        -- to figure out the binding action for the button
        Addon.BindableButton:AddQuickBindingSupport(button, getBindingAction(button))

        -- set a handler for updating the action from a parent frame
        button:SetAttribute('_childupdate-offset', actionButton_OnUpdateOffset)
        button:SetAttribute("UpdateShown", actionButton_UpdateShown)

        -- reset the ID to zero, as that prevents the default paging code
        -- from being used
        button:SetID(0)

        -- clear current position to avoid forbidden frame issues
        button:ClearAllPoints()

        -- reset the showgrid setting to default
        button:SetAttribute('showgrid', 1)

        -- enable mousewheel clicks
        button:EnableMouseWheel(true)

        -- use the pre 10.x button size
        button:SetSize(36, 36)

        -- apply the pre 10.x button skin
        skinActionButton(button)

        -- restore the cooldown bling
        if button.cooldown then
            button.cooldown:SetDrawBling(true)
        end

        -- disable to prevent art updates
        if button.UpdateButtonArt then
            button.UpdateButtonArt = function() end
        end

        -- implement custom flyout handling
        Addon.SpellFlyout:WrapScript(button, "OnClick", [[
            if not down then
                local actionType, actionID = GetActionInfo(self:GetAttribute("action"))
                if actionType == "flyout" then
                    control:SetAttribute("caller", self)
                    control:RunAttribute("Toggle", actionID)
                    return false
                end
            end
        ]])

        rawset(self, id, button)
        return button
    end,
    -- newindex is set to block writes to prevent errors
    __newindex = function()
        error(('%s.ActionButtons does not support writes'):format(AddonName), 2)
    end
})

-- exports
Addon.ActionButtons = ActionButtons