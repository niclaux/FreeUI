local F, C, L = unpack(select(2, ...))
local INFOBAR = F:GetModule('Infobar')


local strfind, format, sort, wipe, unpack, tinsert = string.find, string.format, table.sort, table.wipe, unpack, table.insert
local C_Timer_After = C_Timer.After
local C_FriendList_GetNumFriends = C_FriendList.GetNumFriends
local C_FriendList_GetNumOnlineFriends = C_FriendList.GetNumOnlineFriends
local C_FriendList_GetFriendInfoByIndex = C_FriendList.GetFriendInfoByIndex
local BNet_GetClientEmbeddedTexture, BNet_GetValidatedCharacterName, BNet_GetClientTexture = BNet_GetClientEmbeddedTexture, BNet_GetValidatedCharacterName, BNet_GetClientTexture
local CanCooperateWithGameAccount, GetRealZoneText, GetQuestDifficultyColor = CanCooperateWithGameAccount, GetRealZoneText, GetQuestDifficultyColor
local BNGetNumFriends = BNGetNumFriends
local BNET_CLIENT_WOW, UNKNOWN, GUILD_ONLINE_LABEL = BNET_CLIENT_WOW, UNKNOWN, GUILD_ONLINE_LABEL
local FRIENDS_TEXTURE_ONLINE, FRIENDS_TEXTURE_AFK, FRIENDS_TEXTURE_DND = FRIENDS_TEXTURE_ONLINE, FRIENDS_TEXTURE_AFK, FRIENDS_TEXTURE_DND
local WOW_PROJECT_ID = WOW_PROJECT_ID or 1
local CLIENT_WOW_CLASSIC = "WoV" -- for sorting

local friendTable, bnetTable, updateRequest = {}, {}
local wowString, bnetString = L['INFOBAR_WOW'], L['INFOBAR_BN']
local activeZone, inactiveZone = {r=.3, g=1, b=.3}, {r=.7, g=.7, b=.7}
local AFKTex = '|T'..FRIENDS_TEXTURE_AFK..':14:14:0:0:16:16:1:15:1:15|t'
local DNDTex = '|T'..FRIENDS_TEXTURE_DND..':14:14:0:0:16:16:1:15:1:15|t'

local FreeUIFriendsButton = INFOBAR.FreeUIFriendsButton

local function CanCooperateWithUnit(gameAccountInfo)
	return gameAccountInfo.playerGuid and (gameAccountInfo.factionName == C.Faction) and (gameAccountInfo.realmID ~= 0)
end

local function GetOnlineInfoText(client, isMobile, rafLinkType, locationText)
	if not locationText or locationText == "" then
		return UNKNOWN
	end
	if isMobile then
		return LOCATION_MOBILE_APP
	end
	if (client == BNET_CLIENT_WOW) and (rafLinkType ~= Enum.RafLinkType.None) and not isMobile then
		if rafLinkType == Enum.RafLinkType.Recruit then
			return RAF_RECRUIT_FRIEND:format(locationText)
		else
			return RAF_RECRUITER_FRIEND:format(locationText)
		end
	end

	return locationText
end

local function buildFriendTable(num)
	wipe(friendTable)

	for i = 1, num do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and info.connected then
			local status = ''
			if info.afk then
				status = AFKTex
			elseif info.dnd then
				status = DNDTex
			end
			local class = C.ClassList[info.className]
			friendTable[i] = {info.name, info.level, class, info.area, info.connected, status}
		end
	end

	sort(friendTable, function(a, b)
		if a[1] and b[1] then
			return a[1] < b[1]
		end
	end)
end

