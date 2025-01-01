local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Draggable = require(ReplicatedStorage.Packages.Draggable)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

-- Get the EquipItem remote
local EquipItemRemote = ReplicatedStorage.AW_Inventory.Remotes.EquipItem
local UnequipItemRemote = ReplicatedStorage.AW_Inventory.Remotes.UnequipItem

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
local function getClosestSlot(position, currentFrame, targetContainer)
    local closestSlot = nil
    local closestDistance = math.huge
    local slotNumber = nil
    
    -- If targeting inventory, just return the inventory frame if position is over it
    if targetContainer == inventoryFrame then
        local frame = inventoryFrame
        local isInBounds = position.X >= frame.AbsolutePosition.X 
            and position.X <= frame.AbsolutePosition.X + frame.AbsoluteSize.X
            and position.Y >= frame.AbsolutePosition.Y 
            and position.Y <= frame.AbsolutePosition.Y + frame.AbsoluteSize.Y
            
        return isInBounds and frame or nil, isInBounds and 0 or math.huge, nil
    end
    
    -- Original slot finding logic for SlotsFrame
    for _, object in ipairs(slotsFrame:GetChildren()) do
        if object:IsA("ImageLabel") and object.Name:match("^Slot%d+$") then
            local slotCenter = object.AbsolutePosition + (object.AbsoluteSize / 2)
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
local function setupDraggable(frame, isEquippedItem)
    debugPrint("Setting up draggable for frame: %s (Equipped: %s)", frame.Name, tostring(isEquippedItem))
    
    local draggableObject = Draggable.new(frame)
    draggableObject:IncludeDescendants()
    
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
    
    draggableObject.Dragging:Connect(function(mousePosition)
        -- Check closest slot or inventory frame based on where the item came from
        local targetContainer = isEquippedItem and inventoryFrame or slotsFrame
        local closest, distance = getClosestSlot(mousePosition, frame, targetContainer)
        
        if closest and distance < 50 then
            if isEquippedItem then
                -- When dragging from slots to inventory, highlight the inventory frame
                inventoryFrame.BackgroundColor3 = Color3.new(0, 1, 0)
                inventoryFrame.BackgroundTransparency = 0.9
            else
                -- When dragging from inventory to slots, highlight the slot
                highlightSlot(closest)
            end
        else
            if isEquippedItem then
                inventoryFrame.BackgroundColor3 = Color3.new(1, 1, 1)
                inventoryFrame.BackgroundTransparency = 1
            else
                highlightSlot(nil)
            end
        end
    end)
    
    draggableObject.Ended:Connect(function(mousePosition)
        -- Reset highlights
        highlightSlot(nil)
        inventoryFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        inventoryFrame.BackgroundTransparency = 1
        
        local targetContainer = isEquippedItem and inventoryFrame or slotsFrame
        local closest, distance, slotNumber = getClosestSlot(mousePosition, frame, targetContainer)
        
        if closest and distance < 50 then
            local uniqueId = frame.Name:match("_([^_]+)$")
            
            if isEquippedItem then
                -- If dropping an equipped item into inventory
                debugPrint("Unequipping item with ID: %s", uniqueId)
                UnequipItemRemote:FireServer(uniqueId)
            else
                -- If dropping an inventory item into a slot
                debugPrint("Equipping item to slot %d with ID: %s", slotNumber, uniqueId)
                EquipItemRemote:FireServer(slotNumber, uniqueId)
            end
        end
        
        -- Reset frame properties
        frame.Parent = originalParent
        frame.Position = originalPosition
        frame.Size = originalSize
        frame.BackgroundTransparency = originalTransparency
        frame.ZIndex = originalZIndex
    end)
end

debugPrint("Initializing drag and drop system")

-- Setup draggable for all existing inventory frames
for _, frame in ipairs(inventoryFrame:GetChildren()) do
    if frame:IsA("Frame") then
        setupDraggable(frame, false)
    end
end

-- Setup draggable for all existing slot frames
for _, slot in ipairs(slotsFrame:GetChildren()) do
    if slot:IsA("ImageLabel") and slot.Name:match("^Slot%d+$") then
        for _, frame in ipairs(slot:GetChildren()) do
            if frame:IsA("Frame") then
                setupDraggable(frame, true)
            end
        end
        
        -- Watch for new frames added to slots
        slot.ChildAdded:Connect(function(child)
            if child:IsA("Frame") then
                setupDraggable(child, true)
            end
        end)
    end
end

-- Watch for new inventory frames
inventoryFrame.ChildAdded:Connect(function(child)
    if child:IsA("Frame") then
        setupDraggable(child, false)
    end
end)

debugPrint("Drag and drop system initialized") 