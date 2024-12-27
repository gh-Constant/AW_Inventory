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
		print("DEBUG: Processing item:", itemId, "Type:", itemData.itemType)
		
		if ItemsFolder[itemData.itemType] then
			local itemType = itemData.itemType
			local amount = itemData.quantity
			
			print("DEBUG: Creating frame for item:", itemType, "Amount:", amount)
			
			-- Clone template and set properties
			local frametemplate = CreateFrame.new()
			frametemplate.Parent = inventoryFrame
			frametemplate.Name = nbr
			frametemplate.LayoutOrder = nbr
			frametemplate.Item.Value = itemType
			
			-- Set amount text
			frametemplate.Template.TextLabel.Text = tostring(amount)
			
			-- Set rarity color
			local rarity = ItemsFolder[itemType].Rarity
			print("DEBUG: Item rarity:", rarity)
			local color = SettingsModule.RarityGradient[rarity]:Clone()
			color.Parent = frametemplate
			
			-- Handle viewport or image display
			local viewType = ItemsFolder[itemType].ViewType.Value
			print("DEBUG: Item view type:", viewType)
			
			if viewType == "Viewport" then
				frametemplate.Template.ViewportTemplate.Visible = true
				frametemplate.Template.ImageTemplate.Visible = false
				
				-- Fire viewport update to client
				print("DEBUG: Firing viewport update for:", itemType)
				ReplicatedStorage.AW_Inventory.Remotes.Viewport:FireClient(
					plr,
					frametemplate.Template.ViewportTemplate,
					tostring(itemType)
				)
			else
				if viewType == "Image" then
					frametemplate.Template.ImageTemplate.Image = ItemsFolder[itemType].ImageIcon.Image
					frametemplate.Template.ViewportTemplate.Visible = false
					frametemplate.Template.ImageTemplate.Visible = true
					print("DEBUG: Set image for item:", itemType)
				else
					warn("DEBUG: ImageID not set for item:", itemType)
				end
			end
			
			nbr = nbr + 1
			print("DEBUG: Finished processing item:", itemType)
		else
			warn("DEBUG: Item not configured in ItemsModule:", itemData.itemType)
		end
	end
	
	print("DEBUG: SlotHandler completed for player:", plr.Name)
end

return Functions