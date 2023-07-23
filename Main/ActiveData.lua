--[[
    LadyCelestia 7/22/2023
    
    ActiveData Class, one assigned to each player in server
    
    module.new(Player player) - Creates new ActiveData. Return ActiveData
    
    ActiveData:Nest(String or Number index) - Increase nesting by one layer with index if path is valid. Return Boolean Success
    ActiveData:Unnest(Boolean? all) - Decrease nesting by one layer if all == false or all == nil, otherwise reset nesting to top level
    ActiveData:HardSet(String or Number index, Any value) - Set index of current nesting to value
    ActiveData:HardRemove(String or Number index) - Set index of current nesting to nil, moves subsequent number indexes down by 1 if index is a number
    ActiveData:Increment(String or Number index, Number value) - Increase value of nesting[index] by value. Return Number newValue
    ActiveData:Reduction(String or Number index, Number value) - Decrease value of nesting[index] by value. Return Number newValue
    
    ActiveData:CheckNestingIntegrity() - Internal function. Checks validity of current nesting path. Return Boolean Success
--]]

local ActiveData = {}

ActiveData.new = function(player)
	
	local self = setmetatable({["Data"] = {}}, {
		
		__call = function(self, index)
			
			if index == "GetId" then
				return getmetatable(self).UserId
				
			elseif index == "GetPlayer" then
				return getmetatable(self).Player
				
			elseif index == "GetNest" then
				return getmetatable(self).Nest
				
			end
			
		end,
		
		Player = player,
		UserId = player.UserId,
		Nest = {}
		
	})
	
	-- \\ Internal functions \\
	
	function self:CheckNestingIntegrity()
		
		local check = self.Data
		local success, err = pcall(function()
			
			local entries = #getmetatable(self).Nest
			for i,v in ipairs(getmetatable(self).Nest) do
				check = check[v]
				
				if check == nil and entries > i then
					return false
				end
				
			end
			
		end)
		
		if success then
			return true
		end
		
		warn("[ActiveData]: ActiveData nesting integrity check failed. " ..(err or "No error message."))
		return false
		
	end
	
	
	function self:Unnest(all)

		if all == true then
			getmetatable(self).Nest = {}
		else
			getmetatable(self).Nest = table.remove(getmetatable(self).Nest, #getmetatable(self).Nest)
		end

	end
	
	function self:Nest(index)
		
		if self:CheckNestingIntegrity() == true then
			getmetatable(self).Nest = table.insert(getmetatable(self).Nest, index)
			return true
		end
		
		return false
		
	end
	
	-- \\ User functions \\
	
	function self:GetValue(index)
		
		local nest = self("GetNest")
		
		if #nest > 0 then
			
			local directory = self.Data
			local previousDirectory, lastDirectoryName
			
			for _, name in ipairs(nest) do
				if directory[name] ~= nil then
				    previousDirectory = directory
				    lastDirectoryName = name
					directory = directory[name]
				else
					break
				end
			end
			
			if previousDirectory then
				return previousDirectory[lastDirectoryName][index]
			else
				return nil
			end
			
		else
			
			return self.Data[index]
			
		end
		
	end
	
	function self:HardSet(index, value)
		
		local nest = self("GetNest")
		local directory = self.Data
		local previousDirectory, lastDirectoryName
		
		for _, name in ipairs(nest) do
			previousDirectory = directory
			lastDirectoryName = name
			directory = directory[name]
		end
		
		previousDirectory[lastDirectoryName][index] = value
		
	end
	
	function self:HardRemove(index)

		local nest = self("GetNest")
		local directory = self.Data
		local previousDirectory, lastDirectoryName

		for _, name in ipairs(nest) do
			previousDirectory = directory
			lastDirectoryName = name
			directory = directory[name]
		end

		if typeof(index) == "number" then
			table.remove(previousDirectory[lastDirectoryName], index)
		else
			previousDirectory[lastDirectoryName][index] = nil
		end

	end
	
	function self:Increment(index, value)
		
		local data = self:GetValue(index)
		
		if data ~= nil then
			if typeof(data) == "number" then
				
				local newValue = data + tonumber(value)
				self:HardSet(index, newValue)
				return newValue
				
			end
		end
		
	end
	
	function self:Reduction(index, value)
		
		local data = self:GetValue(index)

		if data ~= nil then
			if typeof(data) == "number" then
				
				local newValue = data - tonumber(value)
				self:HardSet(index, newValue)
				return newValue
				
			end
		end
		
	end
	
end

return ActiveData
