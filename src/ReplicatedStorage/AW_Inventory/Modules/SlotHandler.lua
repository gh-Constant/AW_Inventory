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

-- Helper function to print grid visualization
local function printGridDebug(grid, maxY)
	print("\nGrid Layout (X = taken, . = empty):")
	print("   " .. string.rep("-", SettingsModule.MaxSlotsPerRow * 2 + 1))
	for y = 0, math.max(9, maxY) do -- Show at least 10 rows
		local row = string.format("%2d |", y)
		for x = 0, SettingsModule.MaxSlotsPerRow - 1 do
			row = row .. (grid[x][y] and " X" or " .")
		end
		row = row .. " |"
		print(row)
	end
	print("   " .. string.rep("-", SettingsModule.MaxSlotsPerRow * 2 + 1))
end

-- Helper function to calculate optimal slot position
local function calculateSlotPosition(frames)
	local positions = {} -- Will store {frame = frame, position = Vector2}
	local grid = {} -- 2D grid to track occupied slots
	local maxY = 0 -- Track the maximum Y position used
	
	-- Initialize grid
	for x = 0, SettingsModule.MaxSlotsPerRow - 1 do
		grid[x] = {}
	end
	
	-- Calculate grid sizes and sort frames by total area in descending order
	local frameData = {}
	for _, frame in ipairs(frames) do
		local gridSizeX = math.round(frame.Size.X.Scale / SettingsModule.SlotSize.X)
		local gridSizeY = math.round(frame.Size.Y.Scale / SettingsModule.SlotSize.Y)
		table.insert(frameData, {
			frame = frame,
			gridSize = Vector2.new(gridSizeX, gridSizeY),
			area = gridSizeX * gridSizeY
		})
	end
	
	table.sort(frameData, function(a, b)
		return a.area > b.area
	end)
	
	-- Helper function to check if a position is available
	local function isPositionAvailable(startX, startY, gridSize)
		if startX + gridSize.X > SettingsModule.MaxSlotsPerRow then
			return false
		end
		
		for x = startX, startX + gridSize.X - 1 do
			for y = startY, startY + gridSize.Y - 1 do
				if grid[x][y] then
					return false
				end
			end
		end
		return true
	end
	
	-- Helper function to mark slots as occupied
	local function markSlotsOccupied(startX, startY, gridSize)
		for x = startX, startX + gridSize.X - 1 do
			for y = startY, startY + gridSize.Y - 1 do
				grid[x][y] = true
			end
		end
		maxY = math.max(maxY, startY + gridSize.Y)
	end
	
	-- Process each frame
	for _, data in ipairs(frameData) do
		local frame = data.frame
		local gridSize = data.gridSize
		local placed = false
		
		print(string.format("\nPlacing item: %s (Size: %dx%d)", frame.Item.Value, gridSize.X, gridSize.Y))
		
		-- Try each Y position from top to bottom
		for y = 0, maxY do
			-- Try each X position in this row
			for x = 0, SettingsModule.MaxSlotsPerRow - gridSize.X do
				if isPositionAvailable(x, y, gridSize) then
					-- Place frame here
					table.insert(positions, {
						frame = frame,
						position = Vector2.new(
							x * SettingsModule.SlotSize.X,
							y * SettingsModule.SlotSize.Y
						)
					})
					markSlotsOccupied(x, y, gridSize)
					print(string.format("Placed at position: (%d, %d)", x, y))
					printGridDebug(grid, maxY)
					placed = true
					break
				end
			end
			if placed then break end
		end
		
		-- If couldn't place in existing rows, add to new row
		if not placed then
			local y = maxY
			for x = 0, SettingsModule.MaxSlotsPerRow - gridSize.X do
				if isPositionAvailable(x, y, gridSize) then
					table.insert(positions, {
						frame = frame,
						position = Vector2.new(
							x * SettingsModule.SlotSize.X,
							y * SettingsModule.SlotSize.Y
						)
					})
					markSlotsOccupied(x, y, gridSize)
					print(string.format("Placed at new row position: (%d, %d)", x, y))
					printGridDebug(grid, maxY)
					break
				end
			end
		end
	end
	
	print("\nFinal grid layout:")
	printGridDebug(grid, maxY)
	
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
				
				-- Create frame name with item and data info
				local frameName = itemName
				if itemData.data then
					for key, value in pairs(itemData.data) do
						frameName = frameName .. "_" .. tostring(key) .. "-" .. tostring(value)
					end
				end
				-- For grouped items, use the first ID in the group
				frameName = frameName .. "_" .. group.ids[1]
				
				frametemplate.Name = frameName
				frametemplate.LayoutOrder = nbr
				frametemplate.Item.Value = itemName
				
				-- Get item grid size and set frame size
				local itemFolder = ItemsFolder[itemName]
				if itemFolder:FindFirstChild("GridSize") then
					local gridSize = itemFolder.GridSize.Value
					local width = SettingsModule.SlotSize.X * gridSize.X + SettingsModule.GridPadding.X * (gridSize.X - 1)
					local height = SettingsModule.SlotSize.Y * gridSize.Y + SettingsModule.GridPadding.Y * (gridSize.Y - 1)
					frametemplate.Size = UDim2.new(width, 0, height, 0)
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
				
				-- Create frame name with item and data info
				local frameName = itemName
				if itemData.data then
					for key, value in pairs(itemData.data) do
						frameName = frameName .. "_" .. tostring(key) .. "-" .. tostring(value)
					end
				end
				frameName = frameName .. "_" .. uniqueId
				
				frametemplate.Name = frameName
				frametemplate.LayoutOrder = nbr
				frametemplate.Item.Value = itemName
				
				-- Get item grid size and set frame size
				local itemFolder = ItemsFolder[itemName]
				if itemFolder:FindFirstChild("GridSize") then
					local gridSize = itemFolder.GridSize.Value
					local width = SettingsModule.SlotSize.X * gridSize.X + SettingsModule.GridPadding.X * (gridSize.X - 1)
					local height = SettingsModule.SlotSize.Y * gridSize.Y + SettingsModule.GridPadding.Y * (gridSize.Y - 1)
					frametemplate.Size = UDim2.new(width, 0, height, 0)
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
		
		-- Apply position
		frame.Position = UDim2.new(pos.X, 0, pos.Y, 0)
	end
	
	print("DEBUG: SlotHandler completed for player:", plr.Name)
end

return Functions