local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SlotHandler = require(ReplicatedStorage.AW_Inventory.Modules.SlotHandler)

-- Get the remote event
local UpdateInventoryRemote = ReplicatedStorage.AW_Inventory.Remotes.UpdateInventory

-- Handle update requests from clients
UpdateInventoryRemote.OnServerEvent:Connect(function(player)
    -- Call SlotHandler to update the player's inventory
    SlotHandler.SlotHandler(player)
end) 