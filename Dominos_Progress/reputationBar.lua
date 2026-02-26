local _, Addon = ...
local Dominos = _G.Dominos
local ReputationBar = Dominos:CreateClass("Frame", Addon.ProgressBar)

function ReputationBar:Init()
    self:Update()
end

function ReputationBar:Update()
    local watchedFactionData = C_Reputation.GetWatchedFactionData()
    if not watchedFactionData or watchedFactionData.factionID == 0 then
        return
    end

    local factionID = watchedFactionData.factionID
    local isShowingNewFaction = self.factionID ~= factionID
    if isShowingNewFaction then
        self.factionID = factionID
        local reputationInfo = C_GossipInfo.GetFriendshipReputation(factionID)
        self.friendshipID = reputationInfo.friendshipFactionID
    end

    -- do something different for friendships
    local level
    local maxLevel = MAX_REPUTATION_REACTION

    local minBar, maxBar, value = watchedFactionData.currentReactionThreshold, watchedFactionData.nextReactionThreshold, watchedFactionData.currentStanding
    if C_Reputation.IsFactionParagonForCurrentPlayer(factionID) then
        local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
        minBar, maxBar  = 0, threshold
        if currentValue and threshold then
            value = currentValue % threshold
        end
        level = maxLevel
        if hasRewardPending then
            value = value + threshold
        end
    elseif C_Reputation.IsMajorFaction(factionID) then
        local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID)
        minBar, maxBar = 0, majorFactionData.renownLevelThreshold
        level = majorFactionData.renownLevel
    elseif self.friendshipID > 0 then
        local repInfo = C_GossipInfo.GetFriendshipReputation(factionID)
        local repRankInfo = C_GossipInfo.GetFriendshipReputationRanks(factionID)
        level = repRankInfo.currentLevel
        if repInfo.nextThreshold then
            minBar, maxBar, value = repInfo.reactionThreshold, repInfo.nextThreshold, repInfo.standing
        else
            -- max rank, make it look like a full bar
            minBar, maxBar, value = 0, 1, 1
        end
    else
        level = watchedFactionData.reaction
    end

    local isCapped = (level and maxLevel) and level >= maxLevel

    -- Normalize values
    maxBar = maxBar - minBar
    value = value - minBar
    if isCapped and maxBar == 0 then
        maxBar = 1
        value = 1
    end
    minBar = 0

    self:SetValues(value, maxBar)

    local name = watchedFactionData.name
    local needsAccountWideLabel = C_Reputation.IsAccountWideReputation(factionID)
    if needsAccountWideLabel then
        name = name .. " " .. REPUTATION_STATUS_BAR_LABEL_ACCOUNT_WIDE
    end

    if isCapped then
        self:SetText(name)
    else
        name = name.." %d / %d"
        self:SetText(name:format(value, maxBar))
    end

    local color = FACTION_BAR_COLORS[watchedFactionData.reaction]
    if C_Reputation.IsMajorFaction(factionID) then
        self:SetColor(BLUE_FONT_COLOR.r, BLUE_FONT_COLOR.g, BLUE_FONT_COLOR.b)
    else
        self:SetColor(color.r, color.g, color.b)
    end
end

function ReputationBar:IsModeActive()
    return C_Reputation.GetWatchedFactionData() ~= nil
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes["reputation"] = ReputationBar
Addon.ReputationBar = ReputationBar