local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local PlayerObjectModule = require(game.ServerScriptService.AW_Inventory.Player.PlayerObject)
local ItemsFolder = ReplicatedStorage:WaitForChild("AW_Inventory"):WaitForChild("Items")

-- Import our new modules
local GridManager = require(script.Parent.GridManager)
local FrameManager = require(script.Parent.FrameManager)
local ItemGrouper = require(script.Parent.ItemGrouper)
local EquipmentManager = require(script.Parent.EquipmentManager)
local DebugManager = require(script.Parent.DebugManager)

local Functions = {}

-- Cache for UI elements and throttling
local UICache = {}
local LastUpdateTime = {}
local THROTTLE_TIME = 0.1 -- 100ms throttle

-- Initialize cache for a player
local function initializeCache(plr)
	if not UICache[plr] then
		local inventoryGui = plr.PlayerGui:WaitForChild("Inventory")
		local mainFrame = inventoryGui:WaitForChild("Main")
		local inventoryContainer = mainFrame:WaitForChild("InventoryFrame")
		local inventoryFrame = inventoryContainer:WaitForChild("Inventory")
		
		UICache[plr] = {
			inventoryGui = inventoryGui,
			mainFrame = mainFrame,
			inventoryContainer = inventoryContainer,
			inventoryFrame = inventoryFrame
		}
	end
	return UICache[plr]
end

-- Cleanup cache when player leaves
game.Players.PlayerRemoving:Connect(function(plr)
	UICache[plr] = nil
	LastUpdateTime[plr] = nil
end)

function Functions.SlotHandler(plr)
	-- Throttle check
	local currentTime = tick()
	if LastUpdateTime[plr] and currentTime - LastUpdateTime[plr] < THROTTLE_TIME then
		return -- Skip update if too soon
	end
	LastUpdateTime[plr] = currentTime

	if not SettingsModule.Debug.EnablePrints then
		DebugManager.disable() -- Temporarily disable debug logging in production
	end
	
	DebugManager.printItemProcessing("Starting SlotHandler for player: %s", plr.Name)
	
	local PlayerObject = PlayerObjectModule.GetPlayerObject(plr)
	if not PlayerObject then return end
	
	-- Get player's inventory data
	local inventory = PlayerObject:getInventory()
	if not inventory then 
		DebugManager.warn("No inventory data found for player: %s", plr.Name)
		return 
	end
	
	-- Get cached UI elements
	local cache = initializeCache(plr)
	local inventoryFrame = cache.inventoryFrame
	
	-- Batch remove existing frames
	local toRemove = {}
	for _, b in pairs(inventoryFrame:GetChildren()) do
		if not b:IsA("UIGridLayout") then
			table.insert(toRemove, b)
		end
	end
	for _, frame in ipairs(toRemove) do
		frame:Destroy()
	end
	
	-- Pre-allocate frames table with estimated size
	local frames = table.create(#inventory.Items)
	local nbr = 1
	
	-- Batch process items
	if SettingsModule.ShowQuantity then
		local groupedItems = ItemGrouper.groupItems(inventory)
		local batchSize = 10
		
		for i = 1, #groupedItems, batchSize do
			local batch = {}
			for j = i, math.min(i + batchSize - 1, #groupedItems) do
				local group = groupedItems[j]
				local itemData = group.data
				
				if ItemsFolder:FindFirstChild(itemData.name) then
					table.insert(batch, {
						itemData = itemData,
						itemFolder = ItemsFolder[itemData.name],
						ids = group.ids,
						quantity = #group.ids
					})
				end
			end
			
			-- Process batch
			for _, item in ipairs(batch) do
				local frame = FrameManager.createInventoryFrame(
					item.itemData.name,
					item.itemData,
					item.ids[1],
					item.itemFolder,
					plr,
					nbr
				)
				frame.Parent = inventoryFrame
				frame.BG.Main.Quantity.Text = tostring(item.quantity)
				
				table.insert(frames, frame)
				nbr = nbr + 1
			end
		end
	else
		local items = ItemGrouper.getUngroupedItems(inventory)
		local batchSize = 10
		
		for i = 1, #items, batchSize do
			local batch = {}
			for j = i, math.min(i + batchSize - 1, #items) do
				local item = items[j]
				if ItemsFolder:FindFirstChild(item.data.name) then
					table.insert(batch, {
						item = item,
						itemFolder = ItemsFolder[item.data.name]
					})
				end
			end
			
			-- Process batch
			for _, data in ipairs(batch) do
				local frame = FrameManager.createInventoryFrame(
					data.item.data.name,
					data.item.data,
					data.item.id,
					data.itemFolder,
					plr,
					nbr
				)
				frame.Parent = inventoryFrame
				frame.BG.Main.Quantity.Visible = false
				
				table.insert(frames, frame)
				nbr = nbr + 1
			end
		end
	end
	
	-- Handle equipped items
	local equipped = PlayerObject:getEquipped()
	EquipmentManager.handleEquippedItems(plr, equipped, ItemsFolder)
	
	-- Batch update positions
	local positions = GridManager.calculateSlotPositions(frames)
	for _, posData in ipairs(positions) do
		local frame = posData.frame
		local pos = posData.position
		frame.Position = UDim2.new(pos.X, 0, pos.Y, 0)
	end
	
	if not SettingsModule.Debug.EnablePrints then
		DebugManager.enable() -- Re-enable debug logging
	end
	
	DebugManager.printItemProcessing("SlotHandler completed for player: %s", plr.Name)
end

return Functions