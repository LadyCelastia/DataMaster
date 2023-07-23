--[[
    LadyCelestia 7/23/2023 & 2/8/2019 + SpectrumDev 2/8/2019
    A modern reimaging of an old collaboration between LadyCelestia and SpectrumDev
    
    Discord webhook module
    
    module:SendMessage(String message, String title, String color?) - YIELDS. Post a rich embed using pre-set settings. Return Boolean success
    module:SendMessageWithAvatar(Number userId, String message, String title, String color?) - YIELDS. Post a rich embed using pre-set settings, with a player's avatar icon displayed as author. Return Boolean success

    Other functions and methods are internal API.
--]]

local HttpService = game:GetService("HttpService")

local success, _ = pcall(function()
	HttpService:GetAsync("http://www.google.com/")
end)

if not success then
	
	warn("[Webhook]: Critical error. HttpService is not enabled.")
	return
		
end

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name or "ROBLOX Studio"

local module = {}

module.new = function(values)
	return setmetatable({["properties"] = values}, module)
end

module.__index = module

local embed = {}

embed.new = function()
	return setmetatable({["fields"] = {}}, embed)
end

embed.__index = embed

function embed:NewField(name, value, inline)
	
	self.fields[#self.fields + 1] = {
		["name"] = name,
		["value"] = value,
		["inline"] = inline or false
	}
	
	return self
	
end

function embed:SetAuthor(name, icon_url, url)
	
	self.author = {
		["name"] = name,
		["icon_url"] = icon_url or "",
		["url"] = url or ""
	}
	
	return self
	
end

function embed:SetColor(color)
	
	self.color = color
	return self
	
end

function embed:SetDescription(desc)
	
	self.description = desc
	return self
	
end

function embed:SetFooter(text, icon)
	
	self.footer = {
		["text"] = text,
		["icon_url"] = icon or ""
	}
	
	return self
	
end

function embed:SetImage(url)
	
	self.image = {
		["url"] = url
	}
	
	return self
	
end

function embed:SetThumbnail(url)
	
	self.thumbnail = {
		["url"] = url
	}
	
	return self
	
end

function embed:SetTimeStamp(timestamp)
	
	self.timestamp = timestamp
	return self
	
end

function embed:SetTitle(title)
	
	self.title = title
	return self
	
end

function embed:SetUrl(url)
	
	self.url = url
	return self
	
end

module.RichEmbed = embed

local webhook = {}

webhook.new = function(url, options)
	return setmetatable({
		url = url,
		options = options or {}
	}, webhook)
end

webhook.__index = webhook

webhook.__call = function(self, content, options)
	
	local data = {}
	
	if typeof(content) == "string" then
		data["content"] = content
	end
	
	local sendEmbed
	if typeof(content) == "table" then
		sendEmbed = content
		
	elseif options["embed"] ~= nil then
		sendEmbed = options["embed"]
		
	end
	
	if sendEmbed ~= nil then
		
		local embedData = {}
		for i,v in pairs(sendEmbed) do
			embedData[i] = v
		end
		
		data["embeds"] = {}		
		data["embeds"][1] = embedData
		
	end

	if options ~= nil then
		
		for i,v in pairs(options) do
			
			if typeof(v) ~= "table" then
				data[i] = v
			end
			
		end
		
	end
	
	local success, err = pcall(function()
		HttpService:PostAsync(self.url, HttpService:JSONEncode(data))
	end)
	
	if not success then
		warn("[Webhook]: Failed to post message via webhook. Error message: " ..(err or "No error message."))
	end
	
	return success
	
end

module.Webhook = webhook

--https://discordapp.com/api/webhooks/1132566214326095922/Gx5Nhr3cIsW1i6RJ2z3denoDbFNzxUkJCjrz3-IHe1hK6mMsYi1hgFRQWKqvJ5MbSzqg
local PersistWebhook = module.Webhook.new("https://discordapp.com/api/webhooks/1132591359094706176/2INi_IaZYwXC_0u_TB0nXtvF5sQWiro0W2fA_860AhXcSG0Q7lpRfsl09kRSLcHdCERX")

function module:SendMessage(message, title, color)
	
	local SendEmbed = embed.new()
	:SetTitle(title)
	:SetDescription("\n\n**Message Attached:**" .. "\n" ..message)
	:SetFooter("Log sent from " ..placeName)
	:SetColor(color or 0)
	
	local bool = PersistWebhook(SendEmbed, {username = "Solar Datastore System", avatar_url = "https://t7.rbxcdn.com/51147f00f8f037582ba316c0c369edbc"})
	
	return bool
	
end

function module:SendMessageWithAvatar(userId, message, title, color)
	
	local username
	local success, err = pcall(function()
		username = Players:GetNameFromUserIdAsync(userId)
	end)
	
	if not success then
		warn("[Webhook]: Failed to post message with avatar via webhook. Error message: " ..(err or "No error message."))
	end
	
	if username ~= nil then
		
		local proxy
		local success, err = pcall(function()
			proxy = HttpService:GetAsync("https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=" ..userId.. "&size=420x420&format=Png&isCircular=false")
		end)
		
		local avatarUrl = "http://www.roblox.com/Thumbs/Avatar.ashx?x=100&y=100&Format=Png&username="  ..username
		if success == true then
			local decoded = HttpService:JSONDecode(proxy)
			avatarUrl = decoded["data"][1]["imageUrl"]
		end
		
		local SendEmbed = embed.new()
		:SetAuthor(username, avatarUrl, "https://www.roblox.com/users/"  ..userId..  "/profile")
		:SetTitle(title)
		:SetDescription("\n\n**Message Attached:**" .. "\n" ..message)
		:SetFooter("Log sent from " ..placeName)
		:SetColor(color or 0)
		
		local bool = PersistWebhook(SendEmbed, {username = "Solar Datastore System", avatar_url = "https://t7.rbxcdn.com/51147f00f8f037582ba316c0c369edbc"})

		return bool
		
	end
	
	warn("[Webhook]: Failed to post message with avatar via webhook.")
	return false
	
end

return module
