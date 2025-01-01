local PlayerObject = require(script.Parent.Parent.Player.PlayerObject)
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
    if not SettingsModule.Debug.EnablePrints then
        return
    end

    local output = string.format("=== Raw Inventory Data for %s ===\n", player.Name)
    output ..= "{\n"
    output ..= formatTable(inventory, "  ")
    output ..= "}"

    return output
end 