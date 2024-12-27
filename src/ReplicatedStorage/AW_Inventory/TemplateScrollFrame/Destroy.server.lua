local dt = false
local SlotHandler = require(game.ReplicatedStorage.AW_Inventory.Modules.SlotHandler)
local PlayerObject = require(game.ServerScriptService.AW_Inventory.Player.PlayerObject)

local plr = script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent

script.Parent.MouseButton2Click:Connect(function()
	if dt == false then
		dt = true
		wait(0.5)
		dt = false
		print("too slow")
	elseif dt == true then
		local itemName = script.Parent.Parent.Item.Value -- This is the name of the item
		local playerObj = PlayerObject.GetPlayerObject(plr)
		
		if playerObj and playerObj:hasItemOfName(itemName) then
			-- Get all items of this name and remove the first one we find
			local items = playerObj:getItemsByName(itemName)
			for uniqueId, _ in pairs(items) do
				playerObj:removeItemFromInventory(uniqueId)
				SlotHandler.SlotHandler(plr)
				break -- Only remove one item
			end
		end
		dt = false
	end
end)
