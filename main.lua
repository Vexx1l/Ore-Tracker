local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Load Data from GitHub
local OreData = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vexx1l/Ore-Tracker/main/OreData.lua"))()

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
    PlaceholderText = "Paste Webhook Here",
    Callback = function(Text) 
        _G.WebhookURL = Text 
        print("Webhook Updated: " .. Text)
    end,
})
WebhookTab:CreateInput({
    Name = "User ID (For Pings)",
    PlaceholderText = "Your Discord ID",
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

-- Improved Webhook Function
local function NotifyOre(oreName, area)
    if _G.WebhookURL == "" or _G.WebhookURL == "YOUR_WEBHOOK_HERE" then 
        warn("Webhook URL is empty! Please set it in the UI.")
        return 
    end
    
    -- Search database for ore info
    local oreInfo = nil
    for areaKey, ores in pairs(OreData) do
        if ores[oreName] then
            oreInfo = ores[oreName]
            area = areaKey -- Auto-detect area if not provided correctly
            break
        end
    end

    if not oreInfo then
        warn("Ore not found in database: " .. tostring(oreName))
        oreInfo = {Rarity = "Unknown", Chance = "1/?", Color = 0xFFFFFF}
    end

    if not _G.EnabledRarities[oreInfo.Rarity] then 
        print("Notification skipped: Rarity " .. oreInfo.Rarity .. " is disabled.")
        return 
    end

    local duration = os.time() - StartTime
    local hours = math.floor(duration / 3600)
    local mins = math.floor((duration % 3600) / 60)
    
    local data = {
        ["content"] = (_G.DiscordID ~= "" and _G.DiscordID ~= "YOUR_ID_HERE") and "<@" .. _G.DiscordID .. ">" or nil,
        ["embeds"] = {{
            ["title"] = "💎 " .. oreInfo.Rarity .. " Ore Found!",
            ["color"] = oreInfo.Color,
            ["fields"] = {
                {["name"] = "📍 Area", ["value"] = "**" .. (area or "Unknown") .. "**", ["inline"] = true},
                {["name"] = "⛏️ Ore", ["value"] = "**" .. oreName .. "**", ["inline"] = true},
                {["name"] = "✨ Rarity", ["value"] = oreInfo.Rarity .. " (" .. oreInfo.Chance .. ")", ["inline"] = true},
                {["name"] = "⏱️ Session", ["value"] = string.format("%02dh %02dm", hours, mins), ["inline"] = true},
                {["name"] = "⚡ Efficiency", ["value"] = OresPerHour .. " Ores/Hour", ["inline"] = true},
                {["name"] = "🟢 Status", ["value"] = "Mining...", ["inline"] = false}
            },
            ["footer"] = {["text"] = "The Forge Tracker • v1.1"}
        }}
    }

    local success, err = pcall(function()
        request({
            Url = _G.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = game:GetService("HttpService"):JSONEncode(data)
        })
    end)

    if success then print("✅ Webhook sent for: " .. oreName) else warn("❌ Webhook failed: " .. err) end
end

-- Detection Logic
-- Note: You may need to verify the path game.ReplicatedStorage.Remotes.MineOre
local RemotePath = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
if RemotePath then
    local MineRemote = RemotePath:FindFirstChild("MineOre") or RemotePath:FindFirstChild("OreMined")
    
    if MineRemote then
        MineRemote.OnClientEvent:Connect(function(oreName, areaName)
            TotalMined = TotalMined + 1
            AreaLabel:Set("Current Area: " .. (areaName or "Detecting..."))
            NotifyOre(oreName, areaName)
        end)
    else
        warn("Could not find the Mining Remote. Detection might not work!")
    end
end

-- Efficiency Loop
spawn(function()
    while task.wait(1) do
        local duration = os.time() - StartTime
        OresPerHour = math.floor(TotalMined / (duration / 3600 + 0.0001))
        StatLabel:Set("Session Stats: " .. string.format("%02dh %02dm", math.floor(duration/3600), math.floor((duration%3600)/60)))
        EffLabel:Set("Efficiency: " .. OresPerHour .. " Ores/Hour")
    end
end)