local function buildBNetTable(num)
	wipe(bnetTable)

	for i = 1, num do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo then
			local accountName = accountInfo.accountName
			local battleTag = accountInfo.battleTag
			local isAFK = accountInfo.isAFK
			local isDND = accountInfo.isDND
			local note = accountInfo.note
			local broadcastText = accountInfo.customMessage
			local broadcastTime = accountInfo.customMessageTime
			local rafLinkType = accountInfo.rafLinkType

			local gameAccountInfo = accountInfo.gameAccountInfo
			local isOnline = gameAccountInfo.isOnline
			local gameID = gameAccountInfo.gameAccountID

			if isOnline and gameID then
				local charName = gameAccountInfo.characterName
				local client = gameAccountInfo.clientProgram
				local class = gameAccountInfo.className or UNKNOWN
				local zoneName = gameAccountInfo.areaName or UNKNOWN
				local level = gameAccountInfo.characterLevel
				local gameText = gameAccountInfo.richPresence or ""
				local isGameAFK = gameAccountInfo.isGameAFK
				local isGameBusy = gameAccountInfo.isGameBusy
				local wowProjectID = gameAccountInfo.wowProjectID
				local isMobile = gameAccountInfo.isWowMobile
				local canCooperate = CanCooperateWithUnit(gameAccountInfo)

				charName = BNet_GetValidatedCharacterName(charName, battleTag, client)
				class = C.ClassList[class]

				local status = FRIENDS_TEXTURE_ONLINE
				if isAFK or isGameAFK then
					status = FRIENDS_TEXTURE_AFK
				elseif isDND or isGameBusy then
					status = FRIENDS_TEXTURE_DND
				end

				local infoText = GetOnlineInfoText(client, isMobile, rafLinkType, gameText)
				if client == BNET_CLIENT_WOW and wowProjectID == WOW_PROJECT_ID then
					infoText = GetOnlineInfoText(client, isMobile, rafLinkType, zoneName)
				end

				if client == BNET_CLIENT_WOW and wowProjectID ~= WOW_PROJECT_ID then client = CLIENT_WOW_CLASSIC end

				tinsert(bnetTable, {i, accountName, charName, canCooperate, client, status, class, level, infoText, note, broadcastText, broadcastTime})
			end
		end
	end

	sort(bnetTable, sortBNFriends)
end


