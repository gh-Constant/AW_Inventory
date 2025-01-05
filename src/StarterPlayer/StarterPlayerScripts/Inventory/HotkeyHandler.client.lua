local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local HotkeyManager = require(ReplicatedStorage.AW_Inventory.Modules.HotkeyManager)
local HotkeyRemote = ReplicatedStorage.AW_Inventory.Remotes.HotkeyEquip

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local slotNumber = HotkeyManager.numberKeys[input.KeyCode]
    if slotNumber then
        local player = Players.LocalPlayer
        local hotbarGui = player.PlayerGui:WaitForChild("Hotbar")
        local hotbarSlotsFrame = hotbarGui:WaitForChild("Main"):WaitForChild("SlotsFrame")
        local slot = hotbarSlotsFrame:FindFirstChild("Slot" .. slotNumber)
        
        if slot then
            if not HotkeyManager.hasItemInSlot(slot) then
                HotkeyManager.cleanupSlotState(slot)
                return
            end

            if HotkeyManager.currentlyEquippedSlot == slot or not HotkeyManager.currentlyEquippedSlot then
                HotkeyRemote:FireServer(slotNumber)
                HotkeyManager.playHotbarEffect(slotNumber)
            end
        end
    end
end)

-- Clean up highlights when player leaves
Players.LocalPlayer.CharacterRemoving:Connect(function()
    HotkeyManager.cleanup()
end)

-- Periodically check and clean up slot states
task.spawn(function()
    while true do
        task.wait(1)
        HotkeyManager.checkAndCleanupAllSlots()
    end
end) 