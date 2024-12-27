local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Functions = {}
local ItemsFolder = ReplicatedStorage.AW_Inventory.Items
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local PlayerObjectModule = require(game.ServerScriptService.AW_Inventory.Player.PlayerObject)
local CreateFrame = require(game.ReplicatedStorage.AW_Inventory.TemplateScrollFrame.CreateFrame)
	
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
	
	-- Populate inventory slots
	for itemId, itemData in pairs(inventory.Items) do
		print("DEBUG: Processing item:", itemId, "Name:", itemData.name)
		
		if ItemsFolder:FindFirstChild(itemData.name) then
			local itemName = itemData.name
			
			print("DEBUG: Creating frame for item:", itemName)
			
			-- Clone template and set properties
			local frametemplate = CreateFrame.new()
			frametemplate.Parent = inventoryFrame
			frametemplate.Name = nbr
			frametemplate.LayoutOrder = nbr
			frametemplate.Item.Value = itemName
			
			-- Set amount text (now we show 1 since each item is unique)
			frametemplate.Template.TextLabel.Text = "1"
			
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
			print("DEBUG: Finished processing item:", itemName)
		else
			warn("DEBUG: Item not configured in ItemsFolder:", itemData.name)
		end
	end
	
	print("DEBUG: SlotHandler completed for player:", plr.Name)
end

return Functions