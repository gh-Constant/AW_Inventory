local dt = false
local SlotHandler = require(game.ReplicatedStorage.AW_Inventory.Modules.SlotHandler)
local PlayerObject = require(game.ServerScriptService.AW_Inventory.Player.PlayerObject)
local ItemModule = require(game.ServerScriptService.AW_Inventory.Items.ItemModule)

local plr = script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent

script.Parent.MouseButton1Click:Connect(function()
	if dt == false then
		dt = true
		wait(0.5)
		dt = false
		print("too slow")
	elseif dt == true then
		local itemName = script.Parent.Parent.Item.Value
		local playerObj = PlayerObject.GetPlayerObject(plr)
		
		if playerObj and playerObj:hasItemOfName(itemName) then
			-- Get all items of this name and give the first one we find
			local items = playerObj:getItemsByName(itemName)
			for uniqueId, _ in pairs(items) do
				playerObj:removeItemFromInventory(uniqueId)
				SlotHandler.SlotHandler(plr)
				
				-- Handle tool giving
				local tool = ItemModule.GetItemTool(itemName)
				if tool then
					local toolClone = tool:Clone()
					toolClone.Parent = plr.Backpack
				else
					print("no tool")
				end
				
				break -- Only give one item
			end
		end
		dt = false
	end
end)
-- Compare this snippet from src/ReplicatedStorage/AW_Inventory/TemplateScrollFrame/Give.server.lua: