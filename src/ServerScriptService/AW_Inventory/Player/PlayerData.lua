local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Package = ReplicatedStorage.Packages
local ProfileStore = require(Package.profilestore)
local Log = require(Package.log)

-- Initialize logger
local logger = Log.new()

--[=[
    @class PlayerData
    A module for managing player inventory data using ProfileStore.
    Each item has a unique ID, but items of the same name are visually stacked in the UI.

    Example usage:
    ```lua
    local PlayerData = require(path.to.PlayerData)

    -- Get a player's inventory
    local inventory = PlayerData.GetInventory(player)
    
    -- Add items
    PlayerData.AddItem(player, "Iron Sword", { durability = 100 })
    PlayerData.AddItem(player, "Iron Sword") -- Creates another unique sword
    
    -- Remove items
    PlayerData.RemoveItem(player, "item_uuid_here")
    
    -- Equipment management
    PlayerData.EquipItem(player, "item_uuid_here", 1) -- Equip item to slot 1
    PlayerData.UnequipItem(player, 1) -- Unequip slot 1
    ```
]=]

type ItemData = {
    name: string, -- The item name (e.g. "Iron Sword")
    uniqueId: string, -- Unique identifier for this specific item instance
    data: { [string]: any } -- Additional item-specific data
}

type Inventory = {
    Items: { [string]: ItemData }, -- Map of unique IDs to their data
    Equipped: { [number]: string }, -- Map of slot IDs to unique item IDs
    MaxSlots: number,
}

type Profile = {
    Data: {
        Inventory: Inventory
    },
    AddUserId: (self: Profile, userId: number) -> (),
    Reconcile: (self: Profile) -> (),
    OnSessionEnd: { Connect: (self: any, callback: () -> ()) -> () },
    EndSession: (self: Profile) -> ()
}

-- Define the profile template
local PROFILE_TEMPLATE = {
    Inventory = {
        Items = {}, -- Now stores items by their unique IDs
        Equipped = {},
        MaxSlots = 20,
    },
}

local PlayerStore = ProfileStore.New("PlayerInventoryStore2", PROFILE_TEMPLATE)
local Profiles: { [Player]: Profile } = {}

local PlayerData = {}

-- Utility function to generate a UUID
local function GenerateUUID(): string
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end

--[=[
    Gets the inventory data for a player.
    @param player Player -- The player to get inventory for
    @return Inventory? -- The player's inventory data, or nil if not found
]=]
function PlayerData.GetInventory(player: Player): Inventory?
    local profile = Profiles[player]
    if profile then
        return profile.Data.Inventory
    end
    return nil
end

--[=[
    Gets all items of a specific name in the player's inventory.
    @param player Player -- The player to check
    @param itemName string -- The item name to look for
    @return {[string]: ItemData} -- Table of matching items by their unique IDs
]=]
function PlayerData.GetItemsByName(player: Player, itemName: string): {[string]: ItemData}
    local inventory = PlayerData.GetInventory(player)
    if not inventory then return {} end
    
    local matchingItems = {}
    for uniqueId, itemData in pairs(inventory.Items) do
        if itemData.name == itemName then
            matchingItems[uniqueId] = itemData
        end
    end
    return matchingItems
end

--[=[
    Counts how many items of a specific name the player has.
    @param player Player -- The player to check
    @param itemName string -- The item name to count
    @return number -- The count of matching items
]=]
function PlayerData.GetItemCount(player: Player, itemName: string): number
    local items = PlayerData.GetItemsByName(player, itemName)
    return #items
end

--[=[
    Adds an item to the player's inventory.
    @param player Player -- The player to add item to
    @param itemName string -- The name of the item to add
    @param itemData table? -- Optional additional data for the item
    @return string? -- The unique ID of the added item, or nil if failed
]=]
function PlayerData.AddItem(player: Player, itemName: string, itemData: { [string]: any }?): string?
    local profile = Profiles[player]
    if not profile then return nil end
    
    local uniqueId = GenerateUUID()
    local inventory = profile.Data.Inventory
    
    inventory.Items[uniqueId] = {
        name = itemName,
        uniqueId = uniqueId,
        data = itemData or {}
    }
    
    logger:AtInfo():Log("Added {} (ID: {}) to {}'s inventory", itemName, uniqueId, player.Name)
    return uniqueId
