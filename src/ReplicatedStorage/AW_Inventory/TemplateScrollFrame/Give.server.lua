local dt = false
local SlotHandler = require(game.ReplicatedStorage.AW_Inventory.Modules.SlotHandler)
local plr = script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent
local Items = game.ReplicatedStorage.AW_Inventory.Items
script.Parent.MouseButton1Click:Connect(function()
	if dt == false then
		dt = true
		wait(0.5)
		dt = false
		print("too slow")
	elseif dt == true then
		local item = script.Parent.Parent.Item.Value
		if plr.SlotFolder[item].Amount.Value <= 1 then
			print(1)
			plr.SlotFolder[item]:Destroy()
			plr.Weight.Value -= Items[item].Weight
			SlotHandler.SlotHandler(plr)
            if game.ReplicatedStorage.AW_Inventory.Items[item].Tool:FindFirstChildOfClass("Tool") then  
                local t = game.ReplicatedStorage.AW_Inventory.Items[item].Tool:FindFirstChildOfClass("Tool"):Clone()
                t.Parent = plr.Backpack
            else
                print("no tool")
            end
		else
			print(2)
			plr.SlotFolder[item].Amount.Value -= 1
			plr.Weight.Value -= Items[item].Weight
			SlotHandler.SlotHandler(plr)
            
            if game.ReplicatedStorage.AW_Inventory.Items[item].Tool:FindFirstChildOfClass("Tool") then  
                local t = game.ReplicatedStorage.AW_Inventory.Items[item].Tool:FindFirstChildOfClass("Tool"):Clone()
                t.Parent = plr.Backpack
            else
                print("no tool")
            end
		end
		dt = false
	end
end)
-- Compare this snippet from src/ReplicatedStorage/AW_Inventory/TemplateScrollFrame/Give.server.lua: