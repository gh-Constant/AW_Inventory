local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerObjectModule = require(script.Parent.Player.PlayerObject)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local SlotHandler = require(game:GetService("ServerScriptService").AW_Inventory.UIHandler.showInventory)


-- Get the items folder
local ItemsFolder = ReplicatedStorage.AW_Inventory.Items

-- Helper function for debug prints
local function debugPrint(message, ...)
    if not SettingsModule.Debug.EnablePrints then return end
    print(string.format("[SwapHandler] " .. message, ...))
end

-- Helper function to check if a tool in a slot is currently equipped
local function isToolEquippedInSlot(player, slotNumber)
    if not player.Character then return false end
    
    for _, tool in ipairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("SlotNumber") == slotNumber then
            return true
        end
    end
    return false
end

-- Helper function to destroy equipped tool in a specific slot
local function destroyEquippedToolInSlot(player, slotNumber)
    if not player.Character then 
        debugPrint("No character found for player %s", player.Name)
        return 
    end
    
    for _, tool in ipairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("SlotNumber") == slotNumber then
            debugPrint("Destroying tool %s in slot %d", tool.Name, slotNumber)
            tool:Destroy()
            return true
        end
    end
    debugPrint("No tool found in slot %d to destroy", slotNumber)
    return false
end

-- Helper function to equip a tool from equipped data
local function equipToolFromData(player, slotNumber, itemData)
    if not player.Character then 
        debugPrint("No character found for player %s", player.Name)
        return 
    end
    
    local itemFolder = ItemsFolder:FindFirstChild(itemData.name)
    if not itemFolder then 
        debugPrint("Item folder not found for %s", itemData.name)
        return 
    end
    
    local toolTemplate = itemFolder.Tool:FindFirstChildOfClass("Tool")
    if not toolTemplate then 
        debugPrint("Tool template not found for %s", itemData.name)
        return 
    end
    
    debugPrint("Creating tool %s for slot %d", itemData.name, slotNumber)
    
    -- Clone and setup the tool
    local tool = toolTemplate:Clone()
    tool.Name = itemData.name
    
    -- Set attributes
    tool:SetAttribute("SlotNumber", slotNumber)
    tool:SetAttribute("ItemId", itemData.id)
    tool:SetAttribute("ItemName", itemData.name)
    
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
    if itemData.data and next(itemData.data) then
        local dataFolder = Instance.new("Folder")
        dataFolder.Name = "Data"
        dataFolder.Parent = tool
        
        for key, value in pairs(itemData.data) do
            local valueObject = Instance.new("StringValue")
            valueObject.Name = key
            valueObject.Value = tostring(value)
            valueObject.Parent = dataFolder
        end
    end
    
    debugPrint("Equipping tool %s to slot %d", tool.Name, slotNumber)
    -- Give tool to character
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
    
    return true
end

-- Setup remote event handler
local SwapEquippedItemsRemote = ReplicatedStorage.AW_Inventory.Remotes.SwapEquippedItems

SwapEquippedItemsRemote.OnServerEvent:Connect(function(player, fromSlot, toSlot)
    debugPrint("Player %s attempting to swap items between slots %d and %d", player.Name, fromSlot, toSlot)
    
    -- Get player's equipped data
    local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
    if not PlayerObject then 
        debugPrint("PlayerObject not found for %s", player.Name)
        return 
    end
    
    local equipped = PlayerObject:getEquipped()
    if not equipped then 
        debugPrint("No equipped data found for %s", player.Name)
        return 
    end
    
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
    
    -- Check if either tool is currently equipped
    local isFromToolEquipped = isToolEquippedInSlot(player, fromSlot)
    local isToToolEquipped = isToolEquippedInSlot(player, toSlot)
    
    -- Prevent swapping if either item is equipped
    if isFromToolEquipped or isToToolEquipped then
        debugPrint("Cannot swap items - one or both items are currently equipped")
        return
    end
    
    -- Swap the items in the equipped data
    if toItem then
        -- If both slots have items, swap them
        equipped[fromSlotStr] = toItem
        equipped[toSlotStr] = fromItem
        debugPrint("Swapped items between slots %d and %d", fromSlot, toSlot)
    else
        -- If target slot is empty, just move the item
        equipped[toSlotStr] = fromItem
        equipped[fromSlotStr] = nil
        debugPrint("Moved item from slot %d to empty slot %d", fromSlot, toSlot)
    end
    
    -- Update the equipped data
    PlayerObject:setEquipped(equipped)
    
    -- Update the inventory UI
    SlotHandler.SlotHandler(player)
    
    debugPrint("Successfully handled swap operation for player %s", player.Name)
end) 