function INFOBAR:Friends()
	if not C.infobar.enable then return end
	if not C.infobar.friends then return end

	FreeUIFriendsButton = INFOBAR:addButton('', INFOBAR.POSITION_RIGHT, 120, function(self, button)
		if InCombatLockdown() then UIErrorsFrame:AddMessage(C.InfoColor..ERR_NOT_IN_COMBAT) return end
		
		if button == 'LeftButton' then
			ToggleFriendsFrame()
		elseif button == 'RightButton' then
			StaticPopupSpecial_Show(AddFriendFrame)
			AddFriendFrame_ShowEntry()
		end
	end)

	FreeUIFriendsButton:RegisterEvent('BN_FRIEND_ACCOUNT_ONLINE')
	FreeUIFriendsButton:RegisterEvent('BN_FRIEND_ACCOUNT_OFFLINE')
	FreeUIFriendsButton:RegisterEvent('BN_FRIEND_INFO_CHANGED')
	FreeUIFriendsButton:RegisterEvent('FRIENDLIST_UPDATE')
	FreeUIFriendsButton:RegisterEvent('PLAYER_ENTERING_WORLD')
	FreeUIFriendsButton:RegisterEvent('CHAT_MSG_SYSTEM')
	FreeUIFriendsButton:SetScript('OnEvent', function(self, event, arg1)
		if event == 'CHAT_MSG_SYSTEM' then
			if not string.find(arg1, ERR_FRIEND_ONLINE_SS) and not string.find(arg1, ERR_FRIEND_OFFLINE_S) then return end
		elseif event == 'MODIFIER_STATE_CHANGED' and arg1 == 'LSHIFT' then
			self:GetScript('OnEnter')(self)
		end

		local onlineFriends = C_FriendList.GetNumOnlineFriends()
		local _, onlineBNet = BNGetNumFriends()
		self.Text:SetText(format('%s: '..C.InfoColor..'%d', 'Friends', onlineFriends + onlineBNet))
		updateRequest = false
	end)

	--[[FreeUIFriendsButton:HookScript('OnEnter', function(self)
		local numFriends, onlineFriends = C_FriendList.GetNumFriends(), C_FriendList.GetNumOnlineFriends()
		local numBNet, onlineBNet = BNGetNumFriends()
		local totalOnline = onlineFriends + onlineBNet
		local totalFriends = numFriends + numBNet

		if not updateRequest then
			if numFriends > 0 then buildFriendTable(numFriends) end
			if numBNet > 0 then buildBNetTable(numBNet) end
			updateRequest = true
		end

		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM', 0, -15)
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(FRIENDS_LIST, format('%s: %s/%s', GUILD_ONLINE_LABEL, totalOnline, totalFriends), .9, .8, .6, 1, 1, 1)

		if totalOnline == 0 then
			GameTooltip:AddLine(' ')
			GameTooltip:AddLine(L['INFOBAR_NO_ONLINE'], 1,1,1)
		else
			if onlineFriends > 0 then
				GameTooltip:AddLine(' ')
				GameTooltip:AddLine(wowString, 0,.6,1)
				for i = 1, #friendTable do
					local name, level, class, area, connected, status = unpack(friendTable[i])
					if connected then
						local zoneColor = GetRealZoneText() == area and activeZone or inactiveZone
						local levelColor = F.HexRGB(GetQuestDifficultyColor(level))
						local classColor = C.ClassColors[class] or levelColor
						GameTooltip:AddDoubleLine(levelColor..level..'|r '..name..status, area, classColor.r, classColor.g, classColor.b, zoneColor.r, zoneColor.g, zoneColor.b)
					end
				end
			end

			if onlineBNet > 0 then
				GameTooltip:AddLine(' ')
				GameTooltip:AddLine(bnetString, 0,.6,1)
				for i = 1, #bnetTable do
					local _, accountName, charName, gameID, client, isOnline, status, realmName, class, infoText = unpack(bnetTable[i])

					if isOnline then
						local zoneColor, realmColor = inactiveZone, inactiveZone
						local name = FRIENDS_OTHER_NAME_COLOR_CODE..' ('..charName..')'

						if client == BNET_CLIENT_WOW then
							if CanCooperateWithGameAccount(gameID) then
								local color = C.ClassColors[class] or GetQuestDifficultyColor(1)
								name = F.HexRGB(color)..' '..charName
							end
							zoneColor = GetRealZoneText() == infoText and activeZone or inactiveZone
							realmColor = C.Realm == realmName and activeZone or inactiveZone
						end

						local cicon = BNet_GetClientEmbeddedTexture(client, 14, 14, 0, -1)
						GameTooltip:AddDoubleLine(cicon..name..status, accountName, 1,1,1, .6,.8,1)
						if IsShiftKeyDown() then
							GameTooltip:AddDoubleLine(infoText, realmName, zoneColor.r, zoneColor.g, zoneColor.b, realmColor.r, realmColor.g, realmColor.b)
						end
					end
				end
			end
		end
		GameTooltip:AddDoubleLine(' ', C.LineString)
		GameTooltip:AddDoubleLine(' ', L['INFOBAR_HOLD_SHIFT'], 1,1,1, .6,.8,1)
		GameTooltip:AddDoubleLine(' ', C.LeftButton..L['INFOBAR_OPEN_FRIENDS_PANEL'], 1,1,1, .9, .8, .6)
		GameTooltip:AddDoubleLine(' ', C.RightButton..L['INFOBAR_ADD_FRIEND'], 1,1,1, .9, .8, .6)
		GameTooltip:Show()

		self:RegisterEvent('MODIFIER_STATE_CHANGED')
	end)

	FreeUIFriendsButton:HookScript('OnLeave', function(self)
		GameTooltip:Hide()
		self:UnregisterEvent('MODIFIER_STATE_CHANGED')
	end)--]]
end



