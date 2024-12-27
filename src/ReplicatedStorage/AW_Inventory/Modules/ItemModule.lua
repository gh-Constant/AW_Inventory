local ItemModule = {}

local Items = game.ReplicatedStorage.AW_Inventory.Items

--[=[
    Gets the item data folder from ReplicatedStorage
    @param itemName string -- The name of the item
    @return Instance? -- The item's folder or nil if not found
]=]
function ItemModule.GetItemFolder(itemName: string): Instance?
    return Items:FindFirstChild(itemName)
end

--[=[
    Gets the item's rarity if it exists
    @param itemName string -- The name of the item
    @return string? -- The item's rarity or nil if not found
]=]
function ItemModule.GetItemRarity(itemName: string): string?
    local itemFolder = ItemModule.GetItemFolder(itemName)
    if itemFolder and itemFolder:FindFirstChild("Rarity") then
        return itemFolder.Rarity.Value
    end
    return nil
end

--[=[
    Gets the item's type if it exists
    @param itemName string -- The name of the item
    @return string? -- The item's type or nil if not found
]=]
function ItemModule.GetItemType(itemName: string): string?
    local itemFolder = ItemModule.GetItemFolder(itemName)
    if itemFolder and itemFolder:FindFirstChild("Type") then
        return itemFolder.Type.Value
    end
    return nil
end

--[=[
    Gets the item's weight if it exists
    @param itemName string -- The name of the item
    @return number? -- The item's weight or nil if not found
]=]
function ItemModule.GetItemWeight(itemName: string): number?
    local itemFolder = ItemModule.GetItemFolder(itemName)
    if itemFolder and itemFolder:FindFirstChild("Weight") then
        return itemFolder.Weight.Value
    end
    return nil
end

--[=[
    Gets the item's tool if it exists
    @param itemName string -- The name of the item
    @return Tool? -- The item's tool or nil if not found
]=]
function ItemModule.GetItemTool(itemName: string): Tool?
    local itemFolder = ItemModule.GetItemFolder(itemName)
    if itemFolder and itemFolder:FindFirstChild("Tool") then
        return itemFolder.Tool:FindFirstChildOfClass("Tool")
    end
    return nil
end

--[=[
    Gets the item's description if it exists
    @param itemName string -- The name of the item
    @return string? -- The item's description or nil if not found
]=]
function ItemModule.GetItemDescription(itemName: string): string?
    local itemFolder = ItemModule.GetItemFolder(itemName)
    if itemFolder and itemFolder:FindFirstChild("Description") then
        return itemFolder.Description.Value
    end
    return nil
end

--[=[
    Gets the item's icon if it exists
    @param itemName string -- The name of the item
    @return string? -- The item's icon asset ID or nil if not found
]=]
function ItemModule.GetItemIcon(itemName: string): string?
    local itemFolder = ItemModule.GetItemFolder(itemName)
    if itemFolder and itemFolder:FindFirstChild("Icon") then
        return itemFolder.Icon.Value
    end
    return nil
end

--[=[
    Gets all properties of an item
    @param itemName string -- The name of the item
    @return table? -- Table containing all item properties or nil if item not found
]=]
function ItemModule.GetItemData(itemName: string): {[string]: any}?
    local itemFolder = ItemModule.GetItemFolder(itemName)
    if not itemFolder then return nil end
    
    return {
        name = itemName,
        rarity = ItemModule.GetItemRarity(itemName),
        type = ItemModule.GetItemType(itemName),
        weight = ItemModule.GetItemWeight(itemName),
        description = ItemModule.GetItemDescription(itemName),
        icon = ItemModule.GetItemIcon(itemName),
        hasTool = ItemModule.GetItemTool(itemName) ~= nil
    }
end

--[=[
    Checks if an item exists
    @param itemName string -- The name of the item to check
    @return boolean -- Whether the item exists
]=]
function ItemModule.ItemExists(itemName: string): boolean
    return ItemModule.GetItemFolder(itemName) ~= nil
end

--[=[
    Gets a list of all items
    @return {string} -- Array of all item names
]=]
function ItemModule.GetAllItems(): {string}
    local itemNames = {}
    for _, item in Items:GetChildren() do
        table.insert(itemNames, item.Name)
    end
    return itemNames
end

--[=[
    Gets all items of a specific type
    @param itemType string -- The type to filter by
    @return {string} -- Array of item names of the specified type
]=]
function ItemModule.GetItemsByType(itemType: string): {string}
    local itemNames = {}
    for _, item in Items:GetChildren() do
        if item:FindFirstChild("Type") and item.Type.Value == itemType then
            table.insert(itemNames, item.Name)
        end
    end
    return itemNames
end

--[=[
    Gets all items of a specific rarity
    @param rarity string -- The rarity to filter by
    @return {string} -- Array of item names of the specified rarity
]=]
function ItemModule.GetItemsByRarity(rarity: string): {string}
    local itemNames = {}
    for _, item in Items:GetChildren() do
        if item:FindFirstChild("Rarity") and item.Rarity.Value == rarity then
            table.insert(itemNames, item.Name)
        end
    end
    return itemNames
end

return ItemModule
