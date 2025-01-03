local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local CreateFrame = require(ReplicatedStorage.AW_Inventory.TemplateScrollFrame.CreateFrame)

local FrameManager = {}

-- Helper function to create frame name
local function createFrameName(itemName, itemData, uniqueId)
	local frameName = itemName
	if itemData.data then
		for key, value in pairs(itemData.data) do
			frameName = frameName .. SettingsModule.FrameNameSeparator .. 
					   tostring(key) .. SettingsModule.PropertyValueSeparator .. tostring(value)
		end
	end
	return frameName .. SettingsModule.FrameNameSeparator .. uniqueId
end

-- Helper function to set frame gradients
local function setFrameGradients(frame, rarity)
	-- Create base gradient for BG
	local baseGradient = SettingsModule.RarityGradient[rarity]:Clone()
	baseGradient.Parent = frame.BG
	
	-- Create darker gradient for frame
	local frameGradient = SettingsModule.RarityGradient[rarity]:Clone()
	
	-- Create new keypoints with darker colors
	local newKeypoints = {}
	for _, keypoint in ipairs(frameGradient.Color.Keypoints) do
		local darkerColor = keypoint.Value:Lerp(Color3.new(0, 0, 0), SettingsModule.BGGradientDarkness)
		local newKeypoint = ColorSequenceKeypoint.new(keypoint.Time, darkerColor)
		table.insert(newKeypoints, newKeypoint)
	end
	
	-- Apply new keypoints to the gradient
	frameGradient.Color = ColorSequence.new(newKeypoints)
	frameGradient.Parent = frame
end

-- Helper function to set view type
local function setViewType(frame, itemFolder, plr, itemName)
	if not itemFolder:FindFirstChild("ViewType") then
		warn("ViewType not found for item:", itemName)
		return
	end
	
	local viewType = itemFolder.ViewType.Value
	if SettingsModule.Debug.ShowItemProcessing then
		print("Item view type:", viewType)
	end
	
	if viewType == SettingsModule.ViewTypes.VIEWPORT then
		frame.BG.Main.ViewportTemplate.Visible = true
		frame.BG.Main.ImageTemplate.Visible = false
		
		if SettingsModule.Debug.ShowItemProcessing then
			print("Firing viewport update for:", itemName)
		end
		ReplicatedStorage.AW_Inventory.Remotes.Viewport:FireClient(
			plr,
			frame.BG.Main.ViewportTemplate,
			tostring(itemName)
		)
	elseif viewType == SettingsModule.ViewTypes.IMAGE and itemFolder:FindFirstChild("ImageIcon") then
		frame.BG.Main.ImageTemplate.Image = itemFolder.ImageIcon.Image
		frame.BG.Main.ViewportTemplate.Visible = false
		frame.BG.Main.ImageTemplate.Visible = true
		if SettingsModule.Debug.ShowItemProcessing then
			print("Set image for item:", itemName)
		end
	else
		warn("ViewType not set or invalid for item:", itemName)
	end
end

function FrameManager.createInventoryFrame(itemName, itemData, uniqueId, itemFolder, plr, layoutOrder)
	local frametemplate = CreateFrame.new()
	frametemplate.Name = createFrameName(itemName, itemData, uniqueId)
	frametemplate.LayoutOrder = layoutOrder
	frametemplate.Item.Value = itemName
	
	-- Set frame size based on grid size
	if itemFolder:FindFirstChild("GridSize") then
		local gridSize = itemFolder.GridSize.Value
		local width = SettingsModule.SlotSize.X * gridSize.X + SettingsModule.GridPadding.X * (gridSize.X - 1)
		local height = SettingsModule.SlotSize.Y * gridSize.Y + SettingsModule.GridPadding.Y * (gridSize.Y - 1)
		frametemplate.Size = UDim2.new(width, 0, height, 0)
	end
	
	-- Set rarity color if exists
	if itemFolder:FindFirstChild("Rarity") then
		setFrameGradients(frametemplate, itemFolder.Rarity.Value)
	end
	
	-- Set view type
	setViewType(frametemplate, itemFolder, plr, itemName)
	
	return frametemplate
end

function FrameManager.createEquippedFrame(slot, itemData, itemFolder, plr)
	local frametemplate = CreateFrame.new()
	frametemplate.Parent = slot
	frametemplate.Name = createFrameName(itemData.name, itemData, itemData.id)
	frametemplate.Item.Value = itemData.name
	
	-- Set frame to fill the slot
	frametemplate.Size = UDim2.fromScale(1, 1)
	frametemplate.Position = UDim2.fromScale(0, 0)
	
	-- Set rarity color if exists
	if itemFolder:FindFirstChild("Rarity") then
		setFrameGradients(frametemplate, itemFolder.Rarity.Value)
	end
	
	-- Set view type
	setViewType(frametemplate, itemFolder, plr, itemData.name)
	
	-- Hide quantity label for equipped items
	frametemplate.BG.Main.Quantity.Visible = false
	
	return frametemplate
end

return FrameManager 