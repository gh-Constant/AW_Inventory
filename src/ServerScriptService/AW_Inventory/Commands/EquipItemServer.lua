local PlayerObject = require(script.Parent.Parent.Player.PlayerObject)

return function(context, player, itemId, slotId)
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then
        return "Player object not found"
    end

    local success = playerObj:equipItem(itemId, slotId)
    if success then
        return string.format("Equipped %s to slot %d for %s", itemId, slotId, player.Name)
    else
        return "Failed to equip item"
    end
end 