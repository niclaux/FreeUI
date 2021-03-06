local F, C = unpack(select(2, ...))

tinsert(C.themes["FreeUI"], function()
	for i = 1, 4 do
		F.ReskinTab(_G["FriendsFrameTab"..i])
	end
	FriendsFrameIcon:Hide()
	F.StripTextures(IgnoreListFrame)

	for i = 1, FRIENDS_TO_DISPLAY do
		local bu = _G["FriendsListFrameScrollFrameButton"..i]
		local ic = bu.gameIcon

		bu.background:Hide()
		bu:SetHighlightTexture(C.media.bdTex)
		bu:GetHighlightTexture():SetVertexColor(.24, .56, 1, .2)
		ic:SetSize(22, 22)
		ic:SetTexCoord(.17, .83, .17, .83)

		bu.bg = CreateFrame("Frame", nil, bu)
		bu.bg:SetAllPoints(ic)
		F.CreateBDFrame(bu.bg, 0)

		local travelPass = bu.travelPassButton
		travelPass:SetSize(22, 22)
		travelPass:SetPushedTexture(nil)
		travelPass:SetDisabledTexture(nil)
		travelPass:SetPoint("TOPRIGHT", -3, -6)
		F.CreateBDFrame(travelPass, 1)
		local nt = travelPass:GetNormalTexture()
		nt:SetTexture("Interface\\FriendsFrame\\PlusManz-PlusManz")
		nt:SetTexCoord(.1, .9, .1, .9)
		local hl = travelPass:GetHighlightTexture()
		hl:SetColorTexture(1, 1, 1, .25)
		hl:SetAllPoints()
	end

	local function UpdateScroll()
		for i = 1, FRIENDS_TO_DISPLAY do
			local bu = _G["FriendsListFrameScrollFrameButton"..i]
			if bu.gameIcon:IsShown() then
				bu.bg:Show()
				bu.gameIcon:SetPoint("TOPRIGHT", bu.travelPassButton, "TOPLEFT", -4, 0)
			else
				bu.bg:Hide()
			end
		end
	end
	hooksecurefunc("FriendsFrame_UpdateFriends", UpdateScroll)
	hooksecurefunc(FriendsListFrameScrollFrame, "update", UpdateScroll)

	local header = FriendsListFrameScrollFrame.PendingInvitesHeaderButton
	for i = 1, 11 do
		select(i, header:GetRegions()):Hide()
	end
	local headerBg = F.CreateBDFrame(header, .25)
	headerBg:SetPoint("TOPLEFT", 2, -2)
	headerBg:SetPoint("BOTTOMRIGHT", -2, 2)

	local function reskinInvites(self)
		for invite in self:EnumerateActive() do
			if not invite.styled then
				F.Reskin(invite.AcceptButton)
				F.Reskin(invite.DeclineButton)

				invite.styled = true
			end
		end
	end

	hooksecurefunc(FriendsListFrameScrollFrame.invitePool, "Acquire", reskinInvites)

	local INVITE_RESTRICTION_NONE = 9
	hooksecurefunc("FriendsFrame_UpdateFriendButton", function(button)
		if button.buttonType == FRIENDS_BUTTON_TYPE_INVITE then
			reskinInvites(FriendsListFrameScrollFrame.invitePool)
		elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
			local nt = button.travelPassButton:GetNormalTexture()
			if FriendsFrame_GetInviteRestriction(button.id) == INVITE_RESTRICTION_NONE then
				nt:SetVertexColor(1, 1, 1)
			else
				nt:SetVertexColor(.3, .3, .3)
			end
		end
	end)

	FriendsFrameStatusDropDown:ClearAllPoints()
	FriendsFrameStatusDropDown:SetPoint("TOPLEFT", FriendsFrame, "TOPLEFT", 10, -28)

	for _, button in pairs({FriendsTabHeaderSoRButton, FriendsTabHeaderRecruitAFriendButton}) do
		button:SetPushedTexture("")
		button:GetRegions():SetTexCoord(.08, .92, .08, .92)
		F.CreateBDFrame(button)
	end

	F.CreateBD(FriendsFrameBattlenetFrame.UnavailableInfoFrame)
	FriendsFrameBattlenetFrame.UnavailableInfoFrame:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT", 1, -18)

	FriendsFrameBattlenetFrame:GetRegions():Hide()
	F.CreateBD(FriendsFrameBattlenetFrame, .25)

	FriendsFrameBattlenetFrame.Tag:SetParent(FriendsListFrame)
	FriendsFrameBattlenetFrame.Tag:SetPoint("TOP", FriendsFrame, "TOP", 0, -8)

	hooksecurefunc("FriendsFrame_CheckBattlenetStatus", function()
		if BNFeaturesEnabled() then
			local frame = FriendsFrameBattlenetFrame
			frame.BroadcastButton:Hide()

			if BNConnected() then
				frame:Hide()
			end
		end
	end)

	hooksecurefunc("FriendsFrame_Update", function()
		if FriendsFrame.selectedTab == 1 and FriendsTabHeader.selectedTab == 1 and FriendsFrameBattlenetFrame.Tag:IsShown() then
			FriendsFrameTitleText:Hide()
		else
			FriendsFrameTitleText:Show()
		end
	end)

	local whoBg = F.CreateBDFrame(WhoFrameEditBox, .25)
	whoBg:SetPoint("TOPLEFT", WhoFrameEditBoxInset)
	whoBg:SetPoint("BOTTOMRIGHT", WhoFrameEditBoxInset, -1, 1)
	F.CreateGradient(whoBg)

	F.ReskinPortraitFrame(FriendsFrame)
	F.Reskin(FriendsFrameAddFriendButton)
	F.Reskin(FriendsFrameSendMessageButton)
	F.Reskin(FriendsFrameIgnorePlayerButton)
	F.Reskin(FriendsFrameUnsquelchButton)
	F.ReskinScroll(FriendsListFrameScrollFrame.scrollBar)
	F.ReskinScroll(IgnoreListFrameScrollFrame.scrollBar)
	F.ReskinScroll(WhoListScrollFrame.scrollBar)
	F.ReskinDropDown(FriendsFrameStatusDropDown)
	F.ReskinDropDown(WhoFrameDropDown)
	F.ReskinDropDown(FriendsFriendsFrameDropDown)
	F.Reskin(FriendsListFrameContinueButton)
	F.ReskinInput(AddFriendNameEditBox)
	F.StripTextures(AddFriendFrame)
	F.CreateBD(AddFriendFrame)
	F.CreateSD(AddFriendFrame)
	F.CreateBD(FriendsFriendsFrame)
	F.CreateSD(FriendsFriendsFrame)
	F.Reskin(WhoFrameWhoButton)
	F.Reskin(WhoFrameAddFriendButton)
	F.Reskin(WhoFrameGroupInviteButton)
	F.Reskin(AddFriendEntryFrameAcceptButton)
	F.Reskin(AddFriendEntryFrameCancelButton)
	F.Reskin(AddFriendInfoFrameContinueButton)

	for i = 1, 4 do
		F.StripTextures(_G["WhoFrameColumnHeader"..i])
	end

	WhoFrameListInset:Hide()
	WhoFrameEditBoxInset:Hide()

	for i = 1, 3 do
		F.StripTextures(_G["FriendsTabHeaderTab"..i])
	end

	WhoFrameWhoButton:SetPoint("RIGHT", WhoFrameAddFriendButton, "LEFT", -1, 0)
	WhoFrameAddFriendButton:SetPoint("RIGHT", WhoFrameGroupInviteButton, "LEFT", -1, 0)
	FriendsFrameTitleText:SetPoint("TOP", FriendsFrame, "TOP", 0, -8)
end)