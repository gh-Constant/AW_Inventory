local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIEffects = require(ReplicatedStorage.AW_Inventory.Modules.UIEffects)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

local HotkeyManager = {}

HotkeyManager.numberKeys = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5,
    [Enum.KeyCode.Six] = 6,
    [Enum.KeyCode.Seven] = 7,
    [Enum.KeyCode.Eight] = 8,
    [Enum.KeyCode.Nine] = 9,
}

local slotHighlights = {}
local currentlyEquippedSlot = nil

function HotkeyManager.hasItemInSlot(slot)
    for _, child in ipairs(slot:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("Item") then
            return true
        end
    end
    return false
end

function HotkeyManager.cleanupSlotState(slot)
    if slotHighlights[slot] then
        slotHighlights[slot]:Destroy()
        slotHighlights[slot] = nil
    end
    
    if currentlyEquippedSlot == slot then
        currentlyEquippedSlot = nil
    end
    
    local equippedValue = slot:FindFirstChild("Equipped")
    if equippedValue and equippedValue:IsA("BoolValue") then
        equippedValue:Destroy()
    end
end

function HotkeyManager.toggleHighlight(slot)
    if not HotkeyManager.hasItemInSlot(slot) then
        HotkeyManager.cleanupSlotState(slot)
        return false
    end

    if slotHighlights[slot] then
        HotkeyManager.cleanupSlotState(slot)
        return false
    else
        if currentlyEquippedSlot and currentlyEquippedSlot ~= slot then
            HotkeyManager.cleanupSlotState(currentlyEquippedSlot)
        end
        slotHighlights[slot] = UIEffects.createHighlight(slot)
        currentlyEquippedSlot = slot
        return true
    end
end

function HotkeyManager.playHotbarEffect(slotNumber)
    local player = Players.LocalPlayer
    local hotbarGui = player.PlayerGui:WaitForChild("Hotbar")
    local hotbarSlotsFrame = hotbarGui:WaitForChild("Main"):WaitForChild("SlotsFrame")
    local slot = hotbarSlotsFrame:FindFirstChild("Slot" .. slotNumber)
    
    if slot then
        if not HotkeyManager.hasItemInSlot(slot) then
            HotkeyManager.cleanupSlotState(slot)
            return
        end

        if currentlyEquippedSlot == slot then
            UIEffects.createEquipEffect(slot)
            HotkeyManager.toggleHighlight(slot)
            return
        end
        
        if currentlyEquippedSlot and currentlyEquippedSlot ~= slot then
            return
        end
        
        UIEffects.createEquipEffect(slot)
        HotkeyManager.toggleHighlight(slot)
    end
end

function HotkeyManager.checkAndCleanupAllSlots()
    local player = Players.LocalPlayer
    local hotbarGui = player.PlayerGui:WaitForChild("Hotbar")
    local hotbarSlotsFrame = hotbarGui:WaitForChild("Main"):WaitForChild("SlotsFrame")
    
    for _, slot in ipairs(hotbarSlotsFrame:GetChildren()) do
        if slot:IsA("ImageLabel") and slot.Name:match("^Slot%d+$") then
            if not HotkeyManager.hasItemInSlot(slot) then
                HotkeyManager.cleanupSlotState(slot)
            end
        end
    end
end

function HotkeyManager.cleanup()
    currentlyEquippedSlot = nil
    for slot, highlight in pairs(slotHighlights) do
        highlight:Destroy()
    end
    slotHighlights = {}
end

return HotkeyManager 