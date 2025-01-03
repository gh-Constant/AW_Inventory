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
local SwapEquippedItemsRemote = ReplicatedStorage.AW_Inventory.Remotes.SwapEquipped

--[[
    Helper function for debug prints
    @param message (string) - The message to print
    @param ... (any) - Additional arguments for string formatting
]]
local function debugPrint(message, ...)
    if not SettingsModule.Debug.EnablePrints then return end
    print(string.format("[DraggableHandler] " .. message, ...))
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
    Sets up draggable behavior for a frame
    @param frame (Instance) - The frame to make draggable
    @param isEquippedItem (boolean) - Whether the item is currently equipped
    @param mainFrame (Instance) - The main UI frame
    @param inventoryFrame (Instance) - The inventory container frame
    @param slotsFrame (Instance) - The slots container frame
]]
function DraggableHandler.setupDraggable(frame, isEquippedItem, mainFrame, inventoryFrame, slotsFrame)
    debugPrint("Setting up draggable for frame: %s (Equipped: %s)", frame.Name, tostring(isEquippedItem))
    
    local draggableObject = Draggable.new(frame)
    draggableObject:IncludeDescendants()
    
    local originalParent = frame.Parent
    local originalPosition = frame.Position
    local originalTransparency = frame.BackgroundTransparency
    local originalZIndex = frame.ZIndex
    local originalSize = frame.Size
    local originalSlotNumber = isEquippedItem and getSlotNumber(originalParent) or nil
    
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
        local closest, distance = SlotHighlightHandler.getClosestSlot(mousePosition, frame, targetContainer, slotsFrame, inventoryFrame)
        
        if closest and distance < 50 then
            if isEquippedItem then
                -- Check if we're hovering over another equipped slot or inventory
                if closest.Parent == slotsFrame then
                    -- Highlight the equipped slot for swapping
                    SlotHighlightHandler.highlightSlot(closest)
                else
                    -- When dragging to inventory, highlight the inventory frame
                    inventoryFrame.BackgroundColor3 = Color3.new(0, 1, 0)
                    inventoryFrame.BackgroundTransparency = 0.9
                end
            else
                -- When dragging from inventory to slots, highlight the slot
                SlotHighlightHandler.highlightSlot(closest)
            end
        else
            -- Reset highlights
            SlotHighlightHandler.highlightSlot(nil)
            inventoryFrame.BackgroundColor3 = Color3.new(1, 1, 1)
            inventoryFrame.BackgroundTransparency = 1
        end
    end)
    
    draggableObject.Ended:Connect(function(mousePosition)
        -- Reset highlights
        SlotHighlightHandler.highlightSlot(nil)
        inventoryFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        inventoryFrame.BackgroundTransparency = 1
        
        local targetContainer = isEquippedItem and inventoryFrame or slotsFrame
        local closest, distance, slotNumber = SlotHighlightHandler.getClosestSlot(mousePosition, frame, targetContainer, slotsFrame, inventoryFrame)
        
        if closest and distance < 50 then
            local uniqueId = frame.Name:match("_([^_]+)$")
            
            if isEquippedItem then
                if closest.Parent == slotsFrame then
                    -- Swapping between equipped slots
                    local targetSlotNumber = getSlotNumber(closest)
                    if targetSlotNumber ~= originalSlotNumber then
                        debugPrint("Swapping items between slots %d and %d", originalSlotNumber, targetSlotNumber)
                        SwapEquippedItemsRemote:FireServer(originalSlotNumber, targetSlotNumber)
                    end
                else
                    -- Unequipping to inventory
                    debugPrint("Unequipping item with ID: %s", uniqueId)
                    UnequipItemRemote:FireServer(uniqueId)
                end
            else
                -- Equipping from inventory to slot
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

return DraggableHandler