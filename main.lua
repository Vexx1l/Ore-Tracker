local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Load Data from GitHub (Ensure these links are the RAW versions)
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
    Callback = function(Text) _G.WebhookURL = Text end,
})
WebhookTab:CreateInput({
    Name = "User ID (For Pings)",
    PlaceholderText = "Your Discord ID",
    Callback = function(Text) _G.DiscordID = Text end,
})
WebhookTab:CreateButton({
    Name = "🚀 Send Test Notification",
    Callback = function()
        if _G.WebhookURL == "" then
            Rayfield:Notify({Title = "Error", Content = "Please enter a Webhook URL!", Duration = 5})
            return
        end
        -- Test Notification call
        NotifyOre("Test Crystal", "Development Zone", true)
    end,
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

-- Webhook Logic
function NotifyOre(oreName, area, isTest)
    if _G.WebhookURL == "" then return end
    
    local oreInfo = nil
    -- Search database for the ore
    for areaKey, ores in pairs(OreData) do
        if ores[oreName] then
            oreInfo = ores[oreName]
            area = areaKey
            break
        end
    end

    -- Fallback for Test or Unknown
    if isTest then
        oreInfo = {Rarity = "Divine", Chance = "1/1,000,000", Color = 0x9400D3}
        oreName = "TEST NOTIFICATION"
    elseif not oreInfo then
        oreInfo = {Rarity = "Unknown", Chance = "1/?", Color = 0xFFFFFF}
    end

    if not isTest and not _G.EnabledRarities[oreInfo.Rarity] then return end

    local duration = os.time() - StartTime
    local h = math.floor(duration / 3600)
    local m = math.floor((duration % 3600) / 60)
    
    local data = {
        ["content"] = _G.DiscordID ~= "" and "<@" .. _G.DiscordID .. ">" or nil,
        ["embeds"] = {{
            ["title"] = "💎 Rare Ore Mined!",
            ["color"] = oreInfo.Color,
            ["fields"] = {
                {["name"] = "📍 Area", ["value"] = "**" .. area .. "**", ["inline"] = true},
                {["name"] = "⛏️ Ore", ["value"] = "**" .. oreName .. "**", ["inline"] = true},
                {["name"] = "✨ Rarity", ["value"] = oreInfo.Rarity .. " (" .. oreInfo.Chance .. ")", ["inline"] = true},
                {["name"] = "⏱️ Session Stats", ["value"] = string.format("%02dh %02dm", h, m), ["inline"] = true},
                {["name"] = "⚡ Efficiency", ["value"] = OresPerHour .. " Ores/Hour", ["inline"] = true},
                {["name"] = "🟢 Status", ["value"] = "Mining...", ["inline"] = false}
            },
            ["footer"] = {["text"] = "The Forge Tracker • by Vexx1l"}
        }}
    }

    request({
        Url = _G.WebhookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = game:GetService("HttpService"):JSONEncode(data)
    })
end

-- Detection Logic
local Remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("MineOre")
Remote.OnClientEvent:Connect(function(oreName, areaName)
    TotalMined = TotalMined + 1
    AreaLabel:Set("Current Area: " .. tostring(areaName))
    NotifyOre(oreName, areaName)
end)

-- Stats Loop
spawn(function()
    while task.wait(1) do
        local duration = os.time() - StartTime
        OresPerHour = math.floor(TotalMined / (duration / 3600 + 0.001))
        StatLabel:Set("Session Stats: " .. string.format("%02dh %02dm", math.floor(duration/3600), math.floor((duration%3600)/60)))
        EffLabel:Set("Efficiency: " .. OresPerHour .. " Ores/Hour")
    end
end)
