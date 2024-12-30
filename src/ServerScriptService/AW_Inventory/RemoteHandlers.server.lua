local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SlotHandler = require(ReplicatedStorage.AW_Inventory.Modules.SlotHandler)
local PlayerObject = require(script.Parent.Player.PlayerObject)
local ItemModule = require(ReplicatedStorage.AW_Inventory.Modules.ItemModule)

-- Get remotes
local DestroyItem = ReplicatedStorage.AW_Inventory.Remotes.DestroyItem
local GiveItem = ReplicatedStorage.AW_Inventory.Remotes.GiveItem

-- Handle item destruction
DestroyItem.OnServerEvent:Connect(function(player, itemName)
    if not itemName then return end
    
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then return end
    
    -- Get items and remove one
    local items = playerObj:getItemsByName(itemName)
    for uniqueId, _ in pairs(items) do
        if playerObj:removeItemFromInventory(uniqueId) then
            print("[Inventory] Item destroyed:", itemName, "by", player.Name)
            SlotHandler.SlotHandler(player)
            break -- Only remove one item
        end
    end
end)

-- Handle item giving/equipping
GiveItem.OnServerEvent:Connect(function(player, itemName)
    if not itemName then return end
    
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then return end
    
    -- Get items and give one
    local items = playerObj:getItemsByName(itemName)
    for uniqueId, _ in pairs(items) do
        if playerObj:removeItemFromInventory(uniqueId) then
            print("[Inventory] Item equipped:", itemName, "by", player.Name)
            SlotHandler.SlotHandler(player)
            
            -- Handle tool giving
            local tool = ItemModule.GetItemTool(itemName)
            if tool then
                local toolClone = tool:Clone()
                toolClone.Parent = player.Backpack
            end
            
            break -- Only give one item
        end
    end
end) 