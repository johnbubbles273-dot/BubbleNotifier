-- i know what you are.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
while not player do
	task.wait()
	player = Players.LocalPlayer
end

local playerGui = player:WaitForChild("PlayerGui")

local SETTINGS_FOLDER = "BubbleReceiver"
local SETTINGS_FILE = SETTINGS_FOLDER .. "/Settings.txt"

local AUTO_JOIN_RETRY_DELAY = 3
local STARTUP_AUTOJOIN_DELAY = 30

local autoJoinEnabled = false
local onlyLeftArm = false
local under15Players = false
local autoJoinPaused = false
local autoJoinLoopRunning = false
local startupDelayActive = false
local autoJoinQueue = {}

local function saveSettings()
	if makefolder and isfolder and not isfolder(SETTINGS_FOLDER) then
		makefolder(SETTINGS_FOLDER)
	end

	local data =
		(autoJoinEnabled and "1" or "0") .. "," ..
		(onlyLeftArm and "1" or "0") .. "," ..
		(under15Players and "1" or "0")

	pcall(function()
		writefile(SETTINGS_FILE, data)
	end)
end

local function loadSettings()
	if not isfile or not readfile then return end
	if not isfile(SETTINGS_FILE) then return end

	local success, data = pcall(function()
		return readfile(SETTINGS_FILE)
	end)

	if success and data then
		local a, b, c = data:match("([^,]+),([^,]+),?([^,]*)")
		autoJoinEnabled = a == "1"
		onlyLeftArm = b == "1"
		under15Players = c == "1"
	end
end

loadSettings()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerBrowser"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 550, 0, 320)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://137505070991597"
sound.Volume = 0.5
sound.Parent = mainFrame

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 14)
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Bubble Notifier | Waiting..."
title.TextColor3 = Color3.fromRGB(200, 200, 200)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamMedium
title.TextSize = 14
title.Parent = topBar

local cooldownLabel = Instance.new("TextLabel")
cooldownLabel.Size = UDim2.new(0, 100, 0, 14)
cooldownLabel.Position = UDim2.new(1, -110, 0, 10)
cooldownLabel.BackgroundTransparency = 1
cooldownLabel.Text = ""
cooldownLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
cooldownLabel.Font = Enum.Font.Gotham
cooldownLabel.TextSize = 12
cooldownLabel.TextXAlignment = Enum.TextXAlignment.Right
cooldownLabel.Parent = topBar

local function startStartupCooldown()
	startupDelayActive = true
	title.Text = "Bubble Notifier | Auto Join Delay"
	title.TextColor3 = Color3.fromRGB(200, 200, 200)

	task.spawn(function()
		for i = STARTUP_AUTOJOIN_DELAY, 1, -1 do
			cooldownLabel.Text = "Wait: " .. i .. "s"
			task.wait(1)
		end

		cooldownLabel.Text = ""
		startupDelayActive = false
		title.TextColor3 = autoJoinPaused and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(200, 200, 200)
		title.Text = autoJoinPaused and "Bubble Notifier | Paused - Holding Part" or "Bubble Notifier | Connected To Backend API"
		print("[Bubble Notifier] Startup auto join cooldown finished")
	end)
end

if autoJoinEnabled then
	startStartupCooldown()
end

local function isSaintsHeldObject(obj)
	if not obj then return false end
	return obj.Name:match("^Saints") ~= nil
end

local function characterHasSaintsPart(char)
	if not char then return false end

	for _, obj in ipairs(char:GetDescendants()) do
		if isSaintsHeldObject(obj) then
			return true
		end
	end

	return false
end

local function setAutoJoinPaused(state, reason)
	if autoJoinPaused == state then return end

	autoJoinPaused = state

	if autoJoinPaused then
		title.Text = "Bubble Notifier | Paused - Holding Part"
		title.TextColor3 = Color3.fromRGB(255, 120, 120)
		warn("[Bubble Notifier] Auto join paused:", reason or "Saints part detected")
	else
		title.TextColor3 = Color3.fromRGB(200, 200, 200)
		title.Text = startupDelayActive and "Bubble Notifier | Auto Join Delay" or "Bubble Notifier | Connected To Backend API"
		warn("[Bubble Notifier] Auto join resumed:", reason or "Saints part removed")
	end
