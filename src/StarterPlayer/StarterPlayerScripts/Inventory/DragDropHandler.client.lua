--[[
    DragDropHandler
    Main script that handles drag and drop functionality for the inventory system.
    Manages the initialization and setup of draggable items in both inventory and equipped slots.
    
    @author Constant
    @version 1.0
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local DraggableHandler = require(ReplicatedStorage.AW_Inventory.Modules.SlotHandling.DraggableHandler)

-- Helper function for debug prints
local function debugPrint(message, ...)
    if not SettingsModule.Debug.EnablePrints then return end
    print(string.format("[DragDrop] " .. message, ...))
end

-- Get player GUI references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local inventoryGui = playerGui:WaitForChild("Inventory")
local mainFrame = inventoryGui:WaitForChild("Main")
local slotsFrame = mainFrame:WaitForChild("SlotsFrame")
local inventoryContainer = mainFrame:WaitForChild("InventoryFrame")
local inventoryFrame = inventoryContainer:WaitForChild("Inventory")

debugPrint("Initializing drag and drop system")

--[[
    Initialize draggable behavior for inventory items
    @param frame (Instance) - The frame to initialize
]]
local function initializeInventoryItem(frame)
    DraggableHandler.setupDraggable(frame, false, mainFrame, inventoryFrame, slotsFrame)
end

--[[
    Initialize draggable behavior for equipped items
    @param frame (Instance) - The frame to initialize
]]
local function initializeEquippedItem(frame)
    DraggableHandler.setupDraggable(frame, true, mainFrame, inventoryFrame, slotsFrame)
end

-- Setup draggable for all existing inventory frames
for _, frame in ipairs(inventoryFrame:GetChildren()) do
    if frame:IsA("Frame") then
        initializeInventoryItem(frame)
    end
end

-- Setup draggable for all existing slot frames
for _, slot in ipairs(slotsFrame:GetChildren()) do
    if slot:IsA("ImageLabel") and slot.Name:match("^Slot%d+$") then
        for _, frame in ipairs(slot:GetChildren()) do
            if frame:IsA("Frame") then
                initializeEquippedItem(frame)
            end
        end
        
        -- Watch for new frames added to slots
        slot.ChildAdded:Connect(function(child)
            if child:IsA("Frame") then
                initializeEquippedItem(child)
            end
        end)
    end
end

-- Watch for new inventory frames
inventoryFrame.ChildAdded:Connect(function(child)
    if child:IsA("Frame") then
        initializeInventoryItem(child)
    end
end)

debugPrint("Drag and drop system initialized") 