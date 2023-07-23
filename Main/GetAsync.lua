--[[
    LadyCelestia 7/23/2023
    
    Handling GetAsync requests, auto purge and rollback in case of data corruption
    
    module:GetAsync(Number userId) - YIELDS. Self-explanatory, auto purges outdated versions. Returns Tuple data, Number workingVersion, Number latestVersion, Boolean notLatest
    module:GetOrderedAsync(String or Number identifier) - YIELDS. Self-explanatory. Returns DataStorePages sorted
    module:GetVersion(Number userId) - YIELDS. Get the latest version number of player. Returns Number version
--]]

local GetAsync = {}

local DataStoreService = game:GetService("DataStoreService")

function GetAsync:GetAsync(userId)
	
	local MainStore = DataStoreService:GetDataStore(userId.. "/PlayerData")
	local VersionStore = DataStoreService:GetOrderedDataStore(userId.. "/PlayerData")
	
	local sorted = VersionStore:GetSortedAsync(false, 1)
	local page = sorted:GetCurrentPage()
	
	local data, workingVersion, latestVersion
	local notLatest = false
	local attempts = 0
	
	repeat
		
		for i, v in ipairs(page) do
			
			if not latestVersion then
				latestVersion = v.value
			end
			
			local cache = nil
			local success, err = pcall(function()
				cache = MainStore:GetAsync(v.value)
			end)
			
			if not success then
				warn("[GetAsync]: GetAsync error. Error message: " ..(err or "No error message."))
			end
			
			if cache ~= nil then
				
				data = cache
				workingVersion = v.value
				
			else
				notLatest = true
				
			end
			
			attempts += 1
			
		end
		
		if data ~= nil or attempts > 4 or sorted.IsFinished then
			break
		end
		
		sorted:AdvanceToNextPageAsync()
		page = sorted:GetCurrentPage()
		
	until data ~= nil or attempts > 4
	
	-- \\ Auto Purge \\
	coroutine.wrap(function()
		
		local maxVersion = workingVersion - 50
		
		local keyPages = nil
		local success, err = pcall(function()
			keyPages = MainStore:ListKeysAsync("", 10)
		end)
		
		if not success then
			warn("[GetAsync]: ListKeysAsync error. Error message: " ..(err or "No error message."))
		end
		
		if keyPages ~= nil then
			
			local page = keyPages:GetCurrentPage()
			local removeVersions = {}
			
			repeat
				
				for i,v in pairs(page) do

					if v.KeyName < maxVersion then
                        table.insert(removeVersions, v.KeyName)
					end

				end

				keyPages:AdvanceToNextPageAsync()
				page = keyPages:GetCurrentPage()
					
			until keyPages.IsFinished
			
			for _,v in ipairs(removeVersions) do
				
				local success, err = pcall(function()
					
					MainStore:RemoveAsync(v)
					
				end)
				
				if not success then
					warn("[AutoPurge]: AutoPurge error while iterating through versions to remove. Error message: " ..(err or "No error message."))
				end
				
			end
			
		end
	end)
	
	return data, workingVersion, latestVersion, notLatest
end

function GetAsync:GetVersion(userId)
	
	local VersionStore = DataStoreService:GetOrderedDataStore(userId.. "/PlayerData")
	
	local sorted = VersionStore:GetSortedAsync(false, 1)
	local page = sorted:GetCurrentPage()
	
	local currentVersion
	for i,v in ipairs(page) do
		
		currentVersion = v.value
		
	end
	
	return currentVersion
	
end

function GetAsync:GetOrderedAsync(identifier, ascending, pageSize)
	
	local MainStore = DataStoreService:GetOrderedDataStore(identifier)
	
	local sorted
	local attempts = 0
	
	repeat
		
		local success, err = pcall(function()
            sorted = MainStore:GetSortedAsync(ascending or false, pageSize or 10)
		end)
		
		if not success then
			warn("[GetAsync]: GetOrderedAsync error. Error message: " ..(err or "No error message."))
			break
		end
		
		attempts += 1
		
		if sorted ~= nil or attempts > 3 then
			break
		end
		
	until sorted ~= nil or attempts > 3
	
	return sorted
	
end

return GetAsync
