local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local InventoryDisplay = {}

-- Constants
local ITEM_SIZE = UDim2.new(0, 80, 0, 80)
local PADDING = 5
local ITEMS_PER_ROW = 5

local function createInventoryGui()
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "InventoryFrame"
    mainFrame.Size = UDim2.new(0, 450, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Inventory"
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title

    -- Scrolling Frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemsContainer"
    scrollFrame.Size = UDim2.new(1, -20, 1, -60)
    scrollFrame.Position = UDim2.new(0, 10, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = mainFrame

    -- Grid Layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = ITEM_SIZE
    gridLayout.CellPadding = UDim2.new(0, PADDING, 0, PADDING)
    gridLayout.Parent = scrollFrame

    return mainFrame
end

local function createItemFrame()
    local frame = Instance.new("Frame")
    frame.Size = ITEM_SIZE
    frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    -- Container for either ViewportFrame or ImageLabel
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 1, -25)
    container.Position = UDim2.new(0, 5, 0, 5)
    container.BackgroundTransparency = 1
    container.Parent = frame

    -- Quantity Label
    local quantityLabel = Instance.new("TextLabel")
    quantityLabel.Size = UDim2.new(1, 0, 0, 20)
    quantityLabel.Position = UDim2.new(0, 0, 1, -20)
    quantityLabel.BackgroundTransparency = 1
    quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    quantityLabel.TextSize = 14
    quantityLabel.Font = Enum.Font.GothamSemibold
    quantityLabel.Parent = frame

    return frame, container, quantityLabel
end

function InventoryDisplay:DisplayItem(itemId, itemData, container)
    local itemsFolder = ReplicatedStorage:WaitForChild("AW_Inventory"):WaitForChild("Items")
    local itemFolder = itemsFolder:FindFirstChild(itemId)
    
    if itemFolder then
        -- Check for ViewModel
        local viewModel = itemFolder:FindFirstChild("ViewModel")
        if viewModel and viewModel:FindFirstChildOfClass("Model") then
            local viewport = Instance.new("ViewportFrame")
            viewport.Size = UDim2.new(1, 0, 1, 0)
            viewport.BackgroundTransparency = 1
            viewport.Parent = container

            local model = viewModel:FindFirstChildOfClass("Model"):Clone()
            model.Parent = viewport

            -- Setup camera and lighting
            local camera = Instance.new("Camera")
            camera.Parent = viewport
            viewport.CurrentCamera = camera

            -- Position camera to view model
            -- You might need to adjust these values based on your models
            camera.CFrame = model:GetBoundingBox().CFrame * CFrame.new(0, 0, 3)
        else
            -- Check for ImageIcon
            local imageIcon = itemFolder:FindFirstChild("ImageIcon")
            if imageIcon then
                local image = Instance.new("ImageLabel")
                image.Size = UDim2.new(1, 0, 1, 0)
                image.BackgroundTransparency = 1
                image.Image = imageIcon.Image
                image.Parent = container
            end
        end
    else
        -- Use placeholder icon
        local placeholderIcon = itemsFolder:WaitForChild("IconPlaceholder")
        local image = Instance.new("ImageLabel")
        image.Size = UDim2.new(1, 0, 1, 0)
        image.BackgroundTransparency = 1
        image.Image = placeholderIcon.Image
        image.Parent = container
    end
end

function InventoryDisplay:UpdateInventory(player)
    local PlayerObject = require(ReplicatedStorage.AW_Inventory.Player.PlayerObject)
    local playerObj = PlayerObject.GetPlayerObject(player)
    if not playerObj then return end

    local inventory = playerObj:getInventory()
    if not inventory then return end

    -- Create or get the main GUI
    local gui = player.PlayerGui:FindFirstChild("InventoryGui")
    local existingEnabled = gui and gui.Enabled
    
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "InventoryGui"
        gui.Enabled = existingEnabled or false -- Keep existing state or default to false
        gui.Parent = player.PlayerGui
        
        local mainFrame = createInventoryGui()
        mainFrame.Parent = gui
    end

    local scrollFrame = gui.InventoryFrame.ItemsContainer
    
    -- Clear existing items
    scrollFrame:ClearAllChildren()
    
    -- Recreate grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = ITEM_SIZE
    gridLayout.CellPadding = UDim2.new(0, PADDING, 0, PADDING)
    gridLayout.Parent = scrollFrame

    -- Display items
    for itemId, itemData in pairs(inventory.Items) do
        local itemFrame, container, quantityLabel = createItemFrame()
        self:DisplayItem(itemId, itemData, container)
        quantityLabel.Text = tostring(itemData.quantity)
        itemFrame.Parent = scrollFrame
    end
end

return InventoryDisplay 