if not _G.MinimapCluster then return end

hooksecurefunc(AddonCompartmentFrame, "UpdateDisplay", function(self)
	self:SetShown(false)
end)