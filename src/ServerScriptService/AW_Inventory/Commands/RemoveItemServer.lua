local PlayerObject = require(script.Parent.Parent.Player.PlayerObject)
local ItemModule = require(game.ReplicatedStorage.AW_Inventory.Modules.ItemModule)

return function(context, player, itemId: string, quantity: number?)
    -- Validate input
    quantity = tonumber(quantity) or 1
    if quantity < 1 then
        return "Quantity must be at least 1"
    end

    -- Get player object
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then
        return "Player object not found"
    end

    local inventory = playerObj:getInventory()
    if not inventory then
        return "Inventory not found"
    end

    -- Find all instances of the specified item
    local itemInstances = {}
    for uniqueId, itemData in pairs(inventory.Items) do
        if itemData.name == itemId then
            table.insert(itemInstances, uniqueId)
        end
    end

    if #itemInstances == 0 then
        return string.format("No %s found in inventory", itemId)
    end

    -- Remove the requested number of items
    local removedCount = 0
    for i = 1, math.min(quantity, #itemInstances) do
        local uniqueId = itemInstances[i]
        if playerObj:removeItem(uniqueId) then
            removedCount += 1
        end
    end

    if removedCount == 0 then
        return "Failed to remove any items"
    elseif removedCount < quantity then
        return string.format("Only removed %d of %d requested %s", removedCount, quantity, itemId)
    else
        return string.format("Removed %dx %s", removedCount, itemId)
    end
end 