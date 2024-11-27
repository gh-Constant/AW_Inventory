--[=[
    @class PlayerObject
    A wrapper class for player-related operations, particularly inventory management.

    Example usage:
    ```lua
    local PlayerObject = require(path.to.PlayerObject)
    
    -- Get player object
    local playerObj = PlayerObject.GetPlayerObject(player)
    
    -- Inventory operations
    playerObj:addItemToInventory("Sword", 1, { durability = 100 })
    playerObj:removeItemFromInventory("Coins", 50)
    
    -- Equipment operations
    playerObj:equipItem("Sword", 1)
    playerObj:unequipItem(1)
    
    -- Inventory queries
    local inventory = playerObj:getInventory()
    local hasItem = playerObj:hasItem("Sword")
    local itemCount = playerObj:getItemCount("Coins")
    local equippedItem = playerObj:getEquippedItem(1)
    ```

    @interface PlayerObject
    .player Player -- The associated player instance
    .PlayerData any -- The PlayerData module instance
]=]

local Players = game:GetService("Players")
local PlayerData = require(script.Parent.PlayerData)

local PlayerObject = {}
PlayerObject.__index = PlayerObject

-- Table to store player objects
local playerObjects = {}

--[=[
    Creates a new PlayerObject instance.
    @param player Player -- The player to create the object for
    @return PlayerObject -- The created PlayerObject instance
    @private
]=]
function PlayerObject.new(player: Player)
	local self = setmetatable({}, PlayerObject)
	self.player = player
	self.PlayerData = PlayerData
	return self
end

--[=[
    Gets the player instance associated with this PlayerObject.
    @return Player -- The associated player
]=]
function PlayerObject:getPlayer(): Player
	return self.player
end

--[=[
    Gets the inventory data for the player.
    @return Inventory? -- The player's inventory data, or nil if not found
]=]
function PlayerObject:getInventory()
	return self.PlayerData.GetInventory(self.player)
end

--[=[
    Adds an item to the player's inventory.
    @param itemId string -- The ID of the item to add
    @param quantity number -- The quantity to add
    @param itemData table? -- Optional additional data for the item
    @return boolean -- Whether the operation was successful
]=]
function PlayerObject:addItemToInventory(itemId: string, quantity: number, itemData: { [string]: any }?): boolean
	return self.PlayerData.AddItem(self.player, itemId, quantity, itemData)
end

--[=[
    Removes an item from the player's inventory.
    @param itemId string -- The ID of the item to remove
    @param quantity number -- The quantity to remove
    @return boolean -- Whether the operation was successful
]=]
function PlayerObject:removeItemFromInventory(itemId: string, quantity: number): boolean
	return self.PlayerData.RemoveItem(self.player, itemId, quantity)
end

--[=[
    Equips an item to a specific slot.
    @param itemId string -- The ID of the item to equip
    @param slotId number -- The slot to equip the item to
    @return boolean -- Whether the operation was successful
]=]
function PlayerObject:equipItem(itemId: string, slotId: number): boolean
	return self.PlayerData.EquipItem(self.player, itemId, slotId)
end

--[=[
    Unequips an item from a specific slot.
    @param slotId number -- The slot to unequip
    @return boolean -- Whether the operation was successful
]=]
function PlayerObject:unequipItem(slotId: number): boolean
	return self.PlayerData.UnequipItem(self.player, slotId)
end

--[=[
    Checks if the player has a specific item.
    @param itemId string -- The ID of the item to check
    @return boolean -- Whether the player has the item
]=]
function PlayerObject:hasItem(itemId: string): boolean
	local inventory = self:getInventory()
	return inventory and inventory.Items[itemId] ~= nil
end

--[=[
    Gets the quantity of a specific item in the player's inventory.
    @param itemId string -- The ID of the item to check
    @return number -- The quantity of the item (0 if not found)
]=]
function PlayerObject:getItemCount(itemId: string): number
	local inventory = self:getInventory()
	return inventory and inventory.Items[itemId] and inventory.Items[itemId].quantity or 0
end

--[=[
    Gets the item equipped in a specific slot.
    @param slotId number -- The slot to check
    @return string? -- The ID of the equipped item, or nil if nothing is equipped
]=]
function PlayerObject:getEquippedItem(slotId: number): string?
	local inventory = self:getInventory()
	return inventory and inventory.Equipped[slotId]
end

--[=[
    Gets a PlayerObject instance for a specific player.
    @param player Player -- The player to get the object for
    @return PlayerObject? -- The PlayerObject instance, or nil if not found
]=]
function PlayerObject.GetPlayerObject(player: Player)
	return playerObjects[player]
end

-- Connect to PlayerAdded event to create a PlayerObject for each player
Players.PlayerAdded:Connect(function(player)
	playerObjects[player] = PlayerObject.new(player)
end)

-- Handle PlayerRemoving to clean up
Players.PlayerRemoving:Connect(function(player)
	playerObjects[player] = nil
end)

return PlayerObject
