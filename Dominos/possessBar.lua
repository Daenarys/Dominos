--------------------------------------------------------------------------------
-- Possess bar
-- Handles the exit button for vehicles and taxis
--------------------------------------------------------------------------------

local AddonName, Addon = ...

--------------------------------------------------------------------------------
-- Button setup
--------------------------------------------------------------------------------

local function possessButton_OnClick(self)
    self:SetChecked(false)

    if UnitOnTaxi("player") then
        TaxiRequestEarlyLanding()
        self:SetChecked(true)
        self:Disable()
    elseif CanExitVehicle() then
        VehicleExit()
    else
        CancelPetPossess()
    end
end

local function possessButton_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    if UnitOnTaxi("player") then
        GameTooltip_SetTitle(GameTooltip, TAXI_CANCEL)
        GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    elseif UnitControllingVehicle("player") and CanExitVehicle() then
        GameTooltip_SetTitle(GameTooltip, LEAVE_VEHICLE)
    else
        GameTooltip:SetText(CANCEL)
    end

    GameTooltip:Show()
end

local function possessButton_OnLeave(self)
    if GameTooltip:IsOwned(self) then
        GameTooltip:Hide()
    end
end

local function possessButton_OnCreate(self)
    self:SetScript("OnClick", possessButton_OnClick)
    self:SetScript("OnEnter", possessButton_OnEnter)
    self:SetScript("OnLeave", possessButton_OnLeave)
end

local function getOrCreatePossessButton(id)
    local name = ('%sPossessButton%d'):format(AddonName, id)
    local button = _G[name]

    if not button then
        if SmallActionButtonMixin then
            button = CreateFrame("CheckButton", name, nil, "SmallActionButtonTemplate", id)
            button.cooldown:SetSwipeColor(0, 0, 0)
        else
            button = CreateFrame("CheckButton", name, nil, "ActionButtonTemplate", id)
            button:SetSize(30, 30)
        end

        possessButton_OnCreate(button)
    end

    return button
end

--------------------------------------------------------------------------------
-- Bar setup
--------------------------------------------------------------------------------

local PossessBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function PossessBar:New()
    return PossessBar.proto.New(self, 'possess')
end

function PossessBar:GetDisplayName()
    return _G.BINDING_NAME_VEHICLEEXIT
end

function PossessBar:GetDisplayConditions()
    return '[canexitvehicle][possessbar]show;hide'
end

function PossessBar:GetDefaults()
    return {
        point = 'CENTER',
        x = 244,
        y = 0,
        spacing = 4,
        padW = 2,
        padH = 2
    }
end

function PossessBar:NumButtons()
    return 1
end

function PossessBar:AcquireButton()
    return getOrCreatePossessButton(POSSESS_CANCEL_SLOT)
end

function PossessBar:OnAttachButton(button)
    Addon:GetModule('Tooltips'):Register(button)
end

function PossessBar:OnDetachButton(button)
    Addon:GetModule('Tooltips'):Unregister(button)
end

function PossessBar:Update()
    local button = self.buttons[1]
    local texture = (GetPossessInfo(button:GetID()))
    local icon = button.icon

    if (UnitControllingVehicle("player") and CanExitVehicle()) or not texture then
        icon:SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]])
        icon:SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
    else
        icon:SetTexture(texture)
        icon:SetTexCoord(0, 1, 0, 1)
    end

    icon:SetVertexColor(1, 1, 1)
    icon:SetDesaturated(false)

    -- hide the border texture
    button.NormalTexture:SetTexture()

    button:SetChecked(false)
    button:Enable()
end

-- export
Addon.PossessBar = PossessBar

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

local PossessBarModule = Addon:NewModule('PossessBar', 'AceEvent-3.0')

function PossessBarModule:Load()
    self.bar = PossessBar:New()

    self:RegisterEvent("UNIT_ENTERED_VEHICLE", "Update")
    self:RegisterEvent("UNIT_EXITED_VEHICLE", "Update")
    self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "Update")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
    self:RegisterEvent("VEHICLE_UPDATE", "Update")
    self:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR", "Update")
    self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "Update")
    self:RegisterEvent("UPDATE_POSSESS_BAR", "Update")
    self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "Update")
end

function PossessBarModule:Unload()
    self:UnregisterAllEvents()

    if self.bar then
        self.bar:Free()
    end
end

function PossessBarModule:OnFirstLoad()
    self.Update = Addon:Defer(self.Update, 0.01, self)
end

function PossessBarModule:Update()
    if self.bar then
        self.bar:Update()
    end
end