end

--[=[
    Removes a specific item instance from the player's inventory.
    @param player Player -- The player to remove item from
    @param uniqueId string -- The unique ID of the item to remove
    @return boolean -- Whether the operation was successful
]=]
function PlayerData.RemoveItem(player: Player, uniqueId: string): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    local inventory = profile.Data.Inventory
    if inventory.Items[uniqueId] then
        local itemName = inventory.Items[uniqueId].name
        inventory.Items[uniqueId] = nil
        logger:AtInfo():Log("Removed item {} (ID: {}) from {}'s inventory", itemName, uniqueId, player.Name)
        return true
    end
    return false
end

--[=[
    Equips an item to a specific slot.
    @param player Player -- The player to equip item for
    @param uniqueId string -- The unique ID of the item to equip
    @param slotId number -- The slot to equip the item to
    @return boolean -- Whether the operation was successful
]=]
function PlayerData.EquipItem(player: Player, uniqueId: string, slotId: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    local inventory = profile.Data.Inventory
    if inventory.Items[uniqueId] then
        inventory.Equipped[slotId] = uniqueId
        logger:AtInfo():Log("{} equipped {} in slot {}", player.Name, uniqueId, slotId)
        return true
    end
    return false
end

--[=[
    Unequips an item from a specific slot.
    @param player Player -- The player to unequip item for
    @param slotId number -- The slot to unequip
    @return boolean -- Whether the operation was successful
]=]
function PlayerData.UnequipItem(player: Player, slotId: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    local inventory = profile.Data.Inventory
    local uniqueId = inventory.Equipped[slotId]
    inventory.Equipped[slotId] = nil
    logger:AtInfo():Log("{} unequipped {} from slot {}", player.Name, uniqueId or "nothing", slotId)
    return true
end

function PlayerData.SetupPlayer(player: Player)
    if Profiles[player] then
        logger:AtWarning():Log("Inventory profile session already exists for player: {}", player.Name)
        return
    end

    local profile = PlayerStore:StartSessionAsync(tostring(player.UserId), {
        Cancel = function()
            return player.Parent ~= Players
        end,
    }) :: Profile?

    if profile ~= nil then
        profile:AddUserId(player.UserId)
        profile:Reconcile()

        profile.OnSessionEnd:Connect(function()
            Profiles[player] = nil
            logger:AtWarning():Log("Inventory profile session ended for {}", player.Name)
            player:Kick("Inventory profile session end - Please rejoin")
        end)

        if player.Parent == Players then
            Profiles[player] = profile
            logger:AtInfo():Log("Inventory profile loaded for {}", player.Name)
        else
            profile:EndSession()
            logger:AtWarning():Log("Player left before inventory profile could be loaded: {}", player.Name)
        end
    else
        logger:AtError():Log("Failed to load inventory profile for {}", player.Name)
        player:Kick("Inventory profile load fail - Please rejoin")
    end
end

function PlayerData.CleanupPlayer(player: Player)
    local profile = Profiles[player]
    if profile ~= nil then
        profile:EndSession()
        logger:AtInfo():Log("Cleaned up inventory profile for {}", player.Name)
    end
end

Players.PlayerAdded:Connect(function(player: Player)
    if not Profiles[player] then
        print("Setting up player inventory for", player.Name)
        PlayerData.SetupPlayer(player)
    end
end)

Players.PlayerRemoving:Connect(PlayerData.CleanupPlayer)

for _, player: Player in Players:GetPlayers() do
    if not Profiles[player] then
        task.spawn(PlayerData.SetupPlayer, player)
    end
end

return PlayerData