end

local function refreshHeldState(char)
	setAutoJoinPaused(characterHasSaintsPart(char), "Held part state changed")
end

local function monitorPlayerWorkspaceModel(char)
	refreshHeldState(char)

	char.DescendantAdded:Connect(function(obj)
		if isSaintsHeldObject(obj) then
			setAutoJoinPaused(true, "Picked up " .. obj.Name)
		end
	end)

	char.DescendantRemoving:Connect(function(obj)
		if isSaintsHeldObject(obj) then
			task.defer(function()
				refreshHeldState(char)
			end)
		end
	end)
end

if player.Character then
	monitorPlayerWorkspaceModel(player.Character)
end

player.CharacterAdded:Connect(function(char)
	autoJoinPaused = false
	title.TextColor3 = Color3.fromRGB(200, 200, 200)
	title.Text = startupDelayActive and "Bubble Notifier | Auto Join Delay" or "Bubble Notifier | Connected"
	monitorPlayerWorkspaceModel(char)
end)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 85, 1, -36)
sidebar.Position = UDim2.new(0, 0, 0, 36)
sidebar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local serversTab = Instance.new("TextButton")
serversTab.Size = UDim2.new(1, 0, 0, 32)
serversTab.Position = UDim2.new(0, 0, 0, 12)
serversTab.BackgroundTransparency = 1
serversTab.Text = "Servers"
serversTab.TextColor3 = Color3.fromRGB(255, 255, 255)
serversTab.Font = Enum.Font.GothamMedium
serversTab.TextSize = 13
serversTab.Parent = sidebar

local autoTab = Instance.new("TextButton")
autoTab.Size = UDim2.new(1, 0, 0, 32)
autoTab.Position = UDim2.new(0, 0, 0, 48)
autoTab.BackgroundTransparency = 1
autoTab.Text = "Auto"
autoTab.TextColor3 = Color3.fromRGB(150, 150, 150)
autoTab.Font = Enum.Font.GothamMedium
autoTab.TextSize = 13
autoTab.Parent = sidebar

local serverListFrame = Instance.new("ScrollingFrame")
serverListFrame.Size = UDim2.new(1, -105, 1, -56)
serverListFrame.Position = UDim2.new(0, 95, 0, 46)
serverListFrame.BackgroundTransparency = 1
serverListFrame.BorderSizePixel = 0
serverListFrame.ScrollBarThickness = 4
serverListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
serverListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
serverListFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = serverListFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 6)
listPadding.Parent = serverListFrame

local autoFrame = Instance.new("Frame")
autoFrame.Size = UDim2.new(1, -105, 1, -56)
autoFrame.Position = UDim2.new(0, 95, 0, 46)
autoFrame.BackgroundTransparency = 1
autoFrame.Visible = false
autoFrame.Parent = mainFrame

