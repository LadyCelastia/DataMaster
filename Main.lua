--[[
    LadyCelestia 7/22/2023
    Scripted for the use of Solar and Robloxian Tower Defense
    
    Advanced dynamic data storing system
    Uses modified berezaa DS2 method (50 backup purge)
    
    module.ForceGet(Number userId) - YIELDS. Get player data without registering player. Returns Tuple data (may be {} in case of http exception or target player having no previously saved data)
    module.ForceSave(Number userId) - YIELDS. Save player data without unregistering player. Returns Boolean success
    
    module.PlayerJoined(Number userId) - YIELDS. Get player data and register player. Returns ActiveData
    module.PlayerLeft(Number userId) - YIELDS. If player is registered, save player data then unregister player. Returns Boolean success
    
    module.OverwriteData(Number userId, Tuple newData) - Overwrite the data of a registered player with newData. Returns Boolean success
    module.GetData(Number userId) - Get the data of a registered player. Return Tuple dataCopy
    
    module.GetOrdered(String or Number identifier, Boolean ascending?, Number pageSize?) - YIELDS. Get OrderedDataStore[identifier] as a sorted DataStorePages. Returns DataStorePages (may be nil in case of http exception)
    module.SetOrdered(Number userId, String or Number identifier, Number data) - YIELDS. Set OrderedDataStore[identifier]'s userId (key) to data (value). Returns Boolean success

    In depth API listed at the top of each dependent module.
--]]

local module = {}
module.Players = {}

local Players = game:GetService("Players")

local ActiveData = require(script:WaitForChild("ActiveData"))
local GetAsync = require(script:WaitForChild("GetAsync"))
local SetAsync = require(script:WaitForChild("SetAsync"))
--local Queue = require(script:WaitForChild("Queue"))
local Webhook = require(script:WaitForChild("Webhook"))

local function DeepCopy(original)

	local copy = {}
	for i,v in pairs(original) do

		if typeof(v) == "table" then
			v = DeepCopy(v)
		end

		copy[i] = v
	end

	return setmetatable(copy, getmetatable(original))

end

module.ForceGet = function(userId)
	
	local data, workingVersion, latestVersion, notLatest = GetAsync:GetAsync(userId)

	if data then

		print("[DataMaster]: Player " ..userId.. " has existing data.")

	else

		warn("[DataMaster]: Player " ..userId.. " has no existing data.")
		coroutine.wrap(function()
			Webhook:SendMessageWithAvatar(userId, "Player (" ..userId.. ") has joined without previously saved data.", "New Player", 655104)
		end)

	end

	return data or {}
	
end

module.PlayerJoined = function(userId)
	
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		warn("[DataMaster]: PlayerJoined player does not exist in server.")
		return
	end
	
	local newData = ActiveData.new(player)
	
	local data, workingVersion, latestVersion, notLatest = GetAsync:GetAsync(userId)
	
	if data then
		
		print("[DataMaster]: Player " ..userId.. " has existing data.")
		newData["Data"] = data
		newData["CurrentVersion"] = latestVersion
		newData["Version"] = workingVersion
	    	
	else
		
		warn("[DataMaster]: Player " ..userId.. " has no existing data.")
		coroutine.wrap(function()
			Webhook:SendMessageWithAvatar(userId, "Player (" ..userId.. ") has joined without previously saved data.", "New Player", 655104)
		end)
		
		newData["Data"] = {}
		newData["CurrentVersion"] = 1
		newData["Version"] = 1
		
	end
	
	module.Players[userId] = newData
	
	return newData
	
end

module.OverwriteData = function(userId, newData)
	
	local success = false
	for i,v in pairs(module.Players) do
		
		if i == userId then
			
			module.Players[i]["Data"] = newData
			success = true
		    break
			
		end
		
	end
	
	return success
	
end

module.GetData = function(userId)
	
	if module.Players[userId] ~= nil then
		
		return DeepCopy(module.Players[userId]["Data"])
		
	end
	
	return nil
	
end

module.ForceSave = function(userId, data)
	
	local currentVersion = GetAsync:GetVersion(userId)

	if currentVersion then

		local success = SetAsync:SetAsync(userId, data, currentVersion)

		if not success then

			warn("[DataMaster]: SetAsync failure.")

			coroutine.wrap(function()
				Webhook:SendMessageWithAvatar(userId, "SetAsync exception for " .. Players:GetNameFromUserIdAsync(userId).. " (" ..userId.. "). SetAsync request has failed.", "Datastore Error", 16711680)
			end)

		end

		return success

	else

		warn("[DataMaster]: SetAsync failure.")

		coroutine.wrap(function()
			Webhook:SendMessageWithAvatar(userId, "SetAsync exception for " .. Players:GetNameFromUserIdAsync(userId).. " (" ..userId.. "). Data for SetAsync is invalid.", "Datastore Error", 16711680)
		end)

	end

	return false
	
end

module.PlayerLeft = function(userId)
	
	local dataCopy
	local currentVersion
	
	for i,v in pairs(module.Players) do
		
		if i == userId then
			dataCopy = DeepCopy(module.Players[i]["Data"])
			currentVersion = module.Players[i]["CurrentVersion"]
		end
		
	end
	
	if dataCopy then
		
		local success = SetAsync:SetAsync(userId, dataCopy, currentVersion)
		
		if not success then
			
			warn("[DataMaster]: SetAsync failure.")
			
			coroutine.wrap(function()
				Webhook:SendMessageWithAvatar(userId, "SetAsync exception for " .. Players:GetNameFromUserIdAsync(userId).. " (" ..userId.. "). SetAsync request has failed.", "Datastore Error", 16711680)
			end)
			
		end
		
		module.Players[userId] = nil
		
		return success
		
	else
		
		warn("[DataMaster]: SetAsync failure.")

		coroutine.wrap(function()
			Webhook:SendMessageWithAvatar(userId, "SetAsync exception for " .. Players:GetNameFromUserIdAsync(userId).. " (" ..userId.. "). Data for SetAsync is invalid.", "Datastore Error", 16711680)
		end)
		
	end
	
	return false
	
end

module.GetOrdered = function(identifier, ascending, pageSize)
	
	local sorted = GetAsync:GetOrderedAsync(identifier, ascending or false, pageSize or 10)
	
	return sorted
	
end

module.SetOrdered = function(userId, identifier, data)
	
	local success = SetAsync:SetOrderedAsync(userId, identifier, data)
	
	return success
	
end

return module
