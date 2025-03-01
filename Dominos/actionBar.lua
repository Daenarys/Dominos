--------------------------------------------------------------------------------
-- Action Bar
-- A pool of action bars
--------------------------------------------------------------------------------
local AddonName, Addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local ACTION_BUTTON_COUNT = 120

local ActionBar = Addon:CreateClass('Frame', Addon.ButtonBar)

ActionBar.class = UnitClassBase('player')

-- Metatable magic.  Basically this says, 'create a new table for this index'
-- I do this so that I only create page tables for classes the user is actually
-- playing
ActionBar.defaultOffsets = {
    __index = function(t, i)
        t[i] = {}
        return t[i]
    end
}

-- Metatable magic.  Basically this says, 'create a new table for this index,
-- with these defaults. I do this so that I only create page tables for classes
-- the user is actually playing
ActionBar.mainbarOffsets = {
    __index = function(t, i)
        local pages = {
            page2 = 1,
            page3 = 2,
            page4 = 3,
            page5 = 4,
            page6 = 5
        }

        if i == 'DRUID' then
            pages.cat = 6
            pages.bear = 8
            pages.moonkin = 9
            pages.tree = 7
        elseif i == 'EVOKER' then
            pages.soar = 7
        elseif i == 'ROGUE' then
            pages.stealth = 6
            pages.shadowdance = 6
        end

        t[i] = pages
        return pages
    end
}

ActionBar:Extend('OnLoadSettings', function(self)
    if self.id == 1 then
        setmetatable(self.sets.pages, self.mainbarOffsets)
    else
        setmetatable(self.sets.pages, self.defaultOffsets)
    end

    self.pages = self.sets.pages[self.class]
end)

ActionBar:Extend('OnAcquire', function(self)
    self:SetAttribute("checkselfcast", true)
    self:SetAttribute("checkfocuscast", true)
    self:SetAttribute("checkmouseovercast", true)

    self:LoadStateController()
    self:UpdateStateDriver()
    self:SetUnit(self:GetUnit())
    self:SetRightClickUnit(self:GetRightClickUnit())
    self:UpdateGrid()
    self:UpdateTransparent(true)
    self:UpdateFlyoutDirection()
end)

-- TODO: change the position code to be based more on the number of action bars
function ActionBar:GetDefaults()
    return {
        point = 'BOTTOM',
        x = 0,
        y = 40 * (self.id - 1),
        pages = {},
        spacing = 4,
        padW = 2,
        padH = 2,
        numButtons = self:MaxLength(),
        unit = "none",
        rightClickUnit = "none"
    }
end

function ActionBar:GetDisplayName()
    return L.ActionBarDisplayName:format(self.id)
end

-- returns the maximum possible size for a given bar
function ActionBar:MaxLength()
    return floor(ACTION_BUTTON_COUNT / Addon:NumBars())
end

function ActionBar:AcquireButton(index)
    local id = index + (self.id - 1) * self:MaxLength()
    local button = Addon.ActionButton:GetOrCreateActionButton(id, self)

    button:SetAttributeNoHandler('index', index)

    return button
end

function ActionBar:ReleaseButton(button)
    button:SetAlpha(0)
end

function ActionBar:OnAttachButton(button)
    button:SetAttribute("action", button:GetAttribute("index") + (self:GetAttribute("actionOffset") or 0))

    button:SetFlyoutDirection(self:GetFlyoutDirection())
    button:SetShowMacroText(Addon:ShowMacroText())

    if button:HasAction() then
        button:SetAlpha(1)
    end

    Addon:GetModule('Tooltips'):Register(button)
end

function ActionBar:OnDetachButton(button)
    Addon:GetModule('Tooltips'):Unregister(button)
end

-- paging
function ActionBar:SetOffset(stateId, page)
    self.pages[stateId] = page
    self:UpdateStateDriver()
end

function ActionBar:GetOffset(stateId)
    return self.pages[stateId]
end

function ActionBar:UpdateStateDriver()
    local conditions

    for _, state in Addon.BarStates:getAll() do
        local offset = self:GetOffset(state.id)

        if offset then
            local condition

            if type(state.value) == 'function' then
                condition = state.value()
            else
                condition = state.value
            end

            if condition then
                local page = Wrap(self.id + offset, Addon:NumBars())

                if conditions then
                    conditions = strjoin(';', conditions, (condition .. page))
                else
                    conditions = (condition .. page)
                end
            end
        end
    end

    if conditions then
        RegisterStateDriver(self, 'page', strjoin(';', conditions, self.id))
    else
        UnregisterStateDriver(self, 'page')
        self:SetAttribute('state-page', self.id)
    end
end

