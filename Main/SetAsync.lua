--[[
    LadyCelestia 7/22/2023
    
    Handling SetAsync requests
    
    module:SetAsync(Number userId, Tuple data, Number currentVersion) - YIELDS. Self-explanatory. Return Boolean success
    module:SetOrderedAsync(Number userId, String identifier, Number data) - YIELDS. Self-explanatory. Return Boolean success
--]]

local SetAsync = {}

local DataStoreService = game:GetService("DataStoreService")

function SetAsync:SetAsync(userId, data, currentVersion)
	
	local MainStore = DataStoreService:GetDataStore(userId.. "/PlayerData")
	local VersionStore = DataStoreService:GetOrderedDataStore(userId.. "/PlayerData")
	
	local attempts = 0
	local function store()
		
		attempts += 1
		local success, err = pcall(function()

			MainStore:SetAsync(tostring(currentVersion + 1), {["Data"] = data, ["Time"] = os.time()})
			VersionStore:SetAsync(tostring(currentVersion + 1), currentVersion + 1)

		end)
		
		if success == true then
			return true
			
		elseif attempts < 3 then
			warn("[SetAsync]: SetAsync failed. Attempt: " ..tostring(attempts).. " Error message: " ..(err or "No error message."))
			store()
			
		else
			warn("[SetAsync]: SetAsync failed. Further attempts stopped due to reaching maximum attempt(s). Error message: " ..(err or "No error message."))
			return false
		end
		
	end
	
	local success = store()
	return success
	
end

function SetAsync:SetOrderedAsync(userId, identifier, data)
	
	local MainStore = DataStoreService:GetOrderedDataStore(identifier)
	
	local attempts = 0
	local function store()

		attempts += 1
		local success, err = pcall(function()
			
			MainStore:SetAsync(userId, tonumber(data) or 0)

		end)

		if success == true then
			return true

		elseif attempts < 3 then
			warn("[SetAsync]: SetOrderedAsync failed. Attempt: " ..tostring(attempts).. " Error message: " ..(err or "No error message."))
			local bool = store()
			return bool

		else
			warn("[SetAsync]: SetOrderedAsync failed. Further attempts stopped due to reaching maximum attempt(s). Error message: " ..(err or "No error message."))
			return false
		end

	end

	local success = store()
	return success
	
end

return SetAsync
