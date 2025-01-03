local SettingsModule = require(game.ReplicatedStorage.AW_Inventory.SettingsModule)
local FrameManager = require(script.Parent.FrameManager)

local EquipmentManager = {}

-- Helper function to clear slots
local function clearSlots(slotsFrame)
	for _, slot in pairs(slotsFrame:GetChildren()) do
		if slot:IsA("ImageLabel") and slot.Name:match("^Slot%d+$") then
			for _, child in pairs(slot:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end
		end
	end
end

function EquipmentManager.handleEquippedItems(plr, equipped, itemsFolder)
	if not equipped then return end
	
	if SettingsModule.Debug.ShowItemProcessing then
		print("Processing equipped items for player:", plr.Name)
	end
	
	-- Get references to both inventory and hotbar GUIs
	local inventoryGui = plr.PlayerGui:WaitForChild("Inventory")
	local mainFrame = inventoryGui:WaitForChild("Main")
	local inventorySlotsFrame = mainFrame:WaitForChild("SlotsFrame")
	local hotbarGui = plr.PlayerGui:WaitForChild("Hotbar")
	local hotbarSlotsFrame = hotbarGui:WaitForChild("Main"):WaitForChild("SlotsFrame")
	
	-- Clear existing equipped items from both frames
	clearSlots(inventorySlotsFrame)
	clearSlots(hotbarSlotsFrame)
	
	-- Process equipped items for both frames
	for slotNumber, itemData in pairs(equipped) do
		if SettingsModule.Debug.ShowItemProcessing then
			print("Processing equipped item in slot " .. tostring(slotNumber) .. ": " .. 
				tostring(itemData.name) .. " (ID: " .. tostring(itemData.id) .. ")")
		end
		
		local itemFolder = itemsFolder:FindFirstChild(itemData.name)
		if not itemFolder then
			warn("Item folder not found for equipped item:", itemData.name)
			continue
		end
		
		-- Handle inventory slots
		local inventorySlot = inventorySlotsFrame:FindFirstChild("Slot" .. slotNumber)
		if inventorySlot then
			FrameManager.createEquippedFrame(inventorySlot, itemData, itemFolder, plr)
		end
		
		-- Handle hotbar slots
		local hotbarSlot = hotbarSlotsFrame:FindFirstChild("Slot" .. slotNumber)
		if hotbarSlot then
			FrameManager.createEquippedFrame(hotbarSlot, itemData, itemFolder, plr)
		end
	end
	
	if SettingsModule.Debug.ShowItemProcessing then
		print("Finished processing equipped items for player:", plr.Name)
	end
end

return EquipmentManager 