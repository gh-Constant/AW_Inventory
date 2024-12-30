local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreateFrame = {}

function CreateFrame.new()
	-- Clone the template
	local template = ReplicatedStorage.AW_Inventory.TemplateScrollFrame.Template:Clone()
	
	-- Clone the interaction script
	local interactionScript = ReplicatedStorage.AW_Inventory.TemplateScrollFrame.ItemInteraction:Clone()
	interactionScript.Parent = template
	
	return template
end

return CreateFrame
