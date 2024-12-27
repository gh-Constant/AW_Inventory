local Players = game:GetService("Players")
local PlayerData = require(script.Parent.PlayerData)

local PlayerObject = {}
PlayerObject.__index = PlayerObject

local playerObjects = {}

function PlayerObject.new(player: Player)
	local self = setmetatable({}, PlayerObject)
	self.player = player
	self.PlayerData = PlayerData
	return self
end

function PlayerObject:getPlayer(): Player
	return self.player
end

function PlayerObject:getInventory()
	return self.PlayerData.GetInventory(self.player)
end

--[=[
	Gets all items of a specific name in the inventory.
	@param itemName string -- The item name to look for
	@return {[string]: any} -- Table of matching items by their unique IDs
]=]
function PlayerObject:getItemsByName(itemName: string): {[string]: any}
	return self.PlayerData.GetItemsByName(self.player, itemName)
end


--[=[
	Gets the count of items with a specific name.
	@param itemName string -- The item name to count
	@return number -- The count of matching items
]=]
function PlayerObject:getItemCount(itemName: string): number
	return self.PlayerData.GetItemCount(self.player, itemName)
end

--[=[
	Adds an item to the inventory.
	@param itemName string -- The name of the item to add
	@param itemData table? -- Optional additional data for the item
	@return string? -- The unique ID of the added item, or nil if failed
]=]
function PlayerObject:addItemToInventory(itemName: string, itemData: { [string]: any }?): string?
	return self.PlayerData.AddItem(self.player, itemName, itemData)
end

--[=[
	Removes a specific item instance from the inventory.
	@param uniqueId string -- The unique ID of the item to remove
	@return boolean -- Whether the operation was successful
]=]
function PlayerObject:removeItemFromInventory(uniqueId: string): boolean
	return self.PlayerData.RemoveItem(self.player, uniqueId)
end

--[=[
	Checks if the player has a specific item instance.
	@param uniqueId string -- The unique ID of the item to check
	@return boolean -- Whether the player has the item
]=]
function PlayerObject:hasItem(uniqueId: string): boolean
	local inventory = self:getInventory()
	return inventory and inventory.Items[uniqueId] ~= nil
end

--[=[
	Checks if the player has any items with a specific name.
	@param itemName string -- The item name to check
	@return boolean -- Whether the player has any items of this name
]=]
function PlayerObject:hasItemOfName(itemName: string): boolean
	return self:getItemCount(itemName) > 0
end

--[=[
	Gets the item equipped in a specific slot.
	@param slotId number -- The slot to check
	@return string? -- The unique ID of the equipped item, or nil if nothing is equipped
]=]
function PlayerObject:getEquippedItem(slotId: number): string?
	local inventory = self:getInventory()
	return inventory and inventory.Equipped[slotId]
end


--[=[
	Equips an item to a specific slot.
	@param uniqueId string -- The unique ID of the item to equip
	@param slotId number -- The slot to equip the item to
	@return boolean -- Whether the operation was successful
]=]
function PlayerObject:equipItem(uniqueId: string, slotId: number): boolean
	return self.PlayerData.EquipItem(self.player, uniqueId, slotId)
end

--[=[
	Unequips an item from a specific slot.
	@param slotId number -- The slot to unequip
	@return boolean -- Whether the operation was successful
]=]
function PlayerObject:unequipItem(slotId: number): boolean
	return self.PlayerData.UnequipItem(self.player, slotId)
end

function PlayerObject.GetPlayerObject(player: Player)
	return playerObjects[player]
end

Players.PlayerAdded:Connect(function(player)
	playerObjects[player] = PlayerObject.new(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playerObjects[player] = nil
end)

return PlayerObject
