local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local UIEffects = require(script.Parent.UIEffects)

local InventoryUIManager = {}

local isInventoryOpen = false
local isTweening = false

function InventoryUIManager.initialize()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local inventoryGui = playerGui:WaitForChild("Inventory")
    local mainFrame = inventoryGui:WaitForChild("Main")
    local hotbarGui = playerGui:WaitForChild("Hotbar")

    -- Create blur effect
    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Size = 0
    blurEffect.Enabled = false
    blurEffect.Parent = Lighting

    -- Store original position
    local originalPosition = mainFrame.Position
    local offscreenPosition = UDim2.new(
        originalPosition.X.Scale, 
        originalPosition.X.Offset,
        -1,
        originalPosition.Y.Offset
    )

    -- Set initial state
    mainFrame.Position = offscreenPosition
    mainFrame.Visible = false
    hotbarGui.Enabled = true
    blurEffect.Enabled = false

    return {
        mainFrame = mainFrame,
        hotbarGui = hotbarGui,
        blurEffect = blurEffect,
        originalPosition = originalPosition,
        offscreenPosition = offscreenPosition
    }
end

function InventoryUIManager.toggleInventory(show, uiElements)
    if isTweening then return end
    isTweening = true
    
    local positionTween = UIEffects.createInventoryTween(
        uiElements.mainFrame, 
        show, 
        uiElements.originalPosition, 
        uiElements.offscreenPosition
    )
    
    local blurTween = UIEffects.createBlurTween(uiElements.blurEffect, show)
    
    if show then
        uiElements.blurEffect.Enabled = SettingsModule.InventoryUI.BlurEffect.Enabled
        uiElements.mainFrame.Visible = true
        ReplicatedStorage.AW_Inventory.Remotes.UpdateInventory:FireServer()
    else
        uiElements.hotbarGui.Enabled = true
    end
    
    positionTween:Play()
    blurTween:Play()
    
    positionTween.Completed:Connect(function()
        isTweening = false
        
        if show then
            uiElements.hotbarGui.Enabled = false
        else
            uiElements.mainFrame.Visible = false
            uiElements.blurEffect.Enabled = false
        end
    end)
    
    isInventoryOpen = show
end

function InventoryUIManager.isOpen()
    return isInventoryOpen
end

return InventoryUIManager 