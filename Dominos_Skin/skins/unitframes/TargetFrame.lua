if not _G.TargetFrame then return end

hooksecurefunc(TargetFrame, "CheckClassification", function(self)
	local classification = UnitClassification(self.unit)
	local bossPortraitFrameTexture = self.TargetFrameContainer.BossPortraitFrameTexture
	if (UnitIsBossMob(self.unit) or classification == "rareelite") then
		bossPortraitFrameTexture:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged", TextureKitConstants.UseAtlasSize)
		bossPortraitFrameTexture:SetPoint("TOPRIGHT", 8, -7)
	elseif (classification == "rare") then
		bossPortraitFrameTexture:SetAtlas("ui-hud-unitframe-target-portraiton-boss-rare-silver", TextureKitConstants.UseAtlasSize)
		bossPortraitFrameTexture:SetPoint("TOPRIGHT", -11, -8)
		bossPortraitFrameTexture:Show()
	end
	self.TargetFrameContent.TargetFrameContentContextual.BossIcon:Hide()
end)