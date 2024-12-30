local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Functions = {}
local ItemsFolder = ReplicatedStorage.AW_Inventory.Items
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local PlayerObjectModule = require(game.ServerScriptService.AW_Inventory.Player.PlayerObject)
local CreateFrame = require(game.ReplicatedStorage.AW_Inventory.TemplateScrollFrame.CreateFrame)

-- Helper function to compare item data
local function areItemsEqual(data1, data2)
	if not data1 or not data2 then return false end
	
	-- Compare basic properties
	if data1.name ~= data2.name then return false end
	
	-- Compare data tables
	if not data1.data or not data2.data then
		return not data1.data and not data2.data -- true if both are nil
	end
	
	-- Compare all properties in data
	for k, v in pairs(data1.data) do
		if data2.data[k] ~= v then return false end
	end
	for k, v in pairs(data2.data) do
		if data1.data[k] ~= v then return false end
	end
	
	return true
end

-- Helper function to calculate optimal slot position
local function calculateSlotPosition(frames)
	local positions = {} -- Will store {frame = frame, position = Vector2}
	local rows = {} -- Will store arrays of frames and their occupied slots for each row
	
	-- Sort frames by size (GridSize.X * GridSize.Y) in descending order
	table.sort(frames, function(a, b)
		local aSize = (a.GridSize and (a.GridSize.X * a.GridSize.Y)) or 1
		local bSize = (b.GridSize and (b.GridSize.X * b.GridSize.Y)) or 1
		return aSize > bSize
	end)
	
	-- Helper function to check if a position is available in a row
	local function isPositionAvailable(row, startX, gridSize)
		-- Check each slot the item would occupy
		for x = startX, startX + gridSize.X - 1 do
			for y = 0, gridSize.Y - 1 do
				-- Check if any slot in this position is already occupied
				for _, occupied in ipairs(row.occupied) do
					if x >= occupied.x and x < occupied.x + occupied.width and
					   y >= occupied.y and y < occupied.y + occupied.height then
						return false
					end
				end
			end
		end
		return true
	end
	
	-- Process each frame
	for _, frame in ipairs(frames) do
		local gridSize = frame.GridSize or Vector3.new(1, 1, 0)
		local placed = false
		
		-- Try to place in existing rows first
		for rowIndex, row in ipairs(rows) do
			-- Try each possible X position in this row
			for x = 0, SettingsModule.MaxSlotsPerRow - gridSize.X do
				if isPositionAvailable(row, x, gridSize) then
					-- Place frame here
					table.insert(positions, {
						frame = frame,
						position = Vector2.new(
							x * SettingsModule.SlotSize.X,
							(rowIndex - 1) * SettingsModule.SlotSize.Y
						)
					})
					-- Mark slots as occupied
					table.insert(row.occupied, {
						x = x,
						y = 0,
						width = gridSize.X,
						height = gridSize.Y
					})
					placed = true
					break
				end
			end
			if placed then break end
		end
		
		-- If couldn't place in existing rows, create new row
		if not placed then
			local newRow = {occupied = {}}
			table.insert(rows, newRow)
			-- Place at start of new row
			table.insert(positions, {
				frame = frame,
				position = Vector2.new(
					0,
					(#rows - 1) * SettingsModule.SlotSize.Y
				)
			})
			-- Mark slots as occupied
			table.insert(newRow.occupied, {
				x = 0,
				y = 0,
				width = gridSize.X,
				height = gridSize.Y
			})
		end
	end
	
	return positions
end

function Functions.SlotHandler(plr)
	print("DEBUG: Starting SlotHandler for player:", plr.Name)

	local PlayerObject = PlayerObjectModule.GetPlayerObject(plr)
	print("DEBUG: PlayerData module loaded")
	
	local nbr = 1
	local frames = {} -- Store frames for positioning
	
	-- Clear existing inventory slots except UIGridLayout
	local inventoryFrame = plr.PlayerGui:WaitForChild("Inventory").Main.Background.InventoryFrame.Inventory
	print("DEBUG: Got inventory frame reference")
	
	for _, b in pairs(inventoryFrame:GetChildren()) do
		if not b:IsA("UIGridLayout") then
			b:Destroy()
		end
	end
	print("DEBUG: Cleared existing inventory slots")
	
	-- Get player's inventory data
	local inventory = PlayerObject:getInventory()
	if not inventory then 
		warn("DEBUG: No inventory data found for player:", plr.Name)
		return 
	end
	print("DEBUG: Got inventory data:", inventory)
	
	if SettingsModule.ShowQuantity then
		-- Group similar items
		local groupedItems = {}
		for itemId, itemData in pairs(inventory.Items) do
			local found = false
			for _, group in ipairs(groupedItems) do
				if areItemsEqual(group.data, itemData) then
					table.insert(group.ids, itemId)
					found = true
					break
				end
			end
			if not found then
				table.insert(groupedItems, {
					data = itemData,
					ids = {itemId}
				})
			end
		end
		
		-- Create frames for grouped items
		for _, group in ipairs(groupedItems) do
			local itemData = group.data
			print("DEBUG: Processing item group:", itemData.name, "#Items:", #group.ids)
			
			if ItemsFolder:FindFirstChild(itemData.name) then
				local itemName = itemData.name
				
				print("DEBUG: Creating frame for item:", itemName)
				
				-- Clone template and set properties
				local frametemplate = CreateFrame.new()
				frametemplate.Parent = inventoryFrame
				frametemplate.Name = nbr
				frametemplate.LayoutOrder = nbr
				frametemplate.Item.Value = itemName
				
				-- Get item grid size
				local itemFolder = ItemsFolder[itemName]
				if itemFolder:FindFirstChild("GridSize") then
					frametemplate.GridSize = itemFolder.GridSize.Value
				end
				
				-- Set amount text to show stack size
				frametemplate.BG.Main.Quantity.Text = tostring(#group.ids)
				
				-- Set rarity color
				if itemFolder:FindFirstChild("Rarity") then
					local rarity = itemFolder.Rarity.Value
					print("DEBUG: Item rarity:", rarity)
					local color = SettingsModule.RarityGradient[rarity]:Clone()
					color.Parent = frametemplate.BG
					color:Clone().Parent = frametemplate.BG.Main
				end
				
				-- Handle viewport or image display
				if itemFolder:FindFirstChild("ViewType") then
					local viewType = itemFolder.ViewType.Value
					print("DEBUG: Item view type:", viewType)
					
					if viewType == "Viewport" then
						frametemplate.BG.Main.ViewportTemplate.Visible = true
						frametemplate.BG.Main.ImageTemplate.Visible = false
						
						-- Fire viewport update to client
						print("DEBUG: Firing viewport update for:", itemName)
						ReplicatedStorage.AW_Inventory.Remotes.Viewport:FireClient(
							plr,
							frametemplate.BG.Main.ViewportTemplate,
							tostring(itemName)
						)
					elseif viewType == "Image" and itemFolder:FindFirstChild("ImageIcon") then
						frametemplate.BG.Main.ImageTemplate.Image = itemFolder.ImageIcon.Image
						frametemplate.BG.Main.ViewportTemplate.Visible = false
						frametemplate.BG.Main.ImageTemplate.Visible = true
						print("DEBUG: Set image for item:", itemName)
					else
						warn("DEBUG: ViewType not set or invalid for item:", itemName)
					end
				else
					warn("DEBUG: ViewType not found for item:", itemName)
				end
				
				table.insert(frames, frametemplate)
				nbr = nbr + 1
				print("DEBUG: Finished processing item group:", itemName)
			else
				warn("DEBUG: Item not configured in ItemsFolder:", itemData.name)
			end
		end
	else
		-- Create frames for each item individually
		for uniqueId, itemData in pairs(inventory.Items) do
			local itemName = itemData.name
			print("DEBUG: Processing item:", itemName, "ID:", uniqueId)
			
			if ItemsFolder:FindFirstChild(itemName) then
				print("DEBUG: Creating frame for item:", itemName)
				
				-- Clone template and set properties
				local frametemplate = CreateFrame.new()
				frametemplate.Parent = inventoryFrame
				frametemplate.Name = nbr
				frametemplate.LayoutOrder = nbr
				frametemplate.Item.Value = itemName
				
				-- Get item grid size
				local itemFolder = ItemsFolder[itemName]
				if itemFolder:FindFirstChild("GridSize") then
					frametemplate.GridSize = itemFolder.GridSize.Value
				end
				
				-- Hide quantity label when not using quantities
				frametemplate.BG.Main.Quantity.Visible = false
				
				-- Set rarity color
				if itemFolder:FindFirstChild("Rarity") then
					local rarity = itemFolder.Rarity.Value
					print("DEBUG: Item rarity:", rarity)
					local color = SettingsModule.RarityGradient[rarity]:Clone()
					color.Parent = frametemplate.BG
					color:Clone().Parent = frametemplate.BG.Main
				end
				
				-- Handle viewport or image display
				if itemFolder:FindFirstChild("ViewType") then
					local viewType = itemFolder.ViewType.Value
					print("DEBUG: Item view type:", viewType)
					
					if viewType == "Viewport" then
						frametemplate.BG.Main.ViewportTemplate.Visible = true
						frametemplate.BG.Main.ImageTemplate.Visible = false
						
						-- Fire viewport update to client
						print("DEBUG: Firing viewport update for:", itemName)
						ReplicatedStorage.AW_Inventory.Remotes.Viewport:FireClient(
							plr,
							frametemplate.BG.Main.ViewportTemplate,
							tostring(itemName)
						)
					elseif viewType == "Image" and itemFolder:FindFirstChild("ImageIcon") then
						frametemplate.BG.Main.ImageTemplate.Image = itemFolder.ImageIcon.Image
						frametemplate.BG.Main.ViewportTemplate.Visible = false
						frametemplate.BG.Main.ImageTemplate.Visible = true
						print("DEBUG: Set image for item:", itemName)
					else
						warn("DEBUG: ViewType not set or invalid for item:", itemName)
					end
				else
					warn("DEBUG: ViewType not found for item:", itemName)
				end
				
				table.insert(frames, frametemplate)
				nbr = nbr + 1
				print("DEBUG: Finished processing item:", itemName)
			else
				warn("DEBUG: Item not configured in ItemsFolder:", itemName)
			end
		end
	end
	
	-- Calculate and apply positions for all frames
	local positions = calculateSlotPosition(frames)
	for _, posData in ipairs(positions) do
		local frame = posData.frame
		local pos = posData.position
		
		-- Calculate size based on grid size
		local gridSize = frame.GridSize or Vector3.new(1, 1, 0)
		local width = SettingsModule.SlotSize.X * gridSize.X + SettingsModule.GridPadding.X * (gridSize.X - 1)
		local height = SettingsModule.SlotSize.Y * gridSize.Y + SettingsModule.GridPadding.Y * (gridSize.Y - 1)
		
		-- Apply position and size
		frame.Size = UDim2.new(width, 0, height, 0)
		frame.Position = UDim2.new(pos.X, 0, pos.Y, 0)
	end
	
	print("DEBUG: SlotHandler completed for player:", plr.Name)
end

return Functions