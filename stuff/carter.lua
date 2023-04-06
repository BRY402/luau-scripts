local HttpService = game:GetService("HttpService")
local lib = loadstring(HttpService:GetAsync("https://github.com/BRY402/random-scripts/raw/main/stuff/lib.lua",true))()
local function getResponse(data)
	local response = HttpService:RequestAsync({Url = storage.url,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = HttpService:JSONEncode(data)
	})
	assert(response.Success, "Response fail: "..response.StatusCode..", "..response.StatusMessage)
	return HttpService:JSONDecode(response.Body)
end
local bots = {}
local carter = {new = function(api_key, version_)
	local storage = {
		key = "",
		CanChat = true,
		ids = {}
	}
	local ChatterEvent = lib.Utilities.newEvent("ChatterAdded", "AddChatter")
	local BotChatted = lib.Utilities.newEvent("Chatted")
	local bot = {
		ChatterAdded = ChatterEvent.ChatterAdded,
		Chatted = BotChatted.Chatted
	}
	function bot:Exit()
		storage.CanChat = false
	end
	local Versions = {
		V0 = function()
			warn("i dont really recommend using v0 since they added v1 but its up to you")
			storage.url = "https://api.carterapi.com/v0/chat"
			storage.scene = "Normal"
			function bot:Send(msg, player)
				assert(storage.CanChat,"Bot#"..tostring(table.find(bots, bot)).." is disabled")
				local id = player and player.UserId or 0
				if player and not table.find(storage.ids, id) then
					table.insert(storage.ids,id)
					ChatterEvent:AddChatter(player)
				end
				local reply = getResponse({
					api_key = storage.key,
					query = msg,
					uuid = id,
					scene = storage.scene
				})
				local outputData = {
					Player = player,
					Time_Taken = reply.time_taken,
					Credits_Used = reply.credits_used
				}
				local outputText = reply.output.text
				BotChatted:Fire(outputText, outputData)
				return outputText, outputData
			end
			function bot:SetScene(scene)
				assert(scene, "Missing scene argument for SetScene")
				storage.scene = tostring(scene)
			end
		end,
		V1 = function()
			storage.url = "https://api.carterlabs.ai/chat"
			function bot:Send(msg, player)
				assert(storage.CanChat,"Bot#"..tostring(table.find(bots, bot)).." is disabled")
				local id = player and player.UserId or 0
				if player and not table.find(storage.ids, id) then
					table.insert(storage.ids,id)
					ChatterEvent:AddChatter(player)
				end
				local outputData = getResponse({
					key = storage.key,
					text = msg,
					playerId = id,
				})
				local outputText = outputData.output.text
				outputData.Player = player
				BotChatted:Fire(outputText, outputData)
				return outputText, outputData
			end
		end
	}
	assert(version_ and typeof(version_) == "string", "Expected version")
	local botVersion = Versions[version_]
	assert(botVersion, "Invalid version")
	storage.key = tostring(api_key)
	bot.Version = version_
	botVersion()
	table.insert(bots, bot)
	return bot
end}
return carter
