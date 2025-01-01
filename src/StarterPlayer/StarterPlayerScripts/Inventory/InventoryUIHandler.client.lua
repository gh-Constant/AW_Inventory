local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local inventoryGui = playerGui:WaitForChild("Inventory")
local mainFrame = inventoryGui:WaitForChild("Main")
local hotbarGui = playerGui:WaitForChild("Hotbar")

-- Get the remote event
local UpdateInventoryRemote = ReplicatedStorage.AW_Inventory.Remotes.UpdateInventory

-- Create blur effect
local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 0
blurEffect.Enabled = false
blurEffect.Parent = Lighting

-- Variables to track state
local isInventoryOpen = false
local isTweening = false

-- Store original position
local originalPosition = mainFrame.Position
local offscreenPosition = UDim2.new(
    originalPosition.X.Scale, 
    originalPosition.X.Offset,
    -1, -- Move above screen
    originalPosition.Y.Offset
)

-- Set initial state
mainFrame.Position = offscreenPosition
mainFrame.Visible = false
hotbarGui.Enabled = true
blurEffect.Enabled = false

-- Function to toggle inventory visibility with animation
local function toggleInventory(show)
    if isTweening then return end
    isTweening = true
    
    -- Create tweens
    local tweenInfo = TweenInfo.new(
        0.3, -- Faster animation
        Enum.EasingStyle.Back, -- Bouncy effect
        Enum.EasingDirection.Out
    )
    
    -- Create position tween
    local targetPosition = show and originalPosition or offscreenPosition
    local positionTween = TweenService:Create(mainFrame, tweenInfo, {
        Position = targetPosition
    })
    
    -- Create blur tween
    local blurTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
    local targetBlurSize = show and SettingsModule.InventoryUI.BlurEffect.Size or 0
    local blurTween = TweenService:Create(blurEffect, blurTweenInfo, {
        Size = targetBlurSize
    })
    
    -- Setup UI before animation starts
    if show then
        -- Enable blur immediately when opening
        blurEffect.Enabled = SettingsModule.InventoryUI.BlurEffect.Enabled
        -- Show frame but keep hotbar until animation completes
        mainFrame.Visible = true
        -- Request inventory update from server
        UpdateInventoryRemote:FireServer()
    else
        -- Enable hotbar immediately when closing
        hotbarGui.Enabled = true
    end
    
    -- Start tweens
    positionTween:Play()
    blurTween:Play()
    
    -- Handle completion
    positionTween.Completed:Connect(function()
        isTweening = false
        
        if show then
            -- Disable hotbar after opening animation
            hotbarGui.Enabled = false
        else
            -- Hide inventory and disable blur after closing animation
            mainFrame.Visible = false
            blurEffect.Enabled = false
        end
    end)
    
    isInventoryOpen = show
end

-- Connect to input events
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == SettingsModule.InventoryUI.ToggleKey then
        toggleInventory(not isInventoryOpen)
    end
end)

-- Clean up
player.CharacterRemoving:Connect(function()
    toggleInventory(false)
end) 