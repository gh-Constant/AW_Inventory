local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local InventoryDisplay = require(game.StarterGui.AW_InventoryUI.InventoryDisplay)

local player = Players.LocalPlayer

-- Update inventory display when needed
local function updateInventory()
    InventoryDisplay:UpdateInventory(player)
end

-- Example: Update every 5 seconds
while task.wait(5) do
    updateInventory()
end 