local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerObjectModule = require(script.Parent.Player.PlayerObject)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

-- Get the items folder
local ItemsFolder = ReplicatedStorage.AW_Inventory.Items

-- Helper function for debug prints
local function debugPrint(message, ...)
    if not SettingsModule.Debug.EnablePrints then return end
    print(string.format("[EquipHandler] " .. message, ...))
end

-- Setup remote event handler
local EquipItemRemote = ReplicatedStorage.AW_Inventory.Remotes.EquipItem

EquipItemRemote.OnServerEvent:Connect(function(player, slotNumber, itemId)
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
    
    -- Find the item folder and verify it's a tool type
    local itemFolder = ItemsFolder:FindFirstChild(itemData.name)
    if not itemFolder then return end
    
    local itemType = itemFolder:FindFirstChild("Type")
    if not itemType or itemType.Value ~= "Tool" then
        debugPrint("Item %s is not a tool type", itemData.name)
        return
    end
    
    -- Store in equipped data under the slot number
    equipped[tostring(slotNumber)] = {
        id = itemId,
        name = itemData.name,
        data = itemData.data or {}
    }
    PlayerObject:setEquipped(equipped)
    
    -- Remove the item from inventory
    PlayerObject:removeItemFromInventory(itemId)
    
    debugPrint("Successfully equipped item %s to slot %d for player %s", itemData.name, slotNumber, player.Name)
end)

ReplicatedStorage.AW_Inventory.Remotes.HotkeyEquip.OnServerEvent:Connect(function(player, slotNumber)
    local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
    if not PlayerObject then return end
    
    local equipped = PlayerObject:getEquipped()
    local slotData = equipped[tostring(slotNumber)]
    
    -- If there's a tool in this slot
    if slotData then
        -- Check if player already has this tool equipped
        local hasToolEquipped = false
        if player.Character then
            for _, tool in ipairs(player.Character:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("SlotNumber") == slotNumber then
                    tool:Destroy()
                    hasToolEquipped = true
                    break
                end
            end
        end
        
        -- If tool was equipped, we're unequipping
        if hasToolEquipped then
            debugPrint("Unequipped tool from slot %d", slotNumber)
            return
        end
        
        -- Otherwise, equip the tool
        local itemFolder = ItemsFolder:FindFirstChild(slotData.name)
        if not itemFolder then return end
        
        local toolTemplate = itemFolder.Tool:FindFirstChildOfClass("Tool")
        if not toolTemplate then return end
        
        -- Clone and setup the tool
        local tool = toolTemplate:Clone()
        tool.Name = slotData.name
        
        -- Set attributes
        tool:SetAttribute("SlotNumber", slotNumber)
        tool:SetAttribute("ItemId", slotData.id)
        tool:SetAttribute("ItemName", slotData.name)
        
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
        if slotData.data and next(slotData.data) then
            local dataFolder = Instance.new("Folder")
            dataFolder.Name = "Data"
            dataFolder.Parent = tool
            
            for key, value in pairs(slotData.data) do
                local valueObject = Instance.new("StringValue")
                valueObject.Name = key
                valueObject.Value = tostring(value)
                valueObject.Parent = dataFolder
            end
        end
        
        -- Give tool directly to character instead of backpack
        if player.Character then
            tool.Parent = player.Character
        end
        debugPrint("Equipped tool to slot %d", slotNumber)
    end
end)

-- Handle saving equipped items when player leaves
Players.PlayerRemoving:Connect(function(player)
    local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
    if not PlayerObject then return end
    
    local equipped = PlayerObject:getEquipped()
    -- No need to modify equipped data as it's already in the correct format
    PlayerObject:setEquipped(equipped)
    debugPrint("Saved equipped items for player %s", player.Name)
end)

-- Debug print equipped data every 5 seconds
local function startEquippedDebugPrints()
    task.spawn(function()
        while true do
            task.wait(5)
            for _, player in ipairs(Players:GetPlayers()) do
                local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
                if PlayerObject then
                    local equipped = PlayerObject:getEquipped()
                    if equipped then
                        print("=== Equipped Data for", player.Name, "===")
                        for slotNumber, itemData in pairs(equipped) do
                            if itemData and itemData.name and itemData.id then
                                print(string.format("Slot %s: %s (ID: %s)", 
                                    tostring(slotNumber), 
                                    tostring(itemData.name), 
                                    tostring(itemData.id)
                                ))
                                if itemData.data then
                                    print("  Data:", game:GetService("HttpService"):JSONEncode(itemData.data))
                                end
                            end
                        end
                        print("===================================")
                    end
                end
            end
        end
    end)
end

startEquippedDebugPrints() 