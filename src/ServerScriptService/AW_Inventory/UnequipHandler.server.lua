local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerObjectModule = require(script.Parent.Player.PlayerObject)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local SlotHandler = require(game:GetService("ServerScriptService").AW_Inventory.UIHandler.showInventory)

-- Helper function for debug prints
local function debugPrint(message, ...)
    if not SettingsModule.Debug.EnablePrints then return end
    print(string.format("[UnequipHandler] " .. message, ...))
end

-- Helper function to find and destroy equipped tool
local function destroyEquippedTool(player, slotNumber)
    if not player.Character then return end
    
    for _, tool in ipairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("SlotNumber") == slotNumber then
            tool:Destroy()
            return true
        end
    end
    
    -- Also check backpack just in case
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("SlotNumber") == slotNumber then
            tool:Destroy()
            return true
        end
    end
    
    return false
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
    
    -- First destroy any equipped instance of this tool
    destroyEquippedTool(player, tonumber(targetSlot))
    
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