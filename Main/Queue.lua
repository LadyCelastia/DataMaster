--[[
    LadyCelestia 7/22/2023
    
    DataStoreService throttle control queue master
    
    module.new(String tag) - Add entry to queue. Yield until out of queue. Return Boolean when entry processed
    module.process() - Process the first request in queue. Yields for 1 frame. Return String tag
    module.remove(String tag) - Process any request with tag immediately. Yields for 1 frame
    module.purge(Number seconds) - Process any request with an in-queue time longer than seconds. Yields for 1 frame
--]]

local QueueModule = {}
QueueModule.Requests = {}

QueueModule.new = function(tag)
	
	local coro = coroutine.create(function()
		coroutine.yield("OutOfQueue")
	end)
	
	table.insert(QueueModule.Requests, {["Tag"] = tostring(tag), ["Time"] = os.time(), ["Coroutine"] = coro})
	
	local success, status = coroutine.resume(coro)
	if success and status == "OutOfQueue" then
		return true
	end
	
	return false
end

QueueModule.process = function()
	
	coroutine.resume(QueueModule.Requests[1]["Coroutine"])
	task.wait()
	
	local tag = QueueModule.Requests[1]["Tag"]
	table.remove(QueueModule.Requests, 1)
	
	return tag
	
end

QueueModule.remove = function(tag)
	
	local indexes = {}
	
	for i,v in ipairs(QueueModule.Requests) do
		if v["Tag"] == tostring(tag) then
			
			coroutine.resume(v["Coroutine"])
			table.insert(indexes, i)
			
		end
	end
	
	task.wait()
	
	if #indexes > 0 then
		for _,v in ipairs(indexes) do
			
			table.remove(QueueModule.Requests, v)
			
			if #indexes > 1 then
				for i,v2 in ipairs(indexes) do
					
					if v < v2 then
						indexes[i] -= 1
					end
					
				end
			end
			
		end
	end
	
end

QueueModule.purge = function(seconds)
	
	local currentTime = os.time()
	local indexes = {}
	
	for i,v in ipairs(QueueModule.Requests) do
		if currentTime - v["Time"] > seconds then
			
			coroutine.resume(v["Coroutine"])
			table.insert(indexes, i)
			
		end
	end
	
	task.wait()
	
	if #indexes > 0 then
		for _,v in ipairs(indexes) do

			table.remove(QueueModule.Requests, v)

			if #indexes > 1 then
				for i,v2 in ipairs(indexes) do

					if v < v2 then
						indexes[i] -= 1
					end

				end
			end

		end
	end
	
end

return QueueModule
