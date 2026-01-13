local Config = loadstring(game:HttpGet("YOUR_GITHUB_LINK/Config.lua"))()
local OreData = loadstring(game:HttpGet("YOUR_GITHUB_LINK/OreDatabase.lua"))()

local StartTime = os.time()
local TotalMined = 0
local InventorySession = {}

-- Fancy Webhook Function
local function sendWebhook(oreName, area)
    local oreInfo = OreData[area][oreName] or {Rarity = "Unknown", Chance = "1/?", Color = 0xFFFFFF}
    
    local sessionDuration = os.time() - StartTime
    local hours = math.floor(sessionDuration / 3600)
    local minutes = math.floor((sessionDuration % 3600) / 60)
    local efficiency = math.floor(TotalMined / (sessionDuration / 3600 + 0.001))

    local data = {
        ["content"] = Config.AutoPing and "<@" .. Config.DiscordID .. ">" or nil,
        ["embeds"] = {{
            ["title"] = "💎 Rare Ore Found!",
            ["description"] = "You just mined a **" .. oreName .. "**!",
            ["color"] = oreInfo.Color,
            ["fields"] = {
                {["name"] = "📍 Current Area", ["value"] = area, ["inline"] = true},
                {["name"] = "✨ Rarity", ["value"] = oreInfo.Rarity .. " (" .. oreInfo.Chance .. ")", ["inline"] = true},
                {["name"] = "⏱️ Session Stats", ["value"] = string.format("%02dh %02dm", hours, minutes), ["inline"] = true},
                {["name"] = "⚡ Efficiency", ["value"] = efficiency .. " Ores/Hour", ["inline"] = true},
                {["name"] = "🟢 Status", ["value"] = "Mining...", ["inline"] = false}
            },
            ["footer"] = {["text"] = "The Forge Tracker v1.0 • GitHub Progression"}
        }}
    }
    
    request({
        Url = Config.WebhookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = game:GetService("HttpService"):JSONEncode(data)
    })
end

-- UI Setup (Rayfield or Orion Library recommended for the Min/Max menu)
-- This logic hooks into the game's "Ore Mined" RemoteEvent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Example hook: Change 'OreMinedEvent' to the actual game's remote name
ReplicatedStorage.Remotes.OreMined.OnClientEvent:Connect(function(oreName, areaName)
    TotalMined = TotalMined + 1
    
    -- Update local tracking
    InventorySession[oreName] = (InventorySession[oreName] or 0) + 1
    
    -- Check if rarity should be sent to Webhook
    local info = OreData[areaName] and OreData[areaName][oreName]
    if info and Config.NotifyRarities[info.Rarity] then
        sendWebhook(oreName, areaName)
    end
end)
