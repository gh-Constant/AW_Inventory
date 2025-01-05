local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViewportHandler = require(ReplicatedStorage.AW_Inventory.Modules.ViewportHandler)
local ViewportRemote = ReplicatedStorage.AW_Inventory.Remotes.Viewport

-- Handle viewport updates
ViewportRemote.OnClientEvent:Connect(function(viewportFrame, itemName)
    ViewportHandler.setupViewport(viewportFrame, itemName)
end)