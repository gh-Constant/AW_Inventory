local PlayerObject = require(script.Parent.Parent.Player.PlayerObject)
local ItemModule = require(game.ReplicatedStorage.AW_Inventory.Modules.ItemModule)
local SettingsModule = require(game.ReplicatedStorage.AW_Inventory.SettingsModule)

-- Helper function to format tables
local function formatTable(tbl, indent)
    indent = indent or ""
    local result = ""
    
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            result ..= string.format("%s%s: {\n%s%s}\n", indent, tostring(k), formatTable(v, indent.."  "), indent)
        else
            result ..= string.format("%s%s: %s\n", indent, tostring(k), tostring(v))
        end
    end
    
    return result
end

return function(context, player)
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then
        return "Player object not found"
    end

    local inventory = playerObj:getInventory()
    if not inventory then
        return "Inventory not found"
    end


    -- If prints are disabled, return without output
    if not SettingsModule.Debug.EnablePrints or not SettingsModule.Debug.Commands.CheckInventory.EnablePrints then
        return
    end

    local output = string.format("=== Inventory for %s ===\n", player.Name)
    
    -- List items with detailed information
    output ..= "\n📦 Items:\n"
    for uniqueId, itemData in pairs(inventory.Items) do
        -- Get item info if it exists
        local itemInfo = ItemModule.GetItemData(itemData.name)
        local itemName = itemData.name
        
        if SettingsModule.Debug.Commands.CheckInventory.DetailedPrints then
            output ..= string.format("• %s\n", itemName)
            output ..= string.format("  UniqueID: %s\n", uniqueId)
            
            -- Add additional item properties if they exist
            if itemData.data then
                output ..= "  Properties:\n"
                for prop, value in pairs(itemData.data) do
                    output ..= string.format("    %s: %s\n", prop, tostring(value))
                end
            end

            -- Add item info if available
            if itemInfo then
                if itemInfo.rarity then
                    output ..= string.format("  Rarity: %s\n", itemInfo.rarity)
                end
                if itemInfo.type then
                    output ..= string.format("  Type: %s\n", itemInfo.type)
                end
                if itemInfo.description then
                    output ..= string.format("  Description: %s\n", itemInfo.description)
                end
            end
        else
            -- Simple output
            output ..= string.format("• %s\n", itemName)
        end
    end
    
    -- List equipped items with slot information
    output ..= "\n⚔️ Equipped Items:\n"
    for slotId, itemId in pairs(inventory.Equipped) do
        local itemData = inventory.Items[itemId]
        local slotName = SlotHandler.GetSlotName(slotId)
        
        if itemData then
            if SettingsModule.Debug.Commands.CheckInventory.DetailedPrints then
                output ..= string.format("• Slot %d (%s): %s\n", 
                    slotId, 
                    slotName or "Unknown Slot", 
                    itemData.name
                )
                output ..= string.format("  UniqueID: %s\n", itemId)
            else
                output ..= string.format("• Slot %d (%s): %s\n", 
                    slotId, 
                    slotName or "Unknown Slot", 
                    itemData.name
                )
            end
        end
    end

    -- Add raw inventory data section only if detailed prints are enabled
    if SettingsModule.Debug.Commands.CheckInventory.DetailedPrints then
        output ..= "\n🔧 Raw Inventory Data:\n"
        output ..= "{\n"
        output ..= formatTable(inventory, "  ")
        output ..= "}"
    end

    return output
end 