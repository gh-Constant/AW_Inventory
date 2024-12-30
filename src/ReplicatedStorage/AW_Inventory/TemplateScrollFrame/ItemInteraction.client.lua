local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

-- Get remotes
local DestroyItem = ReplicatedStorage.AW_Inventory.Remotes.DestroyItem
local GiveItem = ReplicatedStorage.AW_Inventory.Remotes.GiveItem

local button = script.Parent.Button
local itemValue = script.Parent.Item
local background = script.Parent.Background

-- Handle item rarity gradient
local function updateRarityGradient()
    local itemName = itemValue.Value
    if not itemName then return end
    
    local itemFolder = ReplicatedStorage.AW_Inventory.Items:FindFirstChild(itemName)
    if not itemFolder or not itemFolder:FindFirstChild("Rarity") then return end
    
    local rarity = itemFolder.Rarity.Value
    local rarityGradient = SettingsModule.RarityGradient[rarity]
    if rarityGradient then
        local gradientClone = rarityGradient:Clone()
        gradientClone.Parent = background
    end
end

-- Initialize rarity gradient
updateRarityGradient()

-- Destroy item on right click
button.MouseButton2Click:Connect(function()
    local itemName = itemValue.Value
    if not itemName then return end
    
    -- Fire server to destroy item
    DestroyItem:FireServer(itemName)
end)

-- Give/equip item on left click
button.MouseButton1Click:Connect(function()
    local itemName = itemValue.Value
    if not itemName then return end
    
    -- Fire server to give item
    GiveItem:FireServer(itemName)
end) 