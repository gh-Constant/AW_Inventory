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
local isInventoryOpen = true
local isTweening = false

-- Function to toggle inventory visibility with animation
local function toggleInventory(show)
    if isTweening then return end
    isTweening = true
    
    -- Create tweens
    local tweenInfo = TweenInfo.new(
        SettingsModule.InventoryUI.TransitionTime,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local targetBlurSize = show and SettingsModule.InventoryUI.BlurEffect.Size or 0
    local blurTween = TweenService:Create(blurEffect, tweenInfo, {
        Size = targetBlurSize
    })
    
    -- Show/hide inventory and hotbar
    if show then
        mainFrame.Visible = true
        hotbarGui.Enabled = false
        blurEffect.Enabled = SettingsModule.InventoryUI.BlurEffect.Enabled
        -- Request inventory update from server
        UpdateInventoryRemote:FireServer()
    else
        hotbarGui.Enabled = true
    end
    
    -- Start tweens
    blurTween:Play()
    
    -- Handle completion
    blurTween.Completed:Connect(function()
        isTweening = false
        
        -- Hide inventory after tweening if closing
        if not show then
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

-- Initialize inventory state
mainFrame.Visible = true
hotbarGui.Enabled = false
blurEffect.Size = SettingsModule.InventoryUI.BlurEffect.Size
blurEffect.Enabled = SettingsModule.InventoryUI.BlurEffect.Enabled
-- Request initial inventory update
UpdateInventoryRemote:FireServer()

-- Clean up
player.CharacterRemoving:Connect(function()
    toggleInventory(false)
end) 