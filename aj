local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local PLACE_ID = 99449877692519
local API_URL = "https://scribe-multitask-research.ngrok-free.dev/get-jobid"

local player = Players.LocalPlayer

print("Job queue script started")

local function getJobId()
	local req = request or http_request or (syn and syn.request)

	if not req then
		warn("No request/http_request function found")
		return nil
	end

	local success, response = pcall(function()
		return req({
			Url = API_URL,
			Method = "GET"
		})
	end)

	if not success then
		warn("Request failed:", response)
		return nil
	end

	print("HTTP status:", response.StatusCode or response.Status)

	local body = response.Body or response.body
	print("Response body:", body)

	local data = HttpService:JSONDecode(body)
	return data.jobId
end

task.wait(2)

local jobId = getJobId()

if not jobId then
	warn("No jobId received")
	return
end

print("Teleporting to jobId:", jobId)

local success, err = pcall(function()
	TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, player)
end)

if not success then
	warn("Teleport failed:", err)
end
