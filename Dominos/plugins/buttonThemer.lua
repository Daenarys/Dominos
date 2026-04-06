local AddonName, Addon = ...
local ButtonThemer = Addon:NewModule('ButtonThemer')

local theme
-- modern theming
-- reserved for if I want to retheme buttons in Dragonflight
theme = function(button)
    if button.SlotArt and button.SlotArt:IsShown() then
        button.SlotArt:Hide()
        button.SlotBackground:Show()
    end
end

function ButtonThemer:Unload()
    self.shouldReskin = true
end

-- masque installed, use for theming
local Masque, MasqueVersion = LibStub('Masque', true)

if Masque then
    -- masque not installed
    function ButtonThemer:Register(button, groupName, ...)
        local group = Masque:Group(AddonName, groupName)

        group:AddButton(button, ...)

        if group.db.Disabled then
            theme(button)
        end
    end

    function ButtonThemer:Unregister(button, groupName)
        local group = Masque:Group(AddonName, groupName)

        group:RemoveButton(button)

        theme(button)
    end

    -- handle differences in the masque API
    if MasqueVersion < 80100 then
        -- in older verisons, fallback to the dominos theme when disabled
        Masque:Register(
            AddonName,
            function(...)
                local _, group, _, _, _, _, disabled = ...

                if disabled then
                    for button in pairs(Masque:Group(AddonName, group).Buttons) do
                        theme(button)
                    end
                end
            end
        )

        function ButtonThemer:Reskin()
            if not self.shouldReskin then
                return
            end

            self.shouldReskin = nil

            for _, groupName in pairs(Masque:Group(AddonName).SubList) do
                Masque:Group(AddonName, groupName):ReSkin()
            end
        end
    else
        function ButtonThemer:Reskin()
            if not self.shouldReskin then
                return
            end

            self.shouldReskin = nil

            for _, group in pairs(Masque:Group(AddonName).SubList) do
                group:ReSkin()
            end
        end
    end
else
    function ButtonThemer:Register(button)
        theme(button)
    end

    function ButtonThemer:Unregister(button)
    end

    function ButtonThemer:Reskin()
    end
end
