--[[
    EquipmentHandler Module
    Handles all equipment-related functionality including equipping, unequipping, and swapping items.
    
    @author Constant
    @version 1.0
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Required modules
local PlayerObjectModule = require(script.Parent.Parent.Player.PlayerObject)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local SlotHandler = require(game:GetService("ServerScriptService").AW_Inventory.UIHandler.showInventory)
local ItemModule = require(ReplicatedStorage.AW_Inventory.Modules.ItemModule)

-- Get the items folder
local ItemsFolder = ReplicatedStorage.AW_Inventory.Items

-- Create remotes if they don't exist
local RemotesFolder = ReplicatedStorage.AW_Inventory.Remotes
local EquipItemRemote = RemotesFolder:FindFirstChild("EquipItem") or Instance.new("RemoteEvent", RemotesFolder)
EquipItemRemote.Name = "EquipItem"
local UnequipItemRemote = RemotesFolder:FindFirstChild("UnequipItem") or Instance.new("RemoteEvent", RemotesFolder)
UnequipItemRemote.Name = "UnequipItem"
local SwapEquippedItemsRemote = RemotesFolder:FindFirstChild("SwapEquippedItems") or Instance.new("RemoteEvent", RemotesFolder)
SwapEquippedItemsRemote.Name = "SwapEquippedItems"
local HotkeyEquipRemote = RemotesFolder:FindFirstChild("HotkeyEquip") or Instance.new("RemoteEvent", RemotesFolder)
HotkeyEquipRemote.Name = "HotkeyEquip"

-- Module table
local EquipmentHandler = {}

--[[
    Helper function for debug prints
    @param message string -- The message to print
    @param ... any -- Additional arguments for string formatting
]]
local function debugPrint(message: string, ...: any)
    if not SettingsModule.Debug.EnablePrints then return end
    print(string.format("[EquipmentHandler] " .. message, ...))
end

--[[
    Helper function to find and destroy equipped tool
    @param player Player -- The player to check
    @param slotNumber number -- The slot number to check
    @return boolean -- Whether a tool was found and destroyed
]]
local function destroyEquippedTool(player: Player, slotNumber: number): boolean
    if not player.Character then return false end
    
    -- Check character
    for _, tool in ipairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("SlotNumber") == slotNumber then
            tool:Destroy()
            return true
        end
    end
    
    -- Check backpack
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("SlotNumber") == slotNumber then
            tool:Destroy()
            return true
        end
    end
    
    return false
end

--[[
    Creates and sets up a tool instance for a player
    @param player Player -- The player to create the tool for
    @param itemName string -- The name of the item
    @param slotNumber number -- The slot number for the tool
    @param itemId string -- The unique ID of the item
    @param itemData table -- Additional data for the item
    @return Tool? -- The created tool or nil if failed
]]
local function createToolInstance(player: Player, itemName: string, slotNumber: number, itemId: string, itemData: table): Tool?
    local itemFolder = ItemsFolder:FindFirstChild(itemName)
    if not itemFolder then return nil end
    
    local toolTemplate = itemFolder.Tool:FindFirstChildOfClass("Tool")
    if not toolTemplate then return nil end
    
    -- Clone and setup the tool
    local tool = toolTemplate:Clone()
    tool.Name = itemName
    
    -- Set attributes
    tool:SetAttribute("SlotNumber", slotNumber)
    tool:SetAttribute("ItemId", itemId)
    tool:SetAttribute("ItemName", itemName)
    
    -- Make tool undroppable
    tool.CanBeDropped = false
    
    -- Clone values from item folder
    for _, child in ipairs(itemFolder:GetChildren()) do
        if child:IsA("ValueBase") then
            local valueClone = child:Clone()
            valueClone.Parent = tool
        end
    end
    
    -- Add custom data
    if itemData and next(itemData) then
        local dataFolder = Instance.new("Folder")
        dataFolder.Name = "Data"
        dataFolder.Parent = tool
        
        for key, value in pairs(itemData) do
            local valueObject = Instance.new("StringValue")
            valueObject.Name = key
            valueObject.Value = tostring(value)
            valueObject.Parent = dataFolder
        end
    end
    
    return tool
end

--[[
    Handles equipping an item to a slot
    @param player Player -- The player equipping the item
    @param slotNumber number -- The slot to equip to
    @param itemId string -- The unique ID of the item to equip
]]
function EquipmentHandler.HandleEquip(player: Player, slotNumber: number, itemId: string)
    debugPrint("Player %s attempting to equip item %s to slot %d", player.Name, itemId, slotNumber)
    
    -- Get player's inventory data
    local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
    if not PlayerObject then return end
    
    local inventory = PlayerObject:getInventory()
    if not inventory then return end
    
    -- Get equipped data
    local equipped = PlayerObject:getEquipped()
    
    -- Check if slot is already occupied
    if equipped[tostring(slotNumber)] then
        debugPrint("Slot %d is already occupied", slotNumber)
        return
    end
    
    -- Find the item in inventory
    local itemData = inventory.Items[itemId]
    if not itemData then
        debugPrint("Item %s not found in player's inventory", itemId)
        return
    end
    
    -- Verify it's a tool type
    if ItemModule.GetItemType(itemData.name) ~= "Tool" then
        debugPrint("Item %s is not a tool type", itemData.name)
        return
    end
    
    -- Store in equipped data
    equipped[tostring(slotNumber)] = {
        id = itemId,
        name = itemData.name,
        data = itemData.data or {}
    }
    PlayerObject:setEquipped(equipped)
    
    -- Remove from inventory
    PlayerObject:removeItemFromInventory(itemId)
    
    -- Update UI
    SlotHandler.SlotHandler(player)
    
    debugPrint("Successfully equipped item %s to slot %d", itemData.name, slotNumber)
end

--[[
    Handles unequipping an item
    @param player Player -- The player unequipping the item
    @param uniqueId string -- The unique ID of the item to unequip
]]
function EquipmentHandler.HandleUnequip(player: Player, uniqueId: string)
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
    
    -- Destroy any equipped instance
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
    
    -- Update UI
    SlotHandler.SlotHandler(player)
    
    debugPrint("Successfully unequipped item %s from slot %s", itemData.name, targetSlot)
end

--[[
    Handles swapping items between equipped slots
    @param player Player -- The player swapping items
    @param fromSlot number -- The source slot number
    @param toSlot number -- The target slot number
]]
function EquipmentHandler.HandleSwap(player: Player, fromSlot: number, toSlot: number)
    debugPrint("Player %s attempting to swap items between slots %d and %d", player.Name, fromSlot, toSlot)
    
    -- Get player's equipped data
    local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
    if not PlayerObject then return end
    
    local equipped = PlayerObject:getEquipped()
    if not equipped then return end
    
    -- Convert slot numbers to strings for table lookup
    local fromSlotStr = tostring(fromSlot)
    local toSlotStr = tostring(toSlot)
    
    -- Get the items in both slots
    local fromItem = equipped[fromSlotStr]
    local toItem = equipped[toSlotStr]
    
    -- Verify the source slot has an item
    if not fromItem then
        debugPrint("No item found in source slot %d", fromSlot)
        return
    end
    
    -- Destroy any equipped tools in both slots
    destroyEquippedTool(player, fromSlot)
    destroyEquippedTool(player, toSlot)
    
    -- Swap the items
    if toItem then
        equipped[fromSlotStr] = toItem
        equipped[toSlotStr] = fromItem
        debugPrint("Swapped items between slots %d and %d", fromSlot, toSlot)
    else
        equipped[toSlotStr] = fromItem
        equipped[fromSlotStr] = nil
        debugPrint("Moved item from slot %d to empty slot %d", fromSlot, toSlot)
    end
    
    -- Update the equipped data
    PlayerObject:setEquipped(equipped)
    
    -- Update UI
    SlotHandler.SlotHandler(player)
    
    debugPrint("Successfully handled swap operation")
end

--[[
    Handles hotkey equipping/unequipping of items
    @param player Player -- The player using the hotkey
    @param slotNumber number -- The slot number to toggle
]]
function EquipmentHandler.HandleHotkeyEquip(player: Player, slotNumber: number)
    local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
    if not PlayerObject then return end
    
    local equipped = PlayerObject:getEquipped()
    local slotData = equipped[tostring(slotNumber)]
    
    -- If there's a tool in this slot
    if slotData then
        -- Check if player already has this tool equipped
        local hasToolEquipped = false
        local currentSlotNumber = nil
        
        if player.Character then
            for _, tool in ipairs(player.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    currentSlotNumber = tool:GetAttribute("SlotNumber")
                    if currentSlotNumber == slotNumber then
                        tool:Destroy()
                        hasToolEquipped = true
                        break
                    elseif currentSlotNumber then
                        -- If a different tool is equipped, ignore this request
                        debugPrint("Player already has a tool equipped in slot %d", currentSlotNumber)
                        return
                    end
                end
            end
        end
        
        -- If tool was equipped, we're unequipping
        if hasToolEquipped then
            debugPrint("Unequipped tool from slot %d", slotNumber)
            return
        end
        
        -- Otherwise, equip the tool
        local tool = createToolInstance(player, slotData.name, slotNumber, slotData.id, slotData.data)
        if tool then
            tool.Parent = player.Character
            
            -- Connect to AncestryChanged to prevent the tool from going to backpack
            tool.AncestryChanged:Connect(function(_, newParent)
                if newParent == player.Backpack then
                    if player.Character then
                        tool.Parent = player.Character
                    else
                        tool:Destroy()
                    end
                end
            end)
            
            debugPrint("Equipped tool to slot %d", slotNumber)
        end
    end
end

-- Connect remote events
EquipItemRemote.OnServerEvent:Connect(EquipmentHandler.HandleEquip)
UnequipItemRemote.OnServerEvent:Connect(EquipmentHandler.HandleUnequip)
SwapEquippedItemsRemote.OnServerEvent:Connect(EquipmentHandler.HandleSwap)
HotkeyEquipRemote.OnServerEvent:Connect(EquipmentHandler.HandleHotkeyEquip)

-- Handle saving equipped items when player leaves
Players.PlayerRemoving:Connect(function(player: Player)
    local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
    if not PlayerObject then return end
    
    local equipped = PlayerObject:getEquipped()
    PlayerObject:setEquipped(equipped)
    debugPrint("Saved equipped items for player %s", player.Name)
end)

return EquipmentHandler 