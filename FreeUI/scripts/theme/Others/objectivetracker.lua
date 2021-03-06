local F, C, L = unpack(select(2, ...))
local APPEARANCE = F:GetModule('appearance')


local pairs = pairs

local ot = ObjectiveTrackerFrame
local BlocksFrame = ot.BlocksFrame
local minimize = ot.HeaderMenu.MinimizeButton
local LE_QUEST_FREQUENCY_DAILY = LE_QUEST_FREQUENCY_DAILY or 2

local otFontHeader = {C.font.header, 16, 'OUTLINE'}
local otFont = {C.font.normal, 12, 'OUTLINE'}


function APPEARANCE:QuestTracker()
	if not C.appearance.questTracker then return end
	
	-- Mover for quest tracker
	local frame = CreateFrame('Frame', 'FreeUIObjectiveTrackerMover', UIParent)
	frame:SetSize(240, 50)
	F.Mover(frame, L['MOVER_OBJECTIVE_TRACKER'], 'QuestTracker', {'TOPRIGHT', UIParent, 'TOPRIGHT', -50, -300})

	ot:ClearAllPoints()
	ot:SetPoint('TOPRIGHT', frame)
	ot:SetHeight(GetScreenHeight()*.6)
	ot:SetClampedToScreen(false)
	ot:SetMovable(true)
	if ot:IsMovable() then ot:SetUserPlaced(true) end


	-- Ctrl+Click to abandon a quest or Alt+Click to share a quest
	local function QuestHook(id)
		local questLogIndex = GetQuestLogIndexByID(id)
		if IsControlKeyDown() and CanAbandonQuest(id) then
			QuestMapQuestOptions_AbandonQuest(id)
		elseif IsAltKeyDown() and GetQuestLogPushable(questLogIndex) then
			QuestMapQuestOptions_ShareQuest(id)
		end
	end

	hooksecurefunc(QUEST_TRACKER_MODULE, 'OnBlockHeaderClick', function(_, block)
		QuestHook(block.id)
	end)
	
	hooksecurefunc('QuestMapLogTitleButton_OnClick', function(self)
		QuestHook(self.questID)
	end)


	-- Show quest color and level
	local function Showlevel(_, _, _, title, level, _, isHeader, _, isComplete, frequency, questID)
		if ENABLE_COLORBLIND_MODE == '1' then return end

		for button in pairs(QuestScrollFrame.titleFramePool.activeObjects) do
			if title and not isHeader and button.questID == questID then
				local title = '['..level..'] '..title
				if isComplete then
					title = '|cffff78ff'..title
				elseif frequency == LE_QUEST_FREQUENCY_DAILY then
					title = '|cff3399ff'..title
				end
				button.Text:SetText(title)
				button.Text:SetPoint('TOPLEFT', 24, -5)
				button.Text:SetWidth(205)
				button.Text:SetWordWrap(false)
				button.Check:SetPoint('LEFT', button.Text, button.Text:GetWrappedWidth(), 0)
			end
		end
	end
	hooksecurefunc('QuestLogQuests_AddQuestButton', Showlevel)


	-- Headers background
	local function reskinHeader(header)
		-- header.Text:SetTextColor(C.r, C.g, C.b)
		header.Background:Hide()
		local bg = header:CreateTexture(nil, 'ARTWORK')
		bg:SetTexture('Interface\\LFGFrame\\UI-LFG-SEPARATOR')
		bg:SetTexCoord(0, .66, 0, .31)
		bg:SetVertexColor(C.r, C.g, C.b, .8)
		bg:SetPoint('BOTTOMLEFT', -30, -4)
		bg:SetSize(210, 30)
	end

	local headers = {
		ObjectiveTrackerBlocksFrame.QuestHeader,
		ObjectiveTrackerBlocksFrame.AchievementHeader,
		ObjectiveTrackerBlocksFrame.ScenarioHeader,
		BONUS_OBJECTIVE_TRACKER_MODULE.Header,
		WORLD_QUEST_TRACKER_MODULE.Header,
		ObjectiveTrackerFrame.BlocksFrame.UIWidgetsHeader
	}
	for _, header in pairs(headers) do reskinHeader(header) end


	-- Icons
	local function reskinQuestIcon(_, block)
		local itemButton = block.itemButton
		if itemButton and not itemButton.styled then
			itemButton:SetNormalTexture('')
			itemButton:SetPushedTexture('')
			itemButton:GetHighlightTexture():SetColorTexture(1, 1, 1, .25)
			itemButton.icon:SetTexCoord(unpack(C.TexCoord))
			local bg = F.CreateBDFrame(itemButton.icon)
			F.CreateSD(bg)

			itemButton.Count:ClearAllPoints()
			itemButton.Count:SetPoint('TOP', itemButton, 2, -1)
			itemButton.Count:SetJustifyH('CENTER')
			F.SetFS(itemButton.Count)

			itemButton.styled = true
		end

		local rightButton = block.rightButton
		if rightButton and not rightButton.styled then
			rightButton:SetNormalTexture('')
			rightButton:SetPushedTexture('')
			rightButton:GetHighlightTexture():SetColorTexture(1, 1, 1, .25)
			local bg = F.CreateBDFrame(rightButton)
			F.CreateSD(bg)
			rightButton:SetSize(18, 18)
			rightButton.Icon:SetParent(bg)
			rightButton.Icon:SetSize(16, 16)
			rightButton.Icon:SetPoint('CENTER', rightButton, 'CENTER')

			rightButton.styled = true
		end
	end
	hooksecurefunc(QUEST_TRACKER_MODULE, 'SetBlockHeader', reskinQuestIcon)
	hooksecurefunc(WORLD_QUEST_TRACKER_MODULE, 'AddObjective', reskinQuestIcon)


	-- Progressbars
	local function reskinBarTemplate(bar)
		F.StripTextures(bar)
		bar:SetHeight(16)
		bar:SetStatusBarTexture(C.media.sbTex)
		--bar:GetStatusBarTexture():SetGradient('VERTICAL', r*.9, g*.9, b*.9, r*.4, g*.4, b*.4)
		bar.bg = F.CreateBDFrame(bar)
		F.CreateSD(bar.bg)
	end

	local function reskinProgressbar(_, _, line)
		local progressBar = line.ProgressBar
		local bar = progressBar.Bar
		local icon = bar.Icon
		local label = bar.Label

		if not bar.bg then
			reskinBarTemplate(bar)
			BonusObjectiveTrackerProgressBar_PlayFlareAnim = F.Dummy

			label:ClearAllPoints()
			label:SetPoint('CENTER')
			F.SetFS(label)

			icon:SetMask(nil)
			icon:SetTexCoord(unpack(C.TexCoord))
			icon:ClearAllPoints()
			icon:SetPoint('RIGHT', 30, 0)
			icon:SetSize(24, 24)

			icon.bg = F.CreateBDFrame(icon)
			F.CreateSD(icon.bg)
		end

		if icon.bg then
			icon.bg:SetShown(icon:IsShown() and icon:GetTexture() ~= nil)
		end
	end
	hooksecurefunc(BONUS_OBJECTIVE_TRACKER_MODULE, 'AddProgressBar', reskinProgressbar)
	hooksecurefunc(WORLD_QUEST_TRACKER_MODULE, 'AddProgressBar', reskinProgressbar)
	hooksecurefunc(SCENARIO_TRACKER_MODULE, 'AddProgressBar', reskinProgressbar)

	hooksecurefunc(QUEST_TRACKER_MODULE, 'AddProgressBar', function(_, _, line)
		local progressBar = line.ProgressBar
		local bar = progressBar.Bar
		local label = bar.Label
		
		F.SetFS(label)

		if not bar.bg then
			reskinBarTemplate(bar)
		end
	end)

	local function reskinTimerBar(_, _, line)
		local timerBar = line.TimerBar
		local bar = timerBar.Bar

		if not bar.bg then
			reskinBarTemplate(bar)
		end
	end
	hooksecurefunc(QUEST_TRACKER_MODULE, 'AddTimerBar', reskinTimerBar)
	hooksecurefunc(SCENARIO_TRACKER_MODULE, 'AddTimerBar', reskinTimerBar)
	hooksecurefunc(ACHIEVEMENT_TRACKER_MODULE, 'AddTimerBar', reskinTimerBar)


	-- Blocks
	hooksecurefunc('ScenarioStage_CustomizeBlock', function(block)
		block.NormalBG:SetTexture('')
		if not block.bg then
			block.bg = F.CreateBDFrame(block.GlowTexture)
			block.bg:SetPoint('TOPLEFT', block.GlowTexture, 4, -2)
			block.bg:SetPoint('BOTTOMRIGHT', block.GlowTexture, -4, 0)
			F.CreateSD(block.bg)
		end
	end)

	hooksecurefunc(SCENARIO_CONTENT_TRACKER_MODULE, 'Update', function()
		local widgetContainer = ScenarioStageBlock.WidgetContainer
		if not widgetContainer then return end
		local widgetFrame = widgetContainer:GetChildren()
		if widgetFrame and widgetFrame.Frame then
			widgetFrame.Frame:SetAlpha(0)
			for _, bu in next, {widgetFrame.CurrencyContainer:GetChildren()} do
				if bu and not bu.styled then
					bu.Icon:SetTexCoord(unpack(C.TexCoord))
					local bg = F.CreateBDFrame(bu.Icon)
					bu.styled = true
				end
			end
		end
	end)

	hooksecurefunc('Scenario_ChallengeMode_ShowBlock', function()
		local block = ScenarioChallengeModeBlock
		if not block.bg then
			block.TimerBG:Hide()
			block.TimerBGBack:Hide()
			block.timerbg = F.CreateBDFrame(block.TimerBGBack)
			block.timerbg:SetPoint('TOPLEFT', block.TimerBGBack, 6, -2)
			block.timerbg:SetPoint('BOTTOMRIGHT', block.TimerBGBack, -6, -5)
			F.CreateBD(block.timerbg)

			block.StatusBar:SetStatusBarTexture(C.media.sbTex)
			block.StatusBar:GetStatusBarTexture():SetGradient('VERTICAL', r*.9, g*.9, b*.9, r*.4, g*.4, b*.4)
			block.StatusBar:SetHeight(10)

			select(3, block:GetRegions()):Hide()
			block.bg = F.CreateBDFrame(block)
			block.bg:SetPoint('TOPLEFT', 4, -2)
			block.bg:SetPoint('BOTTOMRIGHT', -4, 0)
			F.CreateBD(block.bg)
			F.CreateSD(block.bg)
		end
	end)

	hooksecurefunc('Scenario_ChallengeMode_SetUpAffixes', F.AffixesSetup)

	-- Minimize button
	F.ReskinExpandOrCollapse(minimize)
	minimize:GetNormalTexture():SetAlpha(0)
	minimize.expTex:SetTexCoord(0.5625, 1, 0, 0.4375)
	hooksecurefunc('ObjectiveTracker_Collapse', function() minimize.expTex:SetTexCoord(0, 0.4375, 0, 0.4375) end)
	hooksecurefunc('ObjectiveTracker_Expand', function() minimize.expTex:SetTexCoord(0.5625, 1, 0, 0.4375) end)



	-- Fonts
	F.SetFont(ot.HeaderMenu.Title, {C.font.header, 16})

	for _, headerName in pairs({'QuestHeader', 'AchievementHeader', 'ScenarioHeader'}) do
		local header = BlocksFrame[headerName]
		F.SetFont(header.Text, {C.font.header, 16})
	end

	do
		local header = BONUS_OBJECTIVE_TRACKER_MODULE.Header
		F.SetFont(header.Text, {C.font.header, 16})
	end

	do
		local header = WORLD_QUEST_TRACKER_MODULE.Header
		F.SetFont(header.Text, {C.font.header, 16})
	end

	hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, 'SetBlockHeader', function(_, block)
		if not block.headerStyled then
			F.SetFont(block.HeaderText, {C.font.normal, 14})
			block.headerStyled = true
		end
	end)

	hooksecurefunc(QUEST_TRACKER_MODULE, 'SetBlockHeader', function(_, block)
		if not block.headerStyled then
			F.SetFont(block.HeaderText, {C.font.normal, 14})
			block.headerStyled = true
		end
	end)


	hooksecurefunc(WORLD_QUEST_TRACKER_MODULE, 'AddObjective', function(_, block)
		local line = block.currentLine

		local p1, a, p2, x, y = line:GetPoint()
		line:SetPoint(p1, a, p2, x, y - 4)
	end)

	hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, 'AddObjective', function(self, block)
		if block.module == QUEST_TRACKER_MODULE or block.module == ACHIEVEMENT_TRACKER_MODULE then
			local line = block.currentLine

			local p1, a, p2, x, y = line:GetPoint()
			line:SetPoint(p1, a, p2, x, y - 4)
		end
	end)

	local function fixBlockHeight(block)
		if block.shouldFix then
			local height = block:GetHeight()

			if block.lines then
				for _, line in pairs(block.lines) do
					if line:IsShown() then
						height = height + 4
					end
				end
			end

			block.shouldFix = false
			block:SetHeight(height + 4)
			block.shouldFix = true
		end
	end

	hooksecurefunc('ObjectiveTracker_AddBlock', function(block)
		if block.lines then
			for _, line in pairs(block.lines) do
				if not line.styled then
					F.SetFont(line.Text, {C.font.normal, 14})
					line.Text:SetSpacing(2)

					if line.Dash then
						F.SetFS(line.Dash)
					end

					line:SetHeight(line.Text:GetHeight())

					line.styled = true
				end
			end
		end

		if not block.styled then
			block.shouldFix = true
			hooksecurefunc(block, 'SetHeight', fixBlockHeight)
			block.styled = true
		end
	end)
end






