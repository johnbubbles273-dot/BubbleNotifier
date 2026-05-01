-- testing

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- === SETTINGS ===
local DROPS = {
	SaintsLeftArm = true,
	SaintsRightArm = true,
	SaintsLeftLeg = true,
	SaintsRightLeg = true,
	SaintsRibcage = true,
}

-- ⚠️ REPLACE THIS WITH A NEW WEBHOOK
local WEBHOOK_URL = "https://discord.com/api/webhooks/1499068706716778709/FxSPdNCPab2vV14aNKLns3jwklz2OE7cZaw8Cpi3bQKCB5iEneGDT-hgWtC-O1nR9fLh"

-- ✅ FIXED: no /send, using proper WSS root
local RELAY_URL = "wss://scribe-multitask-research.ngrok-free.dev"

local request = request
local WebSocket = syn and syn.websocket or WebSocket

local sent = {}
local ws

-- === WEBSOCKET CONNECT ===
pcall(function()
	if WebSocket and WebSocket.connect then
		ws = WebSocket.connect(RELAY_URL)
		print("[WebSocket] Connected")
	else
		warn("[WebSocket] Not available")
	end
end)

-- === ZONE SYSTEM ===
local ZONES = {
	Vector3.new(-5689.33, 103.83, -3266.03),
	Vector3.new(-7988.94, 67.37, -3212.18),
	Vector3.new(-4018.97, 45.23, -2762.06),
	Vector3.new(-4412.94, 47.39, -1959.46),
	Vector3.new(-3038.57, 47.52, -1783.68),
	Vector3.new(-2192.09, 250.38, -3365.89),
	Vector3.new(-2244.54, 53.78, -3613.92),
	Vector3.new(-2376.34, 57.31, -3822.05),
	Vector3.new(-1856.17, 42.47, -5014.21),
	Vector3.new(-3283.54, 47.83, -5193.98),
	Vector3.new(-3800.04, 242.86, -6001.51),
	Vector3.new(-3934.53, 206.59, -5632.87),
	Vector3.new(-4114.48, 65.89, -4982.86),
	Vector3.new(-4312.44, 63.20, -4814.78),
	Vector3.new(-4163.66, 47.17, -3985.48),
	Vector3.new(-7115.17, -200.74, -5333.19),
	Vector3.new(-7774.09, 49.42, -4513.27),
}

local RADIUS = 100
local Y_TOLERANCE = 50

local function inZone(pos)
	for _, zone in ipairs(ZONES) do
		local horizontalDist = (
			Vector3.new(pos.X, 0, pos.Z) - Vector3.new(zone.X, 0, zone.Z)
		).Magnitude

		local yDiff = math.abs(pos.Y - zone.Y)

		if horizontalDist <= RADIUS and yDiff <= Y_TOLERANCE then
			return true
		end
	end
	return false
end

-- === TELEPORT SCRIPT BUILDER ===
local function buildTeleportScript()
	return string.format(
		[[game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)]],
		game.PlaceId,
		game.JobId
	)
end

-- === SEND WEBHOOK + WEBSOCKET ===
local function sendWebhookAndRelay(part)
	if not part then return end

	local pos = part.Position
	local teleportScript = buildTeleportScript()

	local payload = {
		username = "Corpse Sniper",
		embeds = {{
			title = "Corpse Part Found",
			description = "**Part:** `" .. part.Name .. "`\n" ..
				"**Coords:** `" .. tostring(pos) .. "`",
			color = 65280,
			fields = {
				{
					name = "Players",
					value = #Players:GetPlayers() .. " / " .. Players.MaxPlayers,
					inline = true
				},
				{
					name = "Coordinates",
					value = string.format(
						"X: %.2f | Y: %.2f | Z: %.2f",
						pos.X, pos.Y, pos.Z
					),
					inline = false
				},
				{
					name = "Teleport Script",
					value = "```lua\n" .. teleportScript .. "\n```",
					inline = false
				}
			},
			timestamp = DateTime.now():ToIsoDate()
		}}
	}

	-- Discord webhook
	if request then
		pcall(function()
			request({
				Url = WEBHOOK_URL,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = HttpService:JSONEncode(payload)
			})

			print("[Discord] Sent:", part.Name)
		end)
	end

	-- WebSocket relay
	if ws then
		pcall(function()
			ws:Send(HttpService:JSONEncode({
				type = "teleportData",
				part = part.Name,
				players = #Players:GetPlayers(),
				max = Players.MaxPlayers,
				tp = game.JobId,
				placeId = game.PlaceId,
				code = teleportScript
			}))

			print("[WebSocket] Sent:", part.Name)
		end)
	else
		warn("[WebSocket] Not connected")
	end
end

-- === DETECTION ===
local function check(obj)
	if not obj:IsA("BasePart") then return end
	if not DROPS[obj.Name] then return end
	if sent[obj] then return end

	local pos = obj.Position

	if not inZone(pos) then
		return
	end

	sent[obj] = true

	print("FOUND VALID PART IN ZONE:", obj.Name, pos)

	sendWebhookAndRelay(obj)
end

-- Check existing parts
for _, obj in ipairs(workspace:GetDescendants()) do
	pcall(function()
		check(obj)
	end)
end

-- Check new parts
workspace.DescendantAdded:Connect(function(obj)
	pcall(function()
		check(obj)
	end)
end)

print("Corpse Sniper sender loaded (WebSocket + Webhook working)")