local function createSwitchRow(text, yPos)
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -20, 0, 42)
	row.Position = UDim2.new(0, 10, 0, yPos)
	row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	row.BorderSizePixel = 0
	row.Text = ""
	row.AutoButtonColor = false
	row.Parent = autoFrame

	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -80, 1, 0)
	label.Position = UDim2.new(0, 16, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.Parent = row

	local track = Instance.new("Frame")
	track.Size = UDim2.new(0, 46, 0, 24)
	track.Position = UDim2.new(1, -58, 0.5, -12)
	track.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
	track.BorderSizePixel = 0
	track.Parent = row

	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.Position = UDim2.new(0, 3, 0.5, -9)
	knob.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	knob.BorderSizePixel = 0
	knob.Parent = track

	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	return row, track, knob
end

local autoJoinBtn, autoJoinTrack, autoJoinKnob = createSwitchRow("Auto Join", 20)
local leftArmBtn, leftArmTrack, leftArmKnob = createSwitchRow("Only Left Arm", 70)
local under15Btn, under15Track, under15Knob = createSwitchRow("<15 Players", 120)

local serverEntries = {}
local currentTab = "Servers"
local serverIndex = 0

local function isAllowedPart(partName)
	if onlyLeftArm then
		return partName == "SaintsLeftArm"
	end
	return true
end

local function isAllowedPlayerCount(playerCount)
	if under15Players then
		return tonumber(playerCount) and tonumber(playerCount) < 15
	end
	return true
end

local function getTopJoinEntry()
	for i = #autoJoinQueue, 1, -1 do
		local item = autoJoinQueue[i]

		if item
			and item.jobId
			and item.jobId ~= ""
			and serverEntries[item.id]
			and isAllowedPart(item.partName)
			and isAllowedPlayerCount(item.playerCount)
		then
			return item
		end
	end

	return nil
end

local function updateEntryHighlights(activeID)
	for id, entryData in pairs(serverEntries) do
		if entryData.frame then
			if id == activeID then
				entryData.frame.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
			else
				entryData.frame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
			end
		end
	end
end

local function startAutoJoinLoop()
	if autoJoinLoopRunning then return end

	autoJoinLoopRunning = true

	task.spawn(function()
		while autoJoinEnabled do
			task.wait(AUTO_JOIN_RETRY_DELAY)

			if not autoJoinEnabled then
				break
			end

			if startupDelayActive then
				print("[Bubble Notifier] Waiting startup cooldown")
				continue
			end

			if autoJoinPaused then
				print("[Bubble Notifier] Auto Snipe Paused, Holding Saints Part")
				continue
			end

			local topEntry = getTopJoinEntry()

			if topEntry then
				updateEntryHighlights(topEntry.id)

				title.Text = "Bubble Notifier | Joining Top Entry..."
				title.TextColor3 = Color3.fromRGB(200, 200, 200)

				print("[Bubble Notifier] Spam joining top entry:", topEntry.partName, topEntry.jobId)

				local success, err = pcall(function()
					TeleportService:TeleportToPlaceInstance(game.PlaceId, topEntry.jobId, player)
				end)

				if not success then
					warn("[Bubble Notifier] Auto join attempt failed:", err)
				end
			else
				updateEntryHighlights(nil)
				title.Text = "Bubble Notifier | Connected"
				title.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		end

		autoJoinLoopRunning = false
	end)
end

local function updateSwitch(track, knob, enabled)
	local trackColor = enabled and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(45, 45, 48)
	local knobColor = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
	local knobPos = enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

	TweenService:Create(track, TweenInfo.new(0.15), {
		BackgroundColor3 = trackColor
	}):Play()

	TweenService:Create(knob, TweenInfo.new(0.15), {
		BackgroundColor3 = knobColor,
		Position = knobPos
	}):Play()
end

local function refreshAutoButtons()
	updateSwitch(autoJoinTrack, autoJoinKnob, autoJoinEnabled)
	updateSwitch(leftArmTrack, leftArmKnob, onlyLeftArm)
	updateSwitch(under15Track, under15Knob, under15Players)
end

autoJoinBtn.MouseButton1Click:Connect(function()
	autoJoinEnabled = not autoJoinEnabled
	saveSettings()
	refreshAutoButtons()

	if autoJoinEnabled then
		startStartupCooldown()
		startAutoJoinLoop()
	end
end)

leftArmBtn.MouseButton1Click:Connect(function()
	onlyLeftArm = not onlyLeftArm
	saveSettings()
	refreshAutoButtons()

	for _, entry in pairs(serverEntries) do
		entry.frame.Visible = isAllowedPart(entry.partName)
	end
end)

under15Btn.MouseButton1Click:Connect(function()
	under15Players = not under15Players
	saveSettings()
	refreshAutoButtons()
end)

refreshAutoButtons()

if autoJoinEnabled then
	startAutoJoinLoop()
end

local dragging = false
local dragStart = nil
local startPos = nil

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)

topBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		mainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local function updateTabs()
	if currentTab == "Servers" then
		serversTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		autoTab.TextColor3 = Color3.fromRGB(150, 150, 150)
		serverListFrame.Visible = true
		autoFrame.Visible = false
	else
		serversTab.TextColor3 = Color3.fromRGB(150, 150, 150)
		autoTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		serverListFrame.Visible = false
		autoFrame.Visible = true
	end
end

serversTab.MouseButton1Click:Connect(function()
	currentTab = "Servers"
	updateTabs()
end)

autoTab.MouseButton1Click:Connect(function()
	currentTab = "Auto"
	updateTabs()
end)

local function removeFromAutoJoinQueue(uniqueID)
	for i = #autoJoinQueue, 1, -1 do
		if autoJoinQueue[i].id == uniqueID then
			table.remove(autoJoinQueue, i)
		end
	end
end

local function createServerEntry(partName, jobId, playerCount, maxPlayers)
	serverIndex += 1

	local uniqueID = partName .. "_" .. tostring(serverIndex)

	local entry = Instance.new("Frame")
	entry.Name = uniqueID
	entry.Size = UDim2.new(1, -8, 0, 55)
	entry.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	entry.BorderSizePixel = 0
	entry.LayoutOrder = -serverIndex
	entry.Parent = serverListFrame

	Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 10)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Text = "Found: " .. partName
	nameLabel.Size = UDim2.new(1, -90, 0, 18)
	nameLabel.Position = UDim2.new(0, 15, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextSize = 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = entry

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, -90, 0, 14)
	countLabel.Position = UDim2.new(0, 15, 0, 29)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = "Players: " .. playerCount .. " / " .. maxPlayers
	countLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	countLabel.Font = Enum.Font.Gotham
	countLabel.TextSize = 12
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	countLabel.Parent = entry

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(0, 60, 0, 14)
	timerLabel.Position = UDim2.new(0, 115, 0, 29)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "20s"
	timerLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	timerLabel.Font = Enum.Font.Gotham
	timerLabel.TextSize = 12
	timerLabel.TextXAlignment = Enum.TextXAlignment.Left
	timerLabel.Parent = entry

	local joinBtn = Instance.new("TextButton")
	joinBtn.Size = UDim2.new(0, 55, 0, 28)
	joinBtn.Position = UDim2.new(1, -65, 0.5, -14)
	joinBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	joinBtn.BorderSizePixel = 0
	joinBtn.Text = "Join"
	joinBtn.TextColor3 = Color3.new(1, 1, 1)
	joinBtn.Font = Enum.Font.GothamBold
	joinBtn.TextSize = 12
	joinBtn.Parent = entry

	Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 8)

	joinBtn.MouseButton1Click:Connect(function()
		if not jobId or jobId == "" then
			warn("[Bubble Notifier] No valid jobId for:", partName)
			return
		end

		if autoJoinPaused then
			warn("[Bubble Notifier] Teleport blocked because Saints part is held")
			title.Text = "Bubble Notifier | TP Blocked - Holding Part"
			title.TextColor3 = Color3.fromRGB(255, 120, 120)
			return
		end

		if not isAllowedPart(partName) then
			warn("[Bubble Notifier] Blocked teleport due to part filter:", partName)
			return
		end

		print("[Bubble Notifier] Attempting teleport:", jobId)

		local success, err = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
		end)

		if not success then
			warn("[Bubble Notifier] Teleport failed:", err)
		end
	end)

	serverEntries[uniqueID] = {
		frame = entry,
		countLabel = countLabel,
		timerLabel = timerLabel,
		partName = partName,
		playerCount = playerCount,
	}

	table.insert(autoJoinQueue, {
		id = uniqueID,
		partName = partName,
		jobId = jobId,
		playerCount = playerCount,
		maxPlayers = maxPlayers,
	})

	entry.Visible = isAllowedPart(partName)

	if isAllowedPart(partName) then
		sound:Play()
	end

	if autoJoinEnabled then
		startAutoJoinLoop()
	end

	task.spawn(function()
		for secondsLeft = 20, 1, -1 do
			if not entry or not entry.Parent then return end
			timerLabel.Text = tostring(secondsLeft) .. "s"
			task.wait(1)
		end

		serverEntries[uniqueID] = nil
		removeFromAutoJoinQueue(uniqueID)

		if entry and entry.Parent then
			entry:Destroy()
		end
	end)
