
-- Instances:

local InventoryClose = game.ReplicatedStorage.AW_Inventory.Modules.InventoryClose
local InventoryArranger = game.ReplicatedStorage.AW_Inventory.Modules.InventoryArranger

game.Players.PlayerAdded:Connect(function(player)
    local Inventory = Instance.new("ScreenGui")
    local InventoryFrame = Instance.new("Frame")
    local Inventory_2 = Instance.new("Frame")
    local InventoryFrame_2 = Instance.new("ScrollingFrame")
    local UIGridLayout = Instance.new("UIGridLayout")
    local UIGradient = Instance.new("UIGradient")
    local UICorner = Instance.new("UICorner")
    local TitleFrame = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local UICorner_2 = Instance.new("UICorner")
    local UIGradient_2 = Instance.new("UIGradient")
    local Weight = Instance.new("TextLabel")
    local CloseButton = Instance.new("TextButton")

    --Properties:

    Inventory.Name = "Inventory"
    Inventory.Parent = player:WaitForChild("PlayerGui")
    Inventory.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    InventoryFrame.Name = "InventoryFrame"
    InventoryFrame.Parent = Inventory
    InventoryFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InventoryFrame.BackgroundTransparency = 1.000
    InventoryFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
    InventoryFrame.Size = UDim2.new(1, 0, 1, 0)

    Inventory_2.Name = "Inventory"
    Inventory_2.Parent = InventoryFrame
    Inventory_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Inventory_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
    Inventory_2.BorderSizePixel = 0
    Inventory_2.Position = UDim2.new(0.256173879, 0, 0.22592777, 0)
    Inventory_2.Size = UDim2.new(0.486259639, 0, 0.647671282, 0)

    InventoryFrame_2.Name = "InventoryFrame"
    InventoryFrame_2.Parent = Inventory_2
    InventoryFrame_2.Active = true
    InventoryFrame_2.BackgroundColor3 = Color3.fromRGB(27, 42, 53)
    InventoryFrame_2.BackgroundTransparency = 1.000
    InventoryFrame_2.Position = UDim2.new(0.0151669942, 0, 0.0183850322, 0)
    InventoryFrame_2.Size = UDim2.new(0.970228791, 0, 0.836149096, 0)
    InventoryFrame_2.ScrollBarThickness = 7
    InventoryArranger.Parent = InventoryFrame_2

    UIGridLayout.Parent = InventoryFrame_2
    UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIGridLayout.CellPadding = UDim2.new(0.00999999978, 0, 0.00999999978, 0)
    UIGridLayout.CellSize = UDim2.new(0.150000006, 0, 0.0780000016, 0)

    UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(49, 49, 49)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(52, 52, 52))}
    UIGradient.Rotation = 90
    UIGradient.Parent = Inventory_2

    UICorner.Parent = Inventory_2

    TitleFrame.Name = "TitleFrame"
    TitleFrame.Parent = InventoryFrame
    TitleFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TitleFrame.Position = UDim2.new(0.256241053, 0, 0.175127104, 0)
    TitleFrame.Size = UDim2.new(0.4866274, 0, 0.0500772893, 0)

    Title.Name = "Title"
    Title.Parent = TitleFrame
    Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1.000
    Title.BorderColor3 = Color3.fromRGB(27, 42, 53)
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.Font = Enum.Font.Roboto
    Title.Text = "INVENTORY"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    Title.TextSize = 14.000
    Title.TextWrapped = true

    UICorner_2.Parent = TitleFrame

    UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(49, 49, 49)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(52, 52, 52))}
    UIGradient_2.Rotation = 90
    UIGradient_2.Parent = TitleFrame

    Weight.Name = "Weight"
    Weight.Parent = TitleFrame
    Weight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Weight.BackgroundTransparency = 1.000
    Weight.BorderColor3 = Color3.fromRGB(27, 42, 53)
    Weight.Size = UDim2.new(0.200000018, 0, 1.01444566, 0)
    Weight.Font = Enum.Font.SourceSans
    Weight.Text = "1/2000"
    Weight.TextColor3 = Color3.fromRGB(255, 255, 255)
    Weight.TextScaled = true
    Weight.TextSize = 14.000
    Weight.TextWrapped = true

    CloseButton.Name = "CloseButton"
    CloseButton.Parent = TitleFrame
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.BackgroundTransparency = 1.000
    CloseButton.BorderColor3 = Color3.fromRGB(27, 42, 53)
    CloseButton.Position = UDim2.new(0.938930631, 0, -0.209471703, 0)
    CloseButton.Size = UDim2.new(0.0846030787, 0, 1.19139719, 0)
    CloseButton.Font = Enum.Font.SourceSans
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 0, 4)
    CloseButton.TextScaled = true
    CloseButton.TextSize = 14.000
    CloseButton.TextWrapped = true

    InventoryClose.Parent = CloseButton
end)

