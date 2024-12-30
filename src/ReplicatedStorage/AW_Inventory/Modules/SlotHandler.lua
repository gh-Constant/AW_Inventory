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

function Functions.SlotHandler(plr)
	print("DEBUG: Starting SlotHandler for player:", plr.Name)

	local PlayerObject = PlayerObjectModule.GetPlayerObject(plr)

	print("DEBUG: PlayerData module loaded")
	
	local nbr = 1
	
	-- Clear existing inventory slots except UIGridLayout
	local inventoryFrame = plr.PlayerGui:WaitForChild("Inventory").InventoryFrame.Inventory.InventoryFrame
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
			
			-- Set amount text to show stack size
			frametemplate.Template.TextLabel.Text = tostring(#group.ids)
			
			-- Set rarity color
			local itemFolder = ItemsFolder[itemName]
			if itemFolder:FindFirstChild("Rarity") then
				local rarity = itemFolder.Rarity.Value
				print("DEBUG: Item rarity:", rarity)
				local color = SettingsModule.RarityGradient[rarity]:Clone()
				color.Parent = frametemplate
			end
			
			-- Handle viewport or image display
			if itemFolder:FindFirstChild("ViewType") then
				local viewType = itemFolder.ViewType.Value
				print("DEBUG: Item view type:", viewType)
				
				if viewType == "Viewport" then
					frametemplate.Template.ViewportTemplate.Visible = true
					frametemplate.Template.ImageTemplate.Visible = false
					
					-- Fire viewport update to client
					print("DEBUG: Firing viewport update for:", itemName)
					ReplicatedStorage.AW_Inventory.Remotes.Viewport:FireClient(
						plr,
						frametemplate.Template.ViewportTemplate,
						tostring(itemName)
					)
				elseif viewType == "Image" and itemFolder:FindFirstChild("ImageIcon") then
					frametemplate.Template.ImageTemplate.Image = itemFolder.ImageIcon.Image
					frametemplate.Template.ViewportTemplate.Visible = false
					frametemplate.Template.ImageTemplate.Visible = true
					print("DEBUG: Set image for item:", itemName)
				else
					warn("DEBUG: ViewType not set or invalid for item:", itemName)
				end
			else
				warn("DEBUG: ViewType not found for item:", itemName)
			end
			
			nbr = nbr + 1
			print("DEBUG: Finished processing item group:", itemName)
		else
			warn("DEBUG: Item not configured in ItemsFolder:", itemData.name)
		end
	end
	
	print("DEBUG: SlotHandler completed for player:", plr.Name)
end

return Functions