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

function Functions.SlotHandler(plr)
	DebugManager.printItemProcessing("Starting SlotHandler for player: %s", plr.Name)
	
	local PlayerObject = PlayerObjectModule.GetPlayerObject(plr)
	DebugManager.printItemProcessing("PlayerData module loaded")
	
	-- Get player's inventory data
	local inventory = PlayerObject:getInventory()
	if not inventory then 
		DebugManager.warn("No inventory data found for player: %s", plr.Name)
		return 
	end
	DebugManager.printItemProcessing("Got inventory data")
	
	-- Clear existing inventory slots
	local inventoryGui = plr.PlayerGui:WaitForChild("Inventory")
	local mainFrame = inventoryGui:WaitForChild("Main")
	local inventoryContainer = mainFrame:WaitForChild("InventoryFrame")
	local inventoryFrame = inventoryContainer:WaitForChild("Inventory")
	
	for _, b in pairs(inventoryFrame:GetChildren()) do
		if not b:IsA("UIGridLayout") then
			b:Destroy()
		end
	end
	DebugManager.printItemProcessing("Cleared existing inventory slots")
	
	local frames = {} -- Store frames for 	positioning
	local nbr = 1
	
	if SettingsModule.ShowQuantity then
		-- Process grouped items
		local groupedItems = ItemGrouper.groupItems(inventory)
		
		for _, group in ipairs(groupedItems) do
			local itemData = group.data
			DebugManager.printItemProcessing("Processing item group: %s #Items: %d", itemData.name, #group.ids)
			
			if ItemsFolder:FindFirstChild(itemData.name) then
				local itemFolder = ItemsFolder[itemData.name]
				local frame = FrameManager.createInventoryFrame(itemData.name, itemData, group.ids[1], itemFolder, plr, nbr)
				frame.Parent = inventoryFrame
				frame.BG.Main.Quantity.Text = tostring(#group.ids)
				
				table.insert(frames, frame)
				nbr = nbr + 1
				DebugManager.printItemProcessing("Finished processing item group: %s", itemData.name)
			else
				DebugManager.warn("Item not configured in ItemsFolder: %s", itemData.name)
			end
		end
	else
		-- Process individual items
		local items = ItemGrouper.getUngroupedItems(inventory)
		
		for _, item in ipairs(items) do
			local itemName = item.data.name
			DebugManager.printItemProcessing("Processing item: %s ID: %s", itemName, item.id)
			
			if ItemsFolder:FindFirstChild(itemName) then
				local itemFolder = ItemsFolder[itemName]
				local frame = FrameManager.createInventoryFrame(itemName, item.data, item.id, itemFolder, plr, nbr)
				frame.Parent = inventoryFrame
				frame.BG.Main.Quantity.Visible = false
				
				table.insert(frames, frame)
				nbr = nbr + 1
				DebugManager.printItemProcessing("Finished processing item: %s", itemName)
			else
				DebugManager.warn("Item not configured in ItemsFolder: %s", itemName)
			end
		end
	end
	
	-- Handle equipped items
	local equipped = PlayerObject:getEquipped()
	EquipmentManager.handleEquippedItems(plr, equipped, ItemsFolder)
	
	-- Calculate and apply positions for all frames
	local positions = GridManager.calculateSlotPositions(frames)
	for _, posData in ipairs(positions) do
		local frame = posData.frame
		local pos = posData.position
		frame.Position = UDim2.new(pos.X, 0, pos.Y, 0)
	end
	
	DebugManager.printItemProcessing("SlotHandler completed for player: %s", plr.Name)
end

return Functions