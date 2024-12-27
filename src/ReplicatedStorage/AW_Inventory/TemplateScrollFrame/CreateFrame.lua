local CreateFrame = {}

function CreateFrame.new()
	-- Instances:
	local TemplateImage = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local Template = Instance.new("Frame")
	local ViewportTemplate = Instance.new("ViewportFrame")
	local ImageTemplate = Instance.new("ImageLabel")
	local TextLabel = Instance.new("TextLabel")
	local Frame = Instance.new("Frame")
	local UICorner_2 = Instance.new("UICorner")
	local UIGradient = Instance.new("UIGradient")
	local TextButton = Instance.new("TextButton")
	local ItemValue = Instance.new("StringValue")

	-- Properties:
	TemplateImage.Name = "TemplateImage"
	TemplateImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TemplateImage.BorderColor3 = Color3.fromRGB(103, 103, 103)
	TemplateImage.Position = UDim2.new(0.232676893, 0, 0.533389866, 0)
	TemplateImage.Size = UDim2.new(0.0463165566, 0, 0.0904476494, 0)
	TemplateImage.ZIndex = 2

	UICorner.Parent = TemplateImage

	Template.Name = "Template"
	Template.Parent = TemplateImage
	Template.BackgroundColor3 = Color3.fromRGB(81, 81, 81)
	Template.BackgroundTransparency = 1.000
	Template.BorderColor3 = Color3.fromRGB(27, 42, 53)
	Template.Size = UDim2.new(1, 0, 1, 0)

	ViewportTemplate.Name = "ViewportTemplate"
	ViewportTemplate.Parent = Template
	ViewportTemplate.BackgroundTransparency = 1.000
	ViewportTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ViewportTemplate.BorderColor3 = Color3.fromRGB(27, 42, 53)
	ViewportTemplate.Position = UDim2.new(0.0318571329, 0, 0.0440782718, 0)

	ImageTemplate.Name = "ImageTemplate"
	ImageTemplate.Parent = Template
	ImageTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageTemplate.BackgroundTransparency = 1.000
	ImageTemplate.Position = UDim2.new(0.120663621, 0, 0.165892318, 0)
	ImageTemplate.Size = UDim2.new(0.75, 0, 0.699050128, 0)
	ImageTemplate.Image = "rbxassetid://7265056756"

	TextLabel.Parent = Template
	TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.BackgroundTransparency = 1.000
	TextLabel.BorderColor3 = Color3.fromRGB(27, 42, 53)
	TextLabel.Position = UDim2.new(0.587118804, 0, 0.560448468, 0)
	TextLabel.Size = UDim2.new(0.381385237, 0, 0.423131406, 0)
	TextLabel.Font = Enum.Font.SourceSans
	TextLabel.Text = "100"
	TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.TextScaled = true
	TextLabel.TextSize = 14.000
	TextLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.TextWrapped = true

	Frame.Parent = TemplateImage
	Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Frame.BorderColor3 = Color3.fromRGB(103, 103, 103)
	Frame.Position = UDim2.new(0.0318572596, 0, 0.0345626138, 0)
	Frame.Size = UDim2.new(0.942246735, 0, 0.945354164, 0)
	Frame.ZIndex = 0

	UICorner_2.Parent = Frame

	UIGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(56, 56, 56)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(48, 48, 48)),
	})
	UIGradient.Rotation = 90
	UIGradient.Parent = Frame

	TextButton.Parent = TemplateImage
	TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextButton.BackgroundTransparency = 1.000
	TextButton.BorderColor3 = Color3.fromRGB(27, 42, 53)
	TextButton.Size = UDim2.new(1, 0, 1, 0)
	TextButton.AutoButtonColor = false
	TextButton.Font = Enum.Font.SourceSans
	TextButton.Text = " "
	TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	TextButton.TextSize = 14.000

	-- Add Item StringValue
	ItemValue.Name = "Item"
	ItemValue.Parent = TemplateImage

	-- Add Destroy script
	local DestroyScript = script.Parent.Destroy:Clone()
	DestroyScript.Parent = TemplateImage

	-- Add Give script
	local giveScript = script.Parent.Give:Clone()
	giveScript.Parent = TemplateImage

	return TemplateImage
end

return CreateFrame