end

local function parseRawMessage(rawText)
	local partName, playerCount, maxPlayers, jobId

	for line in string.gmatch(rawText, "[^\r\n]+") do
		line = line:match("^%s*(.-)%s*$")

		if line:find("^Part:") then
			partName = line:match("^Part:%s*(.+)$")
		elseif line:find("^Player Count:") then
			local current, max = line:match("(%d+)%s*/%s*(%d+)")
			playerCount = tonumber(current) or 0
			maxPlayers = tonumber(max) or 25
		elseif line:find("^TP:") then
			jobId = line:match("^TP:%s*(.+)$")

			if jobId == "" or jobId == "_" or jobId == "___" then
				jobId = nil
			end
		end
	end

	return partName, playerCount, maxPlayers, jobId
end

local function handleWebSocketMessage(msg)
	print("[WS RECEIVED]:\n" .. tostring(msg))

	local partName, playerCount, maxPlayers, jobId = parseRawMessage(msg)

	if not partName then return end

	createServerEntry(partName, jobId or "", playerCount or 0, maxPlayers or 25)

	if startupDelayActive then
		title.Text = "Bubble Notifier | Auto Join Delay"
	elseif autoJoinPaused then
		title.Text = "Bubble Notifier | Paused - Holding Part"
		title.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		title.Text = "Bubble Notifier | Connected To Backend API"
		title.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end

local WebSocket

pcall(function()
	if syn and syn.websocket then
		WebSocket = syn.websocket
	elseif Krnl and Krnl.WebSocket then
		WebSocket = Krnl.WebSocket
	elseif fluxus and fluxus.websocket then
		WebSocket = fluxus.websocket
	elseif websocket then
		WebSocket = websocket
	end
end)

local WS_URL = "wss://scribe-multitask-research.ngrok-free.dev/"
local socket, connected

local function connectWebSocket()
	if not WebSocket then
		warn("[Bubble Notifier] WebSocket not supported")
		title.Text = "Bubble Notifier | No WS Support"
		return
	end

	local success, result = pcall(function()
		return WebSocket.connect(WS_URL)
	end)

	if success then
		socket = result
	end

	if not success or not socket then
		warn("[Bubble Notifier] Connection failed:", result)
		title.Text = "Bubble Notifier | Connection Failed"
		task.wait(5)
		connectWebSocket()
		return
	end

	connected = true

	if startupDelayActive then
		title.Text = "Bubble Notifier | Auto Join Delay"
	elseif autoJoinPaused then
		title.Text = "Bubble Notifier | Paused - Holding Part"
		title.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		title.Text = "Bubble Notifier | Connected To Backend API"
		title.TextColor3 = Color3.fromRGB(200, 200, 200)
	end

	socket.OnMessage:Connect(function(msg)
		handleWebSocketMessage(msg)
	end)

	socket.OnClose:Connect(function()
		connected = false
		title.Text = "Bubble Notifier | Disconnected"
		title.TextColor3 = Color3.fromRGB(200, 200, 200)

		task.wait(3)
		connectWebSocket()
	end)
end

task.spawn(connectWebSocket)

_G.BubbleReceiverRawTest = function(partName, count, max, jobId)
	local raw = string.format(
		"Part: %s\nPlayer Count: %d/%d\nTP: %s",
		partName,
		count,
		max,
		jobId or ""
	)

	handleWebSocketMessage(raw)
end
