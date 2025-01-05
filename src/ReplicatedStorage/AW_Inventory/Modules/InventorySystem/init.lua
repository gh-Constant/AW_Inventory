local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local UIEffects = require(script.UIEffects)
local ViewportHandler = require(script.ViewportHandler)
local HotkeyManager = require(script.HotkeyManager)
local InventoryUIManager = require(script.InventoryUIManager)

local InventorySystem = {}

-- Initialize all necessary components
function InventorySystem.init()
    local player = Players.LocalPlayer
    
    -- Disable default backpack
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    
    -- Initialize UI
    local uiElements = InventoryUIManager.initialize()
    
    -- Setup viewport handling
    ReplicatedStorage.AW_Inventory.Remotes.Viewport.OnClientEvent:Connect(function(viewportFrame, itemName)
        ViewportHandler.setupViewport(viewportFrame, itemName)
    end)
    
    -- Setup hotkey handling
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Handle inventory toggle
        if input.KeyCode == SettingsModule.InventoryUI.ToggleKey then
            InventoryUIManager.toggleInventory(not InventoryUIManager.isOpen(), uiElements)
            return
        end
        
        -- Handle hotkey slots
        local slotNumber = HotkeyManager.numberKeys[input.KeyCode]
        if slotNumber then
            local hotbarGui = player.PlayerGui:WaitForChild("Hotbar")
            local hotbarSlotsFrame = hotbarGui:WaitForChild("Main"):WaitForChild("SlotsFrame")
            local slot = hotbarSlotsFrame:FindFirstChild("Slot" .. slotNumber)
            
            if slot then
                if not HotkeyManager.hasItemInSlot(slot) then
                    HotkeyManager.cleanupSlotState(slot)
                    return
                end

                if HotkeyManager.currentlyEquippedSlot == slot or not HotkeyManager.currentlyEquippedSlot then
                    ReplicatedStorage.AW_Inventory.Remotes.HotkeyEquip:FireServer(slotNumber)
                    HotkeyManager.playHotbarEffect(slotNumber)
                end
            end
        end
    end)
    
    -- Setup cleanup
    player.CharacterRemoving:Connect(function()
        InventoryUIManager.toggleInventory(false, uiElements)
        HotkeyManager.cleanup()
    end)
    
    -- Start periodic slot cleanup
    task.spawn(function()
        while true do
            task.wait(1)
            HotkeyManager.checkAndCleanupAllSlots()
        end
    end)
end

return InventorySystem 