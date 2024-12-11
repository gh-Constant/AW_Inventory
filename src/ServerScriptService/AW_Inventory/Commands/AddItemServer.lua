local PlayerObject = require(script.Parent.Parent.PlayerObject)

return function(context, player, itemId, quantity, itemData)
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then
        return "Player object not found"
    end

    local success = playerObj:addItemToInventory(itemId, quantity, itemData)
    if success then
        return string.format("Added %d %s to %s's inventory", quantity, itemId, player.Name)
    else
        return "Failed to add item"
    end
end 