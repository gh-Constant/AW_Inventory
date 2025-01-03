local SettingsModule = require(game.ReplicatedStorage.AW_Inventory.SettingsModule)

local GridManager = {}

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

function GridManager.calculateSlotPositions(frames)
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
			print("\nPlacing item: " .. frame.Item.Value .. " (Size: " .. gridSize.X .. "x" .. gridSize.Y .. ")")
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
						print("Placed at position: (" .. x .. ", " .. y .. ")")
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
						print("Placed at new row position: (" .. x .. ", " .. y .. ")")
						printGridDebug(grid, maxY)
					end
					break
				end
			end
		end
	end
	
	if SettingsModule.Debug.ShowGridDebug then
		print("\nFinal grid layout:")
		printGridDebug(grid, maxY)
	end
	
	return positions
end

return GridManager 