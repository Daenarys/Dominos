if not _G.Minimap then return end

Minimap:HookScript("OnEvent", function(self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if (ExpansionLandingPageMinimapButton:GetNormalTexture():GetAtlas() == "dragonflight-landingbutton-up") then
			ExpansionLandingPageMinimapButton:ClearAllPoints()
			ExpansionLandingPageMinimapButton:SetPoint("TOPLEFT", 8, -156)
		end

		hooksecurefunc(ExpansionLandingPageMinimapButton, "UpdateIcon", function(self)
			if (self:GetNormalTexture():GetAtlas() == "dragonflight-landingbutton-up") then
				self:ClearAllPoints()
				self:SetPoint("TOPLEFT", 8, -156)
			end
		end)
	end
end)