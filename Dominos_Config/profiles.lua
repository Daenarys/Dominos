local _, Addon = ...

local db = Addon:GetParent().db
local options = LibStub("AceDBOptions-3.0"):GetOptionsTable(db, true)

Addon:AddOptionsPanelOptions("profiles", options)
