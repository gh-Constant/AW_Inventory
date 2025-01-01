local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Functions = {}
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local ItemsFolder = game:GetService("ReplicatedStorage"):WaitForChild("AW_Inventory"):WaitForChild("Items")
local PlayerObjectModule = require(game.ServerScriptService.AW_Inventory.Player.PlayerObject)
local CreateFrame = require(game.ReplicatedStorage.AW_Inventory.TemplateScrollFrame.CreateFrame)

-- Helper function for debug prints
local function debugPrint(message, ...)
	if not SettingsModule.Debug.EnablePrints then return end
	print(string.format(message, ...))
end

-- Helper function for debug warnings
local function debugWarn(message, ...)
	if not SettingsModule.Debug.EnablePrints then return end
	warn(string.format(message, ...))
end

-- Helper function to print grid visualization
local function printGridDebug(grid, maxY)
	if not SettingsModule.Debug.EnablePrints or not SettingsModule.Debug.ShowGridDebug then return end
	
	print("\nGrid Layout (X = taken, . = empty):")
	print("   " .. string.rep("-", SettingsModule.MaxSlotsPerRow * 2 + 1))
	for y = 0, math.max(SettingsModule.Debug.MinDebugRows - 1, maxY) do
		local row = string.format("%2d |", y)
		for x = 0, SettingsModule.MaxSlotsPerRow - 1 do
			row = row .. (grid[x][y] and " X" or " .")
		end
		row = row .. " |"
		print(row)
	end
	print("   " .. string.rep("-", SettingsModule.MaxSlotsPerRow * 2 + 1))
end

-- Helper function to create frame name
local function createFrameName(itemName, itemData, uniqueId)
	local frameName = itemName
	if itemData.data then
		for key, value in pairs(itemData.data) do
			frameName = frameName .. SettingsModule.FrameNameSeparator .. 
					   tostring(key) .. SettingsModule.PropertyValueSeparator .. tostring(value)
		end
	end
	return frameName .. SettingsModule.FrameNameSeparator .. uniqueId
end

-- Helper function to set frame gradients
local function setFrameGradients(frame, rarity)
	-- Create base gradient for BG
	local baseGradient = SettingsModule.RarityGradient[rarity]:Clone()
	baseGradient.Parent = frame.BG
	
	-- Create darker gradient for frame
	local frameGradient = SettingsModule.RarityGradient[rarity]:Clone()
	
	-- Create new keypoints with darker colors
	local newKeypoints = {}
	for _, keypoint in ipairs(frameGradient.Color.Keypoints) do
		local darkerColor = keypoint.Value:Lerp(Color3.new(0, 0, 0), SettingsModule.BGGradientDarkness)
		local newKeypoint = ColorSequenceKeypoint.new(keypoint.Time, darkerColor)
		table.insert(newKeypoints, newKeypoint)
	end
	
	-- Apply new keypoints to the gradient
	frameGradient.Color = ColorSequence.new(newKeypoints)
	frameGradient.Parent = frame
end

-- Helper function to handle view type
local function setViewType(frame, itemFolder, plr, itemName)
	if not itemFolder:FindFirstChild("ViewType") then
		warn("DEBUG: ViewType not found for item:", itemName)
		return
	end
	
	local viewType = itemFolder.ViewType.Value
	if SettingsModule.Debug.ShowItemProcessing then
		print("DEBUG: Item view type:", viewType)
	end
	
	if viewType == SettingsModule.ViewTypes.VIEWPORT then
		frame.BG.Main.ViewportTemplate.Visible = true
		frame.BG.Main.ImageTemplate.Visible = false
		
		-- Fire viewport update to client
		if SettingsModule.Debug.ShowItemProcessing then
			print("DEBUG: Firing viewport update for:", itemName)
		end
		ReplicatedStorage.AW_Inventory.Remotes.Viewport:FireClient(
			plr,
			frame.BG.Main.ViewportTemplate,
			tostring(itemName)
		)
	elseif viewType == SettingsModule.ViewTypes.IMAGE and itemFolder:FindFirstChild("ImageIcon") then
		frame.BG.Main.ImageTemplate.Image = itemFolder.ImageIcon.Image
		frame.BG.Main.ViewportTemplate.Visible = false
		frame.BG.Main.ImageTemplate.Visible = true
		if SettingsModule.Debug.ShowItemProcessing then
			print("DEBUG: Set image for item:", itemName)
		end
	else
		warn("DEBUG: ViewType not set or invalid for item:", itemName)
	end
