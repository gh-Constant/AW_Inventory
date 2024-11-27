local PlayerObject = require(script.Parent.Parent.PlayerObject)

return function(context, player, itemId, quantity)
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then
        return "Player object not found"
    end

    local success = playerObj:removeItemFromInventory(itemId, quantity)
    if success then
        return string.format("Removed %d %s from %s's inventory", quantity, itemId, player.Name)
    else
        return "Failed to remove item"
    end
end 