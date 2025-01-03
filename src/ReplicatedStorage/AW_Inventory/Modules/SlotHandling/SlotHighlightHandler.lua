--[[ 
    SlotHighlightHandler Module
    Handles the visual feedback for slot interactions during drag and drop operations.
    
    @author Constant
    @version 1.0
]]

local SlotHighlightHandler = {}

-- Keep track of the currently highlighted slot
local currentHighlightedSlot = nil

--[[
    Highlights a slot with a visual indicator.
    @param slot (Instance) - The slot GUI element to highlight
    If the same slot is already highlighted, this function does nothing.
]]
function SlotHighlightHandler.highlightSlot(slot)
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

--[[
    Checks if a position is within the bounds of a frame
    @param position (Vector2) - The position to check
    @param frame (Instance) - The frame to check against
    @return (boolean) - Whether the position is within the frame's bounds
]]
local function isPositionInFrame(position, frame)
    return position.X >= frame.AbsolutePosition.X 
        and position.X <= frame.AbsolutePosition.X + frame.AbsoluteSize.X
        and position.Y >= frame.AbsolutePosition.Y 
        and position.Y <= frame.AbsolutePosition.Y + frame.AbsoluteSize.Y
end

--[[
    Gets the closest slot to a position.
    @param position (Vector2) - The position to check against
    @param currentFrame (Instance) - The frame being dragged
    @param targetContainer (Instance) - The container to check slots in
    @return (Instance, number, number?) - Returns the closest slot, distance, and slot number (if applicable)
]]
function SlotHighlightHandler.getClosestSlot(position, currentFrame, targetContainer, slotsFrame, inventoryFrame)
    local closestSlot = nil
    local closestDistance = math.huge
    local slotNumber = nil
    
    -- First check if we're hovering over the inventory frame
    if isPositionInFrame(position, inventoryFrame) then
        return inventoryFrame, 0, nil
    end
    
    -- Check all slots in the slotsFrame
    for _, object in ipairs(slotsFrame:GetChildren()) do
        if object:IsA("ImageLabel") and object.Name:match("^Slot%d+$") then
            -- Skip the slot if it's the current item's parent
            if currentFrame and currentFrame.Parent == object then
                continue
            end
            
            -- Check if position is within the slot's bounds first
            if isPositionInFrame(position, object) then
                local slotCenter = object.AbsolutePosition + (object.AbsoluteSize / 2)
                local distance = (Vector2.new(position.X, position.Y) - Vector2.new(slotCenter.X, slotCenter.Y)).Magnitude
                
                if distance < closestDistance then
                    closestDistance = distance
                    closestSlot = object
                    slotNumber = tonumber(object.Name:match("Slot(%d+)"))
                end
            end
        end
    end
    
    return closestSlot, closestDistance, slotNumber
end

--[[
    Gets hover target information for a position
    @param position (Vector2) - The position to check
    @param currentFrame (Instance) - The frame being dragged
    @param slotsFrame (Instance) - The slots container frame
    @param inventoryFrame (Instance) - The inventory container frame
    @return (table) - Information about what's being hovered over
]]
function SlotHighlightHandler.getHoverTarget(position, currentFrame, slotsFrame, inventoryFrame)
    local result = {
        isOverInventory = false,
        isOverSlot = false,
        slot = nil,
        slotNumber = nil,
        distance = math.huge
    }
    
    -- Check inventory first
    if isPositionInFrame(position, inventoryFrame) then
        result.isOverInventory = true
        result.distance = 0
        return result
    end
    
    -- Check slots
    for _, slot in ipairs(slotsFrame:GetChildren()) do
        if slot:IsA("ImageLabel") and slot.Name:match("^Slot%d+$") then
            -- Skip the slot if it's the current item's parent
            if currentFrame and currentFrame.Parent == slot then
                continue
            end
            
            if isPositionInFrame(position, slot) then
                local slotCenter = slot.AbsolutePosition + (slot.AbsoluteSize / 2)
                local distance = (Vector2.new(position.X, position.Y) - Vector2.new(slotCenter.X, slotCenter.Y)).Magnitude
                
                if distance < result.distance then
                    result.isOverSlot = true
                    result.slot = slot
                    result.slotNumber = tonumber(slot.Name:match("Slot(%d+)"))
                    result.distance = distance
                end
            end
        end
    end
    
    return result
end

return SlotHighlightHandler 