function ActionBar:LoadStateController()
    self:SetAttribute('barLength', self:MaxLength())
    self:SetAttribute('overrideBarLength', NUM_ACTIONBAR_BUTTONS)

    self:SetAttribute('_onstate-overridebar', [[ self:RunAttribute('UpdateOffset') ]])
    self:SetAttribute('_onstate-overridepage', [[ self:RunAttribute('UpdateOffset') ]])
    self:SetAttribute('_onstate-page', [[ self:RunAttribute('UpdateOffset') ]])

    self:SetAttribute('UpdateOffset', [[
        local offset = 0

        local overridePage = self:GetAttribute('state-overridepage') or 0
        if overridePage > 10 and self:GetAttribute('state-overridebar') then
            offset = (overridePage - 1) * self:GetAttribute('overrideBarLength')
        else
            local page = self:GetAttribute('state-page') or 1
            offset = (page - 1) * self:GetAttribute('barLength')
        end

        self:SetAttribute('actionOffset', offset)
        control:ChildUpdate('offset', offset)
    ]])

    self:UpdateOverrideBar()
end

function ActionBar:UpdateOverrideBar()
    self:SetAttribute('state-overridebar', self:IsOverrideBar())
end

function ActionBar:IsOverrideBar()
    -- TODO: make overrideBar a property of the bar itself instead of a global
    -- setting
    return Addon.db.profile.possessBar == self.id
end

--Empty button display
function ActionBar:ShowGrid()
    for _,b in pairs(self.buttons) do
        if b:IsShown() then
            b:SetAlpha(1.0)
        end
    end
end

function ActionBar:HideGrid()
    for _,b in pairs(self.buttons) do
        if b:IsShown() and not b:HasAction() and not Addon:ShowGrid() then
            b:SetAlpha(0.0)
        end
    end
end

function ActionBar:UpdateGrid()
    if Addon:ShowGrid() then
        self:ShowGrid()
    else
        self:HideGrid()
    end
end

function ActionBar:UpdateSlot()
    for _,b in pairs(self.buttons) do
        if b:IsShown() and b:HasAction() then
            b:SetAlpha(1.0)
        end
    end
end

-- keybound support
function ActionBar:KEYBOUND_ENABLED()
    self:ShowGrid()
end

function ActionBar:KEYBOUND_DISABLED()
    self:HideGrid()
end

-- right click targeting support
function ActionBar:SetUnit(unit)
    unit = unit or 'none'

    if unit == 'none' then
        self:SetAttribute('*unit*', nil)
    else
        self:SetAttribute('*unit*', unit)
    end

    self.sets.unit = unit
end

function ActionBar:GetUnit()
    return self.sets.unit or 'none'
end

function ActionBar:SetRightClickUnit(unit)
    unit = unit or 'none'

    if unit == 'none' then
        self:SetAttribute('*unit2', nil)
    else
        self:SetAttribute('*unit2', unit)
    end

    self.sets.rightClickUnit = unit
end

function ActionBar:GetRightClickUnit()
    local unit = self.sets.rightClickUnit

    if unit ~= "none" then
        return unit
    end

    return Addon:GetRightClickUnit() or "none"
end

function ActionBar:OnSetAlpha(_alpha)
    self:UpdateTransparent()
end

function ActionBar:UpdateTransparent(force)
    local isTransparent = self:GetAlpha() == 0

    if self.__transparent ~= isTransparent or force then
        self.__transparent = isTransparent

        self:ForButtons('SetShowCooldowns', not isTransparent)
    end
end

-- flyout direction calculations
function ActionBar:GetFlyoutDirection()
    local direction = self.sets.flyoutDirection or 'auto'

    if direction == 'auto' then
        return self:GetCalculatedFlyoutDirection()
    end

    return direction
end

function ActionBar:GetCalculatedFlyoutDirection()
    local width, height = self:GetSize()
    local _, relPoint = self:GetRelativePosition()

    if width < height then
        if relPoint:match('RIGHT') then
            return 'LEFT'
        end

        return 'RIGHT'
    end

    if relPoint and relPoint:match('TOP') then
        return 'DOWN'
    end
    return 'UP'
end

function ActionBar:SetFlyoutDirection(direction)
    local oldDirection = self.sets.flyoutDirection or 'auto'
    local newDirection = direction or 'auto'

    if oldDirection ~= newDirection then
        self.sets.flyoutDirection = newDirection
        self:UpdateFlyoutDirection()
    end
end

function ActionBar:UpdateFlyoutDirection()
    self:ForButtons('SetFlyoutDirection', self:GetFlyoutDirection())
end

ActionBar:Extend("Layout", ActionBar.UpdateFlyoutDirection)
ActionBar:Extend("Stick", ActionBar.UpdateFlyoutDirection)


