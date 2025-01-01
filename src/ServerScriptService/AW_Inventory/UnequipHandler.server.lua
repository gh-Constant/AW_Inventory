local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerObjectModule = require(script.Parent.Player.PlayerObject)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local SlotHandler = require(ReplicatedStorage.AW_Inventory.Modules.SlotHandler)

-- Helper function for debug prints
local function debugPrint(message, ...)
    if not SettingsModule.Debug.EnablePrints then return end
    print(string.format("[UnequipHandler] " .. message, ...))
end

-- Setup remote event handler
local UnequipItemRemote = ReplicatedStorage.AW_Inventory.Remotes.UnequipItem

UnequipItemRemote.OnServerEvent:Connect(function(player, uniqueId)
    debugPrint("Player %s attempting to unequip item with ID: %s", player.Name, uniqueId)
    
    -- Get player's inventory data
    local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
    if not PlayerObject then return end
    
    local inventory = PlayerObject:getInventory()
    if not inventory then return end
    
    -- Get equipped data
    local equipped = PlayerObject:getEquipped()
    
    -- Find which slot has this item
    local targetSlot = nil
    local itemData = nil
    for slotNumber, data in pairs(equipped) do
        if data.id == uniqueId then
            targetSlot = slotNumber
            itemData = data
            break
        end
    end
    
    if not targetSlot or not itemData then
        debugPrint("Item %s not found in equipped slots", uniqueId)
        return
    end
    
    -- Remove from equipped slots
    equipped[targetSlot] = nil
    PlayerObject:setEquipped(equipped)
    
    -- Add back to inventory
    local newUniqueId = PlayerObject:addItemToInventory(itemData.name, itemData.data)
    if not newUniqueId then
        debugPrint("Failed to add item back to inventory")
        return
    end
    
    -- Update the inventory UI
    SlotHandler.SlotHandler(player)
    
    debugPrint("Successfully unequipped item %s from slot %s for player %s", itemData.name, targetSlot, player.Name)
end) 