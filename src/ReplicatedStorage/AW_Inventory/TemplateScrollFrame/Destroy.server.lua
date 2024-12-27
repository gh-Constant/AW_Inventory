local dt = false
local SlotHandler = require(game.ReplicatedStorage.AW_Inventory.Modules.SlotHandler)
local plr = script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent
script.Parent.MouseButton2Click:Connect(function()
	if dt == false then
		dt = true
		wait(0.5)
		dt = false
		print("too slow")
	elseif dt == true then
		local item = script.Parent.Parent.Item.Value
		if plr.SlotFolder[item].Amount.Value == 1 then
			plr.SlotFolder[item]:Destroy()
			--plr.Weight.Value -= Items[item].Weight.Value
			SlotHandler.SlotHandler(plr)
		else
			plr.SlotFolder[item].Amount.Value -= 1
			-- plr.Weight.Value -= Items[item].Weight.Value
			SlotHandler.SlotHandler(plr)
		end
		dt = false
	end
end)
