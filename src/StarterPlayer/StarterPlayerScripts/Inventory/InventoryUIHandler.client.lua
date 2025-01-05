local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local InventoryUIManager = require(ReplicatedStorage.AW_Inventory.Modules.InventoryUIManager)

local player = Players.LocalPlayer

-- Initialize UI elements
local uiElements = InventoryUIManager.initialize()

-- Connect to input events
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == SettingsModule.InventoryUI.ToggleKey then
        InventoryUIManager.toggleInventory(not InventoryUIManager.isOpen(), uiElements)
    end
end)

-- Clean up
player.CharacterRemoving:Connect(function()
    InventoryUIManager.toggleInventory(false, uiElements)
end) 