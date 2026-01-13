local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Load your GitHub Data
local OreData = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vexx1l/Ore-Tracker/refs/heads/main/OreData.lua"))()

-- Session Variables
local StartTime = os.time()
local TotalMined = 0
local OresPerHour = 0

-- Configuration State
_G.WebhookURL = ""
_G.DiscordID = ""
_G.EnabledRarities = {
    ["Common"] = false,
    ["Uncommon"] = false,
    ["Rare"] = false,
    ["Epic"] = true,
    ["Legendary"] = true,
    ["Mythical"] = true,
    ["Divine"] = true,
    ["Relic"] = true
}

local Window = Rayfield:CreateWindow({
    Name = "The Forge | Ultimate Ore Tracker",
    LoadingTitle = "Loading Data...",
    LoadingSubtitle = "by Vexx1l",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TheForgeTracker",
        FileName = "Config"
    }
})

-- Stats Tab
local MainTab = Window:CreateTab("📊 Session", 4483362458)
local AreaLabel = MainTab:CreateLabel("Current Area: Detecting...")
local StatLabel = MainTab:CreateLabel("Session Stats: 00h 00m")
local EffLabel = MainTab:CreateLabel("Efficiency: 0 Ores/Hour")

-- Webhook Tab
local WebhookTab = Window:CreateTab("🔗 Webhook", 4483362458)
WebhookTab:CreateInput({
    Name = "Discord Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Callback = function(Text) _G.WebhookURL = Text end,
})
WebhookTab:CreateInput({
    Name = "User ID (For Pings)",
    PlaceholderText = "1234567890...",
    Callback = function(Text) _G.DiscordID = Text end,
})

-- Filters Tab
local FilterTab = Window:CreateTab("🎯 Filters", 4483362458)
for Rarity, Val in pairs(_G.EnabledRarities) do
    FilterTab:CreateToggle({
        Name = "Notify " .. Rarity,
        CurrentValue = Val,
        Callback = function(Value) _G.EnabledRarities[Rarity] = Value end,
    })
end

-- Function to handle Webhook Sending
local function NotifyOre(oreName, area)
    if _G.WebhookURL == "" then return end
    
    local oreInfo
    if OreData[area] and OreData[area][oreName] then
        oreInfo = OreData[area][oreName]
    else
        -- Fallback if ore isn't in DB
        oreInfo = {Rarity = "Unknown", Chance = "1/?", Color = 0xFFFFFF}
    end

    if not _G.EnabledRarities[oreInfo.Rarity] then return end

    local duration = os.time() - StartTime
    local hours = math.floor(duration / 3600)
    local mins = math.floor((duration % 3600) / 60)
    
    local data = {
        ["content"] = _G.DiscordID ~= "" and "<@" .. _G.DiscordID .. ">" or nil,
        ["embeds"] = {{
            ["title"] = "💎 Rare Ore Mined!",
            ["color"] = oreInfo.Color,
            ["fields"] = {
                {["name"] = "📍 Area", ["value"] = "**" .. area .. "**", ["inline"] = true},
                {["name"] = "⛏️ Ore", ["value"] = "**" .. oreName .. "**", ["inline"] = true},
                {["name"] = "✨ Rarity", ["value"] = oreInfo.Rarity .. " (" .. oreInfo.Chance .. ")", ["inline"] = true},
                {["name"] = "⏱️ Session", ["value"] = string.format("%02dh %02dm", hours, mins), ["inline"] = true},
                {["name"] = "⚡ Efficiency", ["value"] = OresPerHour .. " Ores/Hour", ["inline"] = true},
                {["name"] = "🟢 Status", ["value"] = "Active", ["inline"] = false}
            },
            ["footer"] = {["text"] = "The Forge Tracker • Powered by Vexx1l"}
        }}
    }

    request({
        Url = _G.WebhookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = game:GetService("HttpService"):JSONEncode(data)
    })
end

-- Core Tracking Logic
spawn(function()
    while task.wait(1) do
        local duration = os.time() - StartTime
        local hours = duration / 3600
        local h = math.floor(duration / 3600)
        local m = math.floor((duration % 3600) / 60)
        
        OresPerHour = math.floor(TotalMined / math.max(hours, 0.01))
        
        StatLabel:Set("Session Stats: " .. string.format("%02dh %02dm", h, m))
        EffLabel:Set("Efficiency: " .. OresPerHour .. " Ores/Hour")
    end
end)

-- Detect Ore Mining (Adjust Remote Name based on game)
local Remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("MineOre") -- Example name
Remote.OnClientEvent:Connect(function(oreName, areaName)
    TotalMined = TotalMined + 1
    AreaLabel:Set("Current Area: " .. areaName)
    NotifyOre(oreName, areaName)
end)

Rayfield:Notify({
    Title = "Tracker Active",
    Content = "The Forge Ore Tracker is now running.",
    Duration = 5,
    Image = 4483362458,
})
