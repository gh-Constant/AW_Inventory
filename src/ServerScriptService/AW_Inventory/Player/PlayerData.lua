local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Package = ReplicatedStorage.Packages
local ProfileStore = require(Package.profilestore)
local Log = require(Package.log)
local SlotHandler = require(ReplicatedStorage.AW_Inventory.Modules.SlotHandler)

-- Initialize logger
local logger = Log.new()

--[=[
    @class PlayerData
    A module for managing player inventory data using ProfileStore.

    Example usage:
    ```lua
    local PlayerData = require(path.to.PlayerData)

    -- Get a player's inventory
    local inventory = PlayerData.GetInventory(player)
    
    -- Add items
    PlayerData.AddItem(player, "Sword", 1, { durability = 100 })
    PlayerData.AddItem(player, "Coins", 50)
    
    -- Remove items
    PlayerData.RemoveItem(player, "Coins", 25)
    
    -- Equipment management
    PlayerData.EquipItem(player, "Sword", 1) -- Equip sword to slot 1
    PlayerData.UnequipItem(player, 1) -- Unequip slot 1
    ```

    @interface ItemData
    .quantity number -- The quantity of the item
    .data table -- Additional item-specific data

    @interface Inventory
    .Items { [string]: ItemData } -- Map of item IDs to their data
    .Equipped { [number]: string } -- Map of slot IDs to equipped item IDs
    .MaxSlots number -- Maximum number of equipment slots

    @tag Server
]=]

-- Type definitions
type ItemType = "weapon" | "armor" | "consumable" | "resource" | "quest" | "fish"

type RequiredItemData = {
    itemType: ItemType,
    itemId: number, -- 53-bit integer (safe in Lua)
    quantity: number,
    data: { [string]: any }
}

-- Modified ItemData type
type ItemData = RequiredItemData & {
    [string]: any
}

type Inventory = {
	Items: { [string]: ItemData },
	Equipped: { [number]: string },
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

type PlayerDataType = {
	GetInventory: (player: Player) -> Inventory?,
	AddItem: (player: Player, itemType: ItemType, quantity: number, itemData: { [string]: any }?) -> boolean,
	RemoveItem: (player: Player, itemId: number, quantity: number) -> boolean,
	EquipItem: (player: Player, itemId: string, slotId: number) -> boolean,
	UnequipItem: (player: Player, slotId: number) -> boolean,
	SetupPlayer: (player: Player) -> (),
	CleanupPlayer: (player: Player) -> ()
}

-- Define the profile template with only inventory structure
local PROFILE_TEMPLATE = {
	Inventory = {
		Items = {} :: { [string]: ItemData },
		Equipped = {} :: { [number]: string },
		MaxSlots = 20,
	},
}

local PlayerStore = ProfileStore.New("PlayerInventoryStore", PROFILE_TEMPLATE)
local Profiles: { [Player]: Profile } = {}

local PlayerData: PlayerDataType = {}

-- Add utility functions for ID generation
local LastItemId = 0
local function GenerateItemId(): number
    -- Using a combination of timestamp and counter for uniqueness
    -- Format: TTTTTTTTCCCC (T = timestamp bits, C = counter bits)
    -- This gives us 40 bits for timestamp (34 years of milliseconds) and 12 bits for counter (4096 items per ms)
    local timestamp = math.floor(os.time() * 1000) -- milliseconds
    LastItemId = (LastItemId + 1) % 4096
    return bit32.bor(bit32.lshift(timestamp, 12), LastItemId)
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
    Adds an item to the player's inventory.
    @param player Player -- The player to add item to
    @param itemType ItemType -- The type of the item to add
    @param quantity number -- The quantity to add
    @param itemData table? -- Optional additional data for the item
    @return boolean -- Whether the operation was successful
]=]
function PlayerData.AddItem(player: Player, itemType: ItemType, quantity: number, itemData: { [string]: any }?): boolean
	local profile = Profiles[player]
	if not profile then return false end
	
	-- Generate a unique ID for the item
	local itemId = GenerateItemId()
	
	-- Validate itemType
	if not table.find({"weapon", "armor", "consumable", "resource", "quest"}, itemType) then
		logger:AtError():Log("Invalid item type: {}", itemType)
		return false
	end
	
	local inventory = profile.Data.Inventory
	local newItemData: ItemData = {
		itemType = itemType,
		itemId = itemId,
		quantity = quantity,
		data = itemData or {}
	}
	
	inventory.Items[tostring(itemId)] = newItemData
	logger:AtInfo():Log("Added {} x{} (ID: {}) to {}'s inventory", itemType, quantity, itemId, player.Name)
	return true
end

--[=[
    Removes an item from the player's inventory.
    @param player Player -- The player to remove item from
    @param itemId number -- The ID of the item to remove
    @param quantity number -- The quantity to remove
    @return boolean -- Whether the operation was successful
]=]
function PlayerData.RemoveItem(player: Player, itemId: number, quantity: number): boolean
	local profile = Profiles[player]
	if not profile then return false end
	
	local inventory = profile.Data.Inventory
	local itemIdStr = tostring(itemId)
	if inventory.Items[itemIdStr] then
		inventory.Items[itemIdStr].quantity -= quantity
		if inventory.Items[itemIdStr].quantity <= 0 then
			inventory.Items[itemIdStr] = nil
		end
		logger:AtInfo():Log("Removed item {} x{} from {}'s inventory", itemId, quantity, player.Name)
		return true
	end
	return false
end

--[=[
    Equips an item to a specific slot.
    @param player Player -- The player to equip item for
    @param itemId string -- The ID of the item to equip
    @param slotId number -- The slot to equip the item to
    @return boolean -- Whether the operation was successful
]=]
function PlayerData.EquipItem(player: Player, itemId: string, slotId: number): boolean
	local profile = Profiles[player]
	if not profile then return false end
	
	local inventory = profile.Data.Inventory
	if inventory.Items[itemId] then
		inventory.Equipped[slotId] = itemId
		logger:AtInfo():Log("{} equipped {} in slot {}", player.Name, itemId, slotId)
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
	local itemId = inventory.Equipped[slotId]
	inventory.Equipped[slotId] = nil
	logger:AtInfo():Log("{} unequipped {} from slot {}", player.Name, itemId or "nothing", slotId)
	return true
end

--[=[
    @private
    Sets up the inventory profile for a player.
    @param player Player -- The player to setup
]=]
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
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE

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

--[=[
    @private
    Cleans up the inventory profile for a player.
    @param player Player -- The player to cleanup
]=]
function PlayerData.CleanupPlayer(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
		logger:AtInfo():Log("Cleaned up inventory profile for {}", player.Name)
	end
end

--[=[
    @private
    Updates the player's inventory.
    @param player Player -- The player to update
]=]
function PlayerData.UpdatePlayerInventory(player: Player)
	SlotHandler.SlotHandler(player)
end

-- Connect player events
Players.PlayerAdded:Connect(function(player: Player)
	if not Profiles[player] then
		PlayerData.SetupPlayer(player)
		PlayerData.UpdatePlayerInventory(player)
	end
end)

Players.PlayerRemoving:Connect(PlayerData.CleanupPlayer)

-- Handle existing players
for _, player: Player in Players:GetPlayers() do
	if not Profiles[player] then
		task.spawn(PlayerData.SetupPlayer, player)
	end
end

return PlayerData
