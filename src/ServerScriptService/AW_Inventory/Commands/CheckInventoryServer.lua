local PlayerObject = require(script.Parent.Parent.Player.PlayerObject)

return function(context, player)
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then
        return "Player object not found"
    end

    local inventory = playerObj:getInventory()
    if not inventory then
        return "Inventory not found"
    end

    local output = string.format("Inventory for %s:\n", player.Name)
    
    -- List items
    output ..= "Items:\n"
    for itemId, itemData in pairs(inventory.Items) do
        output ..= string.format("- %s x%d\n", itemId, itemData.quantity)
    end
    
    -- List equipped items
    output ..= "\nEquipped:\n"
    for slotId, itemId in pairs(inventory.Equipped) do
        output ..= string.format("Slot %d: %s\n", slotId, itemId)
    end

    return output
end 