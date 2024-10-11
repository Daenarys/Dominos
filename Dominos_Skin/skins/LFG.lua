if not _G.PVEFrame then return end

ScenarioQueueFrameRandomScrollFrame.ScrollBar:SetAlpha(0)

hooksecurefunc('LFGDungeonReadyPopup_Update', function()
	local proposalExists, id, typeID, subtypeID, name, backgroundTexture, role, hasResponded, totalEncounters, completedEncounters, numMembers, isLeader, _, _, isSilent = GetLFGProposal()
	
	if ( subtypeID == LFG_SUBTYPEID_SCENARIO ) then
		LFGDungeonReadyDialog.background:SetDrawLayer("BACKGROUND")
		if ( LFG_IsHeroicScenario(id) ) then
			LFGDungeonReadyDialog.background:SetTexture("Interface\\LFGFrame\\UI-LFG-BACKGROUND-HeroicScenario")
		else
			LFGDungeonReadyDialog.background:SetTexture("Interface\\LFGFrame\\UI-LFG-BACKGROUND-RandomScenario")
		end
	end
end)

hooksecurefunc("ScenarioQueueFrameRandom_UpdateFrame", function()
	local dungeonID = ScenarioQueueFrame.type

	if ( LFG_IsHeroicScenario(dungeonID) ) then
		ScenarioQueueFrame.Bg:SetTexture("Interface\\LFGFrame\\UI-LFG-SCENARIO-Heroic-Old")
	else
		ScenarioQueueFrame.Bg:SetTexture("Interface\\LFGFrame\\UI-LFG-SCENARIO-Random-Old")
	end
end)

hooksecurefunc("ScenarioQueueFrame_SetTypeRandom", function()
	local queueFrame = ScenarioQueueFrame

	queueFrame.Bg:SetSize(512, 512)
	queueFrame.Bg:ClearAllPoints()
	queueFrame.Bg:SetPoint("TOPLEFT", 4, -75)
end)

hooksecurefunc("GroupFinderFrame_EvaluateButtonVisibility", function(self)
	if not PlayerGetTimerunningSeasonID() then
		self.groupButton1:SetPoint("TOPLEFT", 10, -101)
		self.groupButton2:SetPoint("TOP", self.groupButton1, "BOTTOM", 0, -30)
		self.groupButton3:SetPoint("TOP", self.groupButton2, "BOTTOM", 0, -30)
	end
end)

hooksecurefunc('LFGListGroupDataDisplayEnumerate_Update', function(self, numPlayers, displayData, disabled, iconOrder)
	local LFG_LIST_GROUP_DATA_ATLASES = {
		["TANK"] = "UI-LFG-RoleIcon-Tank-Micro-GroupFinder",
		["HEALER"] = "UI-LFG-RoleIcon-Healer-Micro-GroupFinder",
		["DAMAGER"] = "UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
	}

	--Note that icons are numbered from right to left
	if iconOrder == LFG_LIST_GROUP_DATA_ROLE_ORDER then
		local iconIndex = numPlayers
		for i=1, #iconOrder do
			local role = iconOrder[i]
			for j=1, displayData[iconOrder[i]] do
				local icon = self.Icons[iconIndex]
				icon:SetAlpha(disabled and 0.5 or 0.70)
				icon.RoleIconWithBackground:Hide()
				icon.RoleIcon:Show()
				icon.RoleIcon:SetSize(18, 18)
				icon.RoleIcon:SetAtlas(LFG_LIST_GROUP_DATA_ATLASES[role], false)
				icon.ClassCircle:Hide()
				iconIndex = iconIndex - 1
				if ( iconIndex < 1 ) then
					return
				end
			end
		end
	end
end)