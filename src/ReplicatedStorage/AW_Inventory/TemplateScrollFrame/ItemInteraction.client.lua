local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

-- Get remotes
local DestroyItem = ReplicatedStorage.AW_Inventory.Remotes.DestroyItem
local GiveItem = ReplicatedStorage.AW_Inventory.Remotes.GiveItem

local button = script.Parent.Button
local itemValue = script.Parent.Item

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