--[[
    DraggableHandler Module
    Manages the dragging behavior of inventory items and equipped items.
    
    @author Constant
    @version 1.0
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Draggable = require(ReplicatedStorage.Packages.Draggable)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local SlotHighlightHandler = require(script.Parent.SlotHighlightHandler)

local DraggableHandler = {}

-- Get the remotes
local EquipItemRemote = ReplicatedStorage.AW_Inventory.Remotes.EquipItem
local UnequipItemRemote = ReplicatedStorage.AW_Inventory.Remotes.UnequipItem
local SwapEquippedItemsRemote = ReplicatedStorage.AW_Inventory.Remotes.SwapEquippedItems
local DeleteItemRemote = ReplicatedStorage.AW_Inventory.Remotes.DeleteItem

-- Constants for deletion
local DELETE_HIGHLIGHT_COLOR = Color3.new(1, 0, 0) -- Red color for delete highlight

--[[
    Helper function for debug prints
    @param message (string) - The message to print
    @param ... (any) - Additional arguments for string formatting
]]
local function debugPrint(message, ...)
    if not SettingsModule.Debug.EnablePrints then return end
    local args = {...}
    local success, result = pcall(function()
        return string.format(message, unpack(args))
    end)
    if success then
        print("[DraggableHandler] " .. result)
    end
end

--[[
    Gets the slot number from a frame or its parent
    @param frame (Instance) - The frame to check
    @return (number?) - The slot number if found
]]
local function getSlotNumber(frame)
    local slotFrame = frame
    if not frame.Name:match("^Slot%d+$") then
        slotFrame = frame.Parent
    end
    return tonumber(slotFrame.Name:match("Slot(%d+)"))
end

--[[
    Gets the item name from a frame by checking various possible sources
    @param frame Instance - The frame to get the name from
    @return string - The item name
]]
local function getItemName(frame)
    -- First try to get from Item StringValue
    local itemValue = frame:FindFirstChild("Item")
    if itemValue and itemValue:IsA("StringValue") then
        return itemValue.Value
    end
    
    -- If no StringValue, get from frame name (everything before the underscore)
    local frameName = frame.Name
    local itemName = frameName:match("^(.-)_")
    if itemName then
        return itemName
    end
    
    -- Fallback to Unknown Item if no pattern match
    return "Unknown Item"
end

--[[
    Shows the confirmation UI for item deletion
    @param mainFrame (Instance) - The main UI frame
    @param itemName (string) - The name of the item
    @param itemId (string) - The unique ID of the item
    @param callback (function) - Function to call when confirmed
]]
local function showConfirmationUI(mainFrame, itemName, itemId, callback)
    local confirmScreen = mainFrame:WaitForChild("ConfirmationScreen")
    local background = confirmScreen:WaitForChild("Background")
    local buttons = background:WaitForChild("Buttons")
    local destroyText = background:WaitForChild("DestroyText")
    
    -- Set the text
    destroyText.Text = string.format("Are you sure you want to destroy:\n\n%s\nID: %s", itemName, itemId)
    
    -- Show the confirmation screen
    confirmScreen.Visible = true
    
    -- Connect button events
    local destroyButton = buttons:WaitForChild("Destroy")
    local cancelButton = buttons:WaitForChild("Cancel")
    
    -- Store connections to disconnect them later
    local destroyConnection
    local cancelConnection
    
    local function cleanup()
        confirmScreen.Visible = false
        if destroyConnection then
            destroyConnection:Disconnect()
        end
        if cancelConnection then
            cancelConnection:Disconnect()
        end
    end
    
    destroyConnection = destroyButton.MouseButton1Click:Connect(function()
        cleanup()
        callback()
    end)
    
    cancelConnection = cancelButton.MouseButton1Click:Connect(function()
        cleanup()
    end)
end

--[[
    Checks if a point is inside any of the given frames
    @param point Vector2 - The point to check
    @param frames {GuiObject} - Array of frames to check against
    @return boolean - Whether the point is inside any of the frames
]]
local function isPointInFrames(point, frames)
    for _, frame in ipairs(frames) do
        local framePos = frame.AbsolutePosition
        local frameSize = frame.AbsoluteSize
        
        -- Debug print frame bounds
        debugPrint("Frame %s bounds: X(%d-%d) Y(%d-%d)", frame.Name,
            framePos.X, framePos.X + frameSize.X,
            framePos.Y, framePos.Y + frameSize.Y)
        
        if point.X >= framePos.X and point.X <= framePos.X + frameSize.X
            and point.Y >= framePos.Y and point.Y <= framePos.Y + frameSize.Y then
            return true
        end
    end
    return false
end

--[[
    Sets up draggable behavior for a frame
    @param frame (Instance) - The frame to make draggable
    @param isEquippedItem (boolean) - Whether the item is currently equipped
    @param mainFrame (Instance) - The main UI frame
    @param inventoryFrame (Instance) - The inventory container frame
    @param slotsFrame (Instance) - The slots container frame
]]
function DraggableHandler.setupDraggable(frame, isEquippedItem, mainFrame, inventoryFrame, slotsFrame)
    local draggableObject = Draggable.new(frame)
    draggableObject:IncludeDescendants()
    
    local originalParent = frame.Parent
    local originalPosition = frame.Position
    local originalTransparency = frame.BackgroundTransparency
    local originalZIndex = frame.ZIndex
    local originalSize = frame.Size
    local originalSlotNumber = isEquippedItem and getSlotNumber(originalParent) or nil
    local originalColor = frame.BackgroundColor3
    
    -- Get item information
    local itemName = getItemName(frame)
    local uniqueId = frame.Name:match("_([^_]+)$") or "Unknown ID"
    
    -- Get the delete frame
    local deleteFrame = mainFrame:WaitForChild("DeleteFrame")
    
    draggableObject.Began:Connect(function(mousePosition)
        debugPrint("Drag began at X:%d Y:%d", mousePosition.X, mousePosition.Y)
        
        -- Calculate absolute position before reparenting
        local absolutePosition = frame.AbsolutePosition
        local absoluteSize = frame.AbsoluteSize
        
        -- Parent to main frame for visibility
        frame.Parent = mainFrame
        
        -- Convert position to maintain the same screen position
        frame.Position = UDim2.new(
            0, absolutePosition.X,
            0, absolutePosition.Y
        )
        
        -- Convert size to maintain the same dimensions
        frame.Size = UDim2.new(
            0, absoluteSize.X,
            0, absoluteSize.Y
        )
        
        frame.ZIndex = 999
    end)
    
    draggableObject.Dragging:Connect(function(mousePosition)
        -- Check if mouse is over the delete frame
        local isOverDeleteFrame = isPointInFrames(mousePosition, {deleteFrame})
        
        if not isOverDeleteFrame then
            frame.BackgroundColor3 = DELETE_HIGHLIGHT_COLOR
            debugPrint("Setting delete highlight color - not over delete frame")
        else
            frame.BackgroundColor3 = originalColor
            
            local hoverInfo = SlotHighlightHandler.getHoverTarget(mousePosition, frame, slotsFrame, inventoryFrame)
            
            -- Reset all highlights first
            SlotHighlightHandler.highlightSlot(nil)
            inventoryFrame.BackgroundColor3 = Color3.new(1, 1, 1)
            inventoryFrame.BackgroundTransparency = 1
            
            if isEquippedItem then
                if hoverInfo.isOverInventory then
                    inventoryFrame.BackgroundColor3 = Color3.new(0, 1, 0)
                    inventoryFrame.BackgroundTransparency = 0.9
                elseif hoverInfo.isOverSlot then
                    SlotHighlightHandler.highlightSlot(hoverInfo.slot)
                end
            else
                if hoverInfo.isOverSlot then
                    SlotHighlightHandler.highlightSlot(hoverInfo.slot)
                end
            end
        end
    end)
    
    draggableObject.Ended:Connect(function(mousePosition)
        -- Check if mouse is over the delete frame
        local isOverDeleteFrame = isPointInFrames(mousePosition, {deleteFrame})
        debugPrint("Drag ended - Over delete frame: " .. tostring(isOverDeleteFrame))
        
        if not isOverDeleteFrame then
            debugPrint("Showing delete confirmation for item %s (%s)", itemName, uniqueId)
            -- Show confirmation UI
            showConfirmationUI(mainFrame, itemName, uniqueId, function()
                debugPrint("Deleting item with ID: %s", uniqueId)
                DeleteItemRemote:FireServer(uniqueId, isEquippedItem)
            end)
        else
            local hoverInfo = SlotHighlightHandler.getHoverTarget(mousePosition, frame, slotsFrame, inventoryFrame)
            
            if (hoverInfo.isOverSlot or hoverInfo.isOverInventory) and hoverInfo.distance < 50 then
                if isEquippedItem then
                    if hoverInfo.isOverSlot and hoverInfo.slotNumber ~= originalSlotNumber then
                        debugPrint("Swapping items between slots %d and %d", originalSlotNumber, hoverInfo.slotNumber)
                        SwapEquippedItemsRemote:FireServer(originalSlotNumber, hoverInfo.slotNumber)
                    elseif hoverInfo.isOverInventory then
                        debugPrint("Unequipping item with ID: %s", uniqueId)
                        UnequipItemRemote:FireServer(uniqueId)
                    end
                else
                    if hoverInfo.isOverSlot then
                        debugPrint("Equipping item to slot %d with ID: %s", hoverInfo.slotNumber, uniqueId)
                        EquipItemRemote:FireServer(hoverInfo.slotNumber, uniqueId)
                    end
                end
            end
        end
        
        -- Reset frame properties
        frame.Parent = originalParent
        frame.Position = originalPosition
        frame.Size = originalSize
        frame.BackgroundTransparency = originalTransparency
        frame.ZIndex = originalZIndex
        frame.BackgroundColor3 = originalColor

        -- Reset inventory frame highlight
        inventoryFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        inventoryFrame.BackgroundTransparency = 1

        -- Reset slot highlights
        SlotHighlightHandler.highlightSlot(nil)
    end)
end

return DraggableHandler