function ActionBar:OnCreateMenu(menu)
    local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local dropdownItems = {}
    local lastNumBars = -1

    local function getDropdownItems()
        local numBars = Addon:NumBars()

        if lastNumBars ~= numBars then
            dropdownItems = {
                {value = -1, text = _G.DISABLE}
            }

            for i = 1, numBars do
                dropdownItems[i + 1] = {
                    value = i,
                    text = ('Action Bar %d'):format(i)
                }
            end

            lastNumBars = numBars
        end

        return dropdownItems
    end

    local function addStateGroup(panel, categoryName, stateType)
        local states =
            Addon.BarStates:map(
            function(s)
                return s.type == stateType
            end
        )

        if #states == 0 then
            return
        end

        panel:NewHeader(categoryName)

        for _, state in ipairs(states) do
            local id = state.id
            local name = state.text
            if type(name) == 'function' then
                name = name()
            elseif not name then
                name = L['State_' .. id:upper()]
            end

            panel:NewDropdown {
                name = name,
                items = getDropdownItems,
                get = function()
                    local offset = panel.owner:GetOffset(state.id) or -1
                    if offset > -1 then
                        return (panel.owner.id + offset - 1) % Addon:NumBars() + 1
                    end
                    return offset
                end,
                set = function(_, value)
                    local offset

                    if value == -1 then
                        offset = nil
                    elseif value < panel.owner.id then
                        offset = (Addon:NumBars() - panel.owner.id) + value
                    else
                        offset = value - panel.owner.id
                    end

                    panel.owner:SetOffset(state.id, offset)
                end
            }
        end
    end

    local function addLayoutPanel()
        local panel = menu:NewPanel(L.Layout)

        panel.sizeSlizer = panel:NewSlider {
            name = L.Size,
            min = 1,
            max = function()
                return panel.owner:MaxLength()
            end,
            get = function()
                return panel.owner:NumButtons()
            end,
            set = function(_, value)
                panel.owner:SetNumButtons(value)

                panel.colsSlider:UpdateRange()
                panel.colsSlider:UpdateValue()
            end
        }

        panel:AddLayoutOptions()

        return panel
    end

    local function addPagingPanel()
        local panel = menu:NewPanel(L.Paging)

        addStateGroup(panel, UnitClass('player'), 'class')
        addStateGroup(panel, L.QuickPaging, 'page')
        addStateGroup(panel, L.Modifiers, 'modifier')
        addStateGroup(panel, L.Targeting, 'target')

        return panel
    end

    -- add panels
    addLayoutPanel()
    addPagingPanel()
    menu:AddFadingPanel()
    menu:AddAdvancedPanel()
end

local ActionBarsModule = Addon:NewModule('ActionBars', 'AceEvent-3.0')

function ActionBarsModule:Load()
    self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
    self:RegisterEvent('UPDATE_BONUS_ACTIONBAR', 'OnOverrideBarUpdated')

    if _G.OverrideActionBar then
        self:RegisterEvent('UPDATE_VEHICLE_ACTIONBAR', 'OnOverrideBarUpdated')
        self:RegisterEvent('UPDATE_OVERRIDE_ACTIONBAR', 'OnOverrideBarUpdated')
    end

    self:RegisterEvent("ACTIONBAR_SHOWGRID")
    self:RegisterEvent("ACTIONBAR_HIDEGRID")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:RegisterEvent("SPELLS_CHANGED")

    self:SetBarCount(Addon:NumBars())
    Addon.RegisterCallback(self, "ACTIONBAR_COUNT_UPDATED")
end

function ActionBarsModule:Unload()
    self:UnregisterAllEvents()
    self:ForAll('Free')
    self.active = nil
end

-- events
function ActionBarsModule:OnOverrideBarUpdated()
    if InCombatLockdown() or not (Addon.OverrideController and Addon.OverrideController:OverrideBarActive()) then
        return
    end

    local bar = Addon:GetOverrideBar()
    if bar then
        bar:ForButtons('Update')
    end
end

function ActionBarsModule:ACTIONBAR_COUNT_UPDATED(event, count)
    self:SetBarCount(count)
end

function ActionBarsModule:ACTIONBAR_SHOWGRID()
    self:ForAll('ShowGrid')
end

function ActionBarsModule:ACTIONBAR_HIDEGRID()
    self:ForAll('HideGrid')
end

function ActionBarsModule:ACTIONBAR_SLOT_CHANGED()
    self:ForAll('UpdateSlot')
end

function ActionBarsModule:SPELLS_CHANGED()
    self:ForAll('UpdateGrid')
end

function ActionBarsModule:UPDATE_SHAPESHIFT_FORMS()
    if InCombatLockdown() then
        return
    end

    self:ForAll('UpdateStateDriver')
end

function ActionBarsModule:SetBarCount(count)
    self:ForAll('Free')

    if count > 0 then
        self.active = {}

        for i = 1, count do
            self.active[i] = Addon.ActionBar:New(i)
        end
    else
        self.active = nil
    end
end

function ActionBarsModule:ForAll(method, ...)
    if self.active then
        for _, bar in pairs(self.active) do
            bar:CallMethod(method, ...)
        end
    end
end

-- exports
Addon.ActionBar = ActionBar