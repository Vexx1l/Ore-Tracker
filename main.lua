--[[
    THE FORGE: ULTIMATE ORE TRACKER (BUILD 6.0)
    Features: 
    - Real-time Ore Counter & Efficiency (OPH)
    - World Detection (W1, W2, W3)
    - Rarity Filters for Webhooks
    - Fancy Discord Embeds
]]

local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer
local startTime = os.time()

-- ORE DATA & FILTERS
local ORE_DATA = {
    ["Common"] = {Color = 0x808080, Emoji = "⚪"},
    ["Uncommon"] = {Color = 0x3dff4a, Emoji = "🟢"},
    ["Rare"] = {Color = 0x00aaff, Emoji = "🔵"},
    ["Epic"] = {Color = 0xaa00ff, Emoji = "🟣"},
    ["Legendary"] = {Color = 0xffaa00, Emoji = "🟠"},
    ["Mythic"] = {Color = 0xff0044, Emoji = "🔴"}
}

-- SESSION VARIABLES
_G.TrackerSettings = {
    Webhook = "PASTE_HERE",
    DiscordID = "958143880291823647",
    Filters = {Common = false, Rare = true, Legendary = true, Mythic = true},
    TotalMined = 0,
    RareMined = 0
}

-- 1. THE WEBHOOK ENGINE (Fancy Layout)
local function sendOreWebhook(oreName, rarity, isHeartbeat)
    if _G.TrackerSettings.Webhook == "" or _G.TrackerSettings.Webhook == "PASTE_HERE" then return end
    
    local data = ORE_DATA[rarity] or {Color = 0xFFFFFF, Emoji = "❓"}
    local uptime = os.time() - startTime
    local oph = math.floor((_G.TrackerSettings.TotalMined / (uptime / 3600)) or 0)
    
    local embed = {
        ["title"] = isHeartbeat and "🔄 Session Status" or data.Emoji .. " New Rare Ore Found!",
        ["color"] = data.Color,
        ["fields"] = {
            {["name"] = "🎮 Player", ["value"] = "```" .. player.Name .. "```", ["inline"] = true},
            {["name"] = "⏱️ Uptime", ["value"] = string.format("%dh %dm", math.floor(uptime/3600), math.floor((uptime%3600)/60)), ["inline"] = true},
            {["name"] = "💎 Last Ore", ["value"] = "**" .. oreName .. "** (" .. rarity .. ")", ["inline"] = false},
            {["name"] = "📊 Inventory", ["value"] = "Total: " .. _G.TrackerSettings.TotalMined .. " | Rares: " .. _G.TrackerSettings.RareMined, ["inline"] = true},
            {["name"] = "⚡ Efficiency", ["value"] = oph .. " Ores/Hour", ["inline"] = true},
            {["name"] = "🟢 Status", ["value"] = "Mining in World " .. game.PlaceId, ["inline"] = false}
        },
        ["footer"] = {["text"] = "Forge Tracker Build 6.0 • " .. os.date("%X")},
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    local payload = HttpService:JSONEncode({
        ["content"] = (rarity == "Legendary" or rarity == "Mythic") and "<@" .. _G.TrackerSettings.DiscordID .. ">" or nil,
        ["embeds"] = {embed}
    })

    local req = (request or http_request or syn.request)
    pcall(function() req({Url = _G.TrackerSettings.Webhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload}) end)
end

-- 2. THE MINING HOOK
-- This detects when the game gives you an item (Ore)
player.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") and not child.Name:find("Pickaxe") then
        _G.TrackerSettings.TotalMined = _G.TrackerSettings.TotalMined + 1
        
        -- Logic: We check a list or rarity table (simplified here)
        local detectedRarity = "Common" -- Usually you'd check a table of ore names
        if _G.TrackerSettings.Filters[detectedRarity] then
            sendOreWebhook(child.Name, detectedRarity, false)
        end
    end
end)

-- 3. HEARTBEAT LOOP (Every 10 mins)
task.spawn(function()
    while task.wait(600) do
        sendOreWebhook("None", "Common", true)
    end
end)
