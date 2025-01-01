local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Draggable = require(ReplicatedStorage.Packages.Draggable)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

-- Get the EquipItem remote
local EquipItemRemote = ReplicatedStorage.AW_Inventory.Remotes.EquipItem

-- Helper function for debug prints
local function debugPrint(message, ...)
    if not SettingsModule.Debug.EnablePrints then return end
    print(string.format("[DragDrop] " .. message, ...))
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local inventoryGui = playerGui:WaitForChild("Inventory")
local mainFrame = inventoryGui:WaitForChild("Main")
local slotsFrame = mainFrame:WaitForChild("SlotsFrame")
local inventoryContainer = mainFrame:WaitForChild("InventoryFrame")
local inventoryFrame = inventoryContainer:WaitForChild("Inventory")

-- Keep track of the currently highlighted slot
local currentHighlightedSlot = nil

-- Function to highlight a slot
local function highlightSlot(slot)
    if currentHighlightedSlot == slot then return end
    
    -- Reset previous highlight if any
    if currentHighlightedSlot then
        currentHighlightedSlot.ImageColor3 = Color3.new(1, 1, 1)
        currentHighlightedSlot.ImageTransparency = 0
    end
    
    -- Highlight new slot
    if slot then
        slot.ImageColor3 = Color3.new(0, 1, 0) -- Green tint
        slot.ImageTransparency = 0.3 -- Make it slightly transparent
    end
    
    currentHighlightedSlot = slot
end

-- Helper function to get the closest slot to a position
local function getClosestSlot(position, currentFrame)
    local closestSlot = nil
    local closestDistance = math.huge
    local slotNumber = nil
    
    for _, object in ipairs(slotsFrame:GetChildren()) do
        if object:IsA("ImageLabel") and object.Name:match("^Slot%d+$") then
            -- Get the center position of the slot
            local slotCenter = object.AbsolutePosition + (object.AbsoluteSize / 2)
            -- Calculate distance using Vector2 distance
            local distance = (Vector2.new(position.X, position.Y) - Vector2.new(slotCenter.X, slotCenter.Y)).Magnitude
            
            if distance < closestDistance then
                closestDistance = distance
                closestSlot = object
                slotNumber = tonumber(object.Name:match("Slot(%d+)"))
            end
        end
    end
    
    return closestSlot, closestDistance, slotNumber
end

-- Function to handle frame dragging
local function setupDraggable(frame)
    debugPrint("Setting up draggable for frame: %s", frame.Name)
    
    local draggableObject = Draggable.new(frame)
    draggableObject:IncludeDescendants() -- Make the entire frame draggable
    
    -- Store original properties
    local originalParent = frame.Parent
    local originalPosition = frame.Position
    local originalTransparency = frame.BackgroundTransparency
    local originalZIndex = frame.ZIndex
    local originalSize = frame.Size
    
    -- When dragging starts
    draggableObject.Began:Connect(function(mousePosition)
        debugPrint("Started dragging frame: %s", frame.Name)
        
        -- Calculate absolute position before reparenting
        local absolutePosition = frame.AbsolutePosition
        local absoluteSize = frame.AbsoluteSize
        
        -- Parent to main frame for visibility outside ScrollingFrame
        frame.Parent = mainFrame
        
        -- Convert position to maintain the same screen position
        local newPosition = UDim2.new(
            0, absolutePosition.X,
            0, absolutePosition.Y
        )
        frame.Position = newPosition
        
        -- Convert size to maintain the same dimensions
        frame.Size = UDim2.new(
            0, absoluteSize.X,
            0, absoluteSize.Y
        )
        
        -- Make frame darker during drag
        frame.BackgroundTransparency = originalTransparency + 0.2
        -- Set high ZIndex to appear above other UI elements
        frame.ZIndex = 999
    end)
    
    -- While dragging
    draggableObject.Dragging:Connect(function(mousePosition)
        -- Get closest slot during drag
        local closestSlot, distance, slotNumber = getClosestSlot(mousePosition, frame)
        if closestSlot and distance < 50 then -- You can adjust this threshold
            debugPrint("Close to slot number: %d (Distance: %.2f)", slotNumber, distance)
            highlightSlot(closestSlot)
        else
            highlightSlot(nil) -- Remove highlight when not close to any slot
        end
    end)
    
    -- When dragging ends
    draggableObject.Ended:Connect(function(mousePosition)
        -- Remove any slot highlight
        highlightSlot(nil)
        
        local closestSlot, distance, slotNumber = getClosestSlot(mousePosition, frame)
        if closestSlot and distance < 50 then
            debugPrint("Dropped near slot number: %d (Distance: %.2f)", slotNumber, distance)
            
            -- Get the item name and data from the frame
            local itemName = frame.Item.Value
            -- Extract the unique ID from the frame name
            local uniqueId = frame.Name:match("_([^_]+)$") -- Gets the last part after underscore
            
            -- Call the EquipItem remote
            EquipItemRemote:FireServer(slotNumber, uniqueId)
        end
        
        -- Reset all properties
        frame.Parent = originalParent
        frame.Position = originalPosition
        frame.Size = originalSize
        frame.BackgroundTransparency = originalTransparency
        frame.ZIndex = originalZIndex
    end)
end

debugPrint("Initializing drag and drop system")

-- Setup draggable for all existing frames
for _, frame in ipairs(inventoryFrame:GetChildren()) do
    if frame:IsA("Frame") then
        setupDraggable(frame)
    end
end

-- Setup draggable for new frames
inventoryFrame.ChildAdded:Connect(function(child)
    if child:IsA("Frame") then
        setupDraggable(child)
    end
end)

debugPrint("Drag and drop system initialized") 