end

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
		
		if SettingsModule.Debug.ShowGridDebug then
			debugPrint("\nPlacing item: %s (Size: %dx%d)", frame.Item.Value, gridSize.X, gridSize.Y)
		end
		
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
					if SettingsModule.Debug.ShowGridDebug then
						debugPrint("Placed at position: (%d, %d)", x, y)
						printGridDebug(grid, maxY)
					end
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
					if SettingsModule.Debug.ShowGridDebug then
						debugPrint("Placed at new row position: (%d, %d)", x, y)
						printGridDebug(grid, maxY)
					end
					break
				end
			end
		end
	end
	
	if SettingsModule.Debug.ShowGridDebug then
		debugPrint("\nFinal grid layout:")
		printGridDebug(grid, maxY)
	end
	
	return positions
end

function Functions.SlotHandler(plr)
	if SettingsModule.Debug.ShowItemProcessing then
			debugPrint("Starting SlotHandler for player: %s", plr.Name)
	end

	local PlayerObject = PlayerObjectModule.GetPlayerObject(plr)
	if SettingsModule.Debug.ShowItemProcessing then
		debugPrint("PlayerData module loaded")
	end
	
	local nbr = 1
	local frames = {} -- Store frames for positioning
	
	-- Clear existing inventory slots except UIGridLayout
	local inventoryGui = plr.PlayerGui:WaitForChild("Inventory")
	local mainFrame = inventoryGui:WaitForChild("Main")
	local inventoryContainer = mainFrame:WaitForChild("InventoryFrame")
	local inventoryFrame = inventoryContainer:WaitForChild("Inventory")
	
	if SettingsModule.Debug.ShowItemProcessing then
		debugPrint("Got inventory frame reference")
	end
	
	for _, b in pairs(inventoryFrame:GetChildren()) do
		if not b:IsA("UIGridLayout") then
			b:Destroy()
		end
	end
	if SettingsModule.Debug.ShowItemProcessing then
		debugPrint("Cleared existing inventory slots")
	end
	
	-- Get player's inventory data
	local inventory = PlayerObject:getInventory()
	if not inventory then 
		debugWarn("No inventory data found for player: %s", plr.Name)
		return 
	end
	if SettingsModule.Debug.ShowItemProcessing then
		debugPrint("Got inventory data: %s", tostring(inventory))
	end
	
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
			if SettingsModule.Debug.ShowItemProcessing then
				debugPrint("Processing item group: %s #Items: %d", itemData.name, #group.ids)
			end
			
			if ItemsFolder:FindFirstChild(itemData.name) then
				local itemName = itemData.name
				
				if SettingsModule.Debug.ShowItemProcessing then
					debugPrint("Creating frame for item: %s", itemName)
				end
				
				-- Clone template and set properties
				local frametemplate = CreateFrame.new()
				frametemplate.Parent = inventoryFrame
				frametemplate.Name = createFrameName(itemName, itemData, group.ids[1])
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
				
				-- Set rarity color and view type
				if itemFolder:FindFirstChild("Rarity") then
					setFrameGradients(frametemplate, itemFolder.Rarity.Value)
				end
				setViewType(frametemplate, itemFolder, plr, itemName)
				
				table.insert(frames, frametemplate)
				nbr = nbr + 1
				if SettingsModule.Debug.ShowItemProcessing then
					debugPrint("Finished processing item group: %s", itemName)
				end
			else
				debugWarn("Item not configured in ItemsFolder: %s", itemData.name)
			end
		end
	else
		-- Create frames for each item individually
		for uniqueId, itemData in pairs(inventory.Items) do
			local itemName = itemData.name
			if SettingsModule.Debug.ShowItemProcessing then
				debugPrint("Processing item: %s ID: %s", itemName, uniqueId)
			end
			
			if ItemsFolder:FindFirstChild(itemName) then
				if SettingsModule.Debug.ShowItemProcessing then
					debugPrint("Creating frame for item: %s", itemName)
				end
				
				-- Clone template and set properties
				local frametemplate = CreateFrame.new()
				frametemplate.Parent = inventoryFrame
				frametemplate.Name = createFrameName(itemName, itemData, uniqueId)
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
				
				-- Set rarity color and view type
				if itemFolder:FindFirstChild("Rarity") then
					setFrameGradients(frametemplate, itemFolder.Rarity.Value)
				end
				setViewType(frametemplate, itemFolder, plr, itemName)
				
				table.insert(frames, frametemplate)
				nbr = nbr + 1
				if SettingsModule.Debug.ShowItemProcessing then
					debugPrint("Finished processing item: %s", itemName)
				end
			else
				debugWarn("Item not configured in ItemsFolder: %s", itemName)
			end
		end
	end
	
	-- Calculate and apply positions for all frames
	local positions = calculateSlotPosition(frames)
	for _, posData in ipairs(positions) do
		local frame = posData.frame
		local pos = posData.position
		frame.Position = UDim2.new(pos.X, 0, pos.Y, 0)
	end
	
	if SettingsModule.Debug.ShowItemProcessing then
		debugPrint("SlotHandler completed for player: %s", plr.Name)
	end
end

return Functions