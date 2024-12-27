local PlayerObject = require(script.Parent.Parent.Player.PlayerObject)
local ItemModule = require(game.ReplicatedStorage.AW_Inventory.Modules.ItemModule)
local HttpService = game:GetService("HttpService")

return function(context, player, itemId: string, quantity: number, propertiesJson: string?)
    -- Validate input
    quantity = tonumber(quantity) or 1
    if quantity < 1 then
        return "Quantity must be at least 1"
    end

    -- Parse properties from JSON if provided
    local properties = {}
    if propertiesJson then
        local success, result = pcall(function()
            return HttpService:JSONDecode(propertiesJson)
        end)
        if not success then
            return "Invalid properties JSON format"
        end
        properties = result
    end

    -- Check if item exists and warn if it doesn't
    if not ItemModule.ItemExists(itemId) then
        return string.format("Item '%s' does not exist in ItemModule", itemId)
    end

    -- Get player object
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then
        return "Player object not found"
    end

    -- Add items
    local addedIds = {}
    for i = 1, quantity do
        local uniqueId = playerObj:addItemToInventory(itemId, properties)
        if uniqueId then
            table.insert(addedIds, uniqueId)
        end
    end

    if #addedIds == 0 then
        return "Failed to add items"
    end

    -- Return success message
    if #addedIds == 1 then
        return string.format("Added %s (ID: %s)", itemId, addedIds[1])
    else
        return string.format("Added %dx %s (IDs: %s)", #addedIds, itemId, table.concat(addedIds, ", "))
    end
end 