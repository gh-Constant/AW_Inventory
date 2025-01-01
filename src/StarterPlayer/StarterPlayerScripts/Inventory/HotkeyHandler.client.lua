local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local HotkeyRemote = ReplicatedStorage.AW_Inventory.Remotes.HotkeyEquip
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

-- Map number keys to their keycode
local numberKeys = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5,
    [Enum.KeyCode.Six] = 6,
    [Enum.KeyCode.Seven] = 7,
    [Enum.KeyCode.Eight] = 8,
    [Enum.KeyCode.Nine] = 9,
}

-- Keep track of highlights and currently equipped slot
local slotHighlights = {}
local currentlyEquippedSlot = nil

-- Function to create and play the equip effect
local function createEquipEffect(slot)
    -- Create the effect frame
    local effectFrame = Instance.new("Frame")
    effectFrame.Name = "EquipEffect"
    effectFrame.BackgroundColor3 = SettingsModule.EquipEffect.Color
    effectFrame.BackgroundTransparency = SettingsModule.EquipEffect.Transparency.Start
    effectFrame.Size = SettingsModule.EquipEffect.Size.Start
    effectFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    effectFrame.Position = UDim2.fromScale(0.5, 0.5)
    effectFrame.Parent = slot
    effectFrame.ZIndex = 999 -- Make sure effect appears above other UI elements
    
    -- Create corner to make it rounded
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = effectFrame
    
    -- Animate the effect
    local tweenInfo = TweenInfo.new(
        SettingsModule.EquipEffect.Duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = game:GetService("TweenService"):Create(effectFrame, tweenInfo, {
        Size = SettingsModule.EquipEffect.Size.End,
        BackgroundTransparency = SettingsModule.EquipEffect.Transparency.End
    })
    
    tween:Play()
    
    -- Clean up after animation
    tween.Completed:Connect(function()
        effectFrame:Destroy()
    end)
end

-- Function to create persistent highlight
local function createHighlight(slot)
    -- Remove existing highlight if any
    if slotHighlights[slot] then
        slotHighlights[slot]:Destroy()
        slotHighlights[slot] = nil
    end
    
    -- Create highlight frame
    local highlightFrame = Instance.new("Frame")
    highlightFrame.Name = "EquipHighlight"
    highlightFrame.BackgroundColor3 = SettingsModule.EquipHighlight.Color
    highlightFrame.BackgroundTransparency = SettingsModule.EquipHighlight.Transparency
    highlightFrame.Size = UDim2.fromScale(1, 1)
    highlightFrame.Position = UDim2.fromScale(0, 0)
    highlightFrame.ZIndex = 2 -- Below the item but above the slot
    highlightFrame.Parent = slot
    
    -- Create corner to make it rounded
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = highlightFrame
    
    -- Store reference to highlight
    slotHighlights[slot] = highlightFrame
    
    return highlightFrame
end

-- Function to remove highlight
local function removeHighlight(slot)
    if slotHighlights[slot] then
        slotHighlights[slot]:Destroy()
        slotHighlights[slot] = nil
    end
end

-- Function to check if a slot has an item
local function hasItemInSlot(slot)
    for _, child in ipairs(slot:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("Item") then
            return true
        end
    end
    return false
end

-- Function to clean up slot state
local function cleanupSlotState(slot)
    -- Remove highlight
    removeHighlight(slot)
    
    -- If this was the currently equipped slot, clear it
    if currentlyEquippedSlot == slot then
        currentlyEquippedSlot = nil
    end
    
    -- Find and remove any equipped bool value
    local equippedValue = slot:FindFirstChild("Equipped")
    if equippedValue and equippedValue:IsA("BoolValue") then
        equippedValue:Destroy()
    end
end

-- Function to toggle highlight
local function toggleHighlight(slot)
    -- First check if there's actually an item in the slot
    if not hasItemInSlot(slot) then
        cleanupSlotState(slot)
        return false
    end

    if slotHighlights[slot] then
        cleanupSlotState(slot)
        return false
    else
        -- Remove highlight from previously equipped slot if any
        if currentlyEquippedSlot and currentlyEquippedSlot ~= slot then
            cleanupSlotState(currentlyEquippedSlot)
        end
        createHighlight(slot)
        currentlyEquippedSlot = slot
        return true
    end
end

-- Function to play effect on hotbar slot
local function playHotbarEffect(slotNumber)
    local player = Players.LocalPlayer
    local hotbarGui = player.PlayerGui:WaitForChild("Hotbar")
    local hotbarSlotsFrame = hotbarGui:WaitForChild("Main"):WaitForChild("SlotsFrame")
    local slot = hotbarSlotsFrame:FindFirstChild("Slot" .. slotNumber)
    
    if slot then
        -- Check if there's actually an item in the slot
        if not hasItemInSlot(slot) then
            cleanupSlotState(slot)
            return
        end

        -- If this is the currently equipped slot, unequip it
        if currentlyEquippedSlot == slot then
            createEquipEffect(slot)
            toggleHighlight(slot)
            return
        end
        
        -- If another slot is equipped, ignore this request
        if currentlyEquippedSlot and currentlyEquippedSlot ~= slot then
            return
        end
        
        -- Otherwise, equip this slot
        createEquipEffect(slot)
        toggleHighlight(slot)
    end
end

-- Function to check and clean up all slots
local function checkAndCleanupAllSlots()
    local player = Players.LocalPlayer
    local hotbarGui = player.PlayerGui:WaitForChild("Hotbar")
    local hotbarSlotsFrame = hotbarGui:WaitForChild("Main"):WaitForChild("SlotsFrame")
    
    for _, slot in ipairs(hotbarSlotsFrame:GetChildren()) do
        if slot:IsA("ImageLabel") and slot.Name:match("^Slot%d+$") then
            if not hasItemInSlot(slot) then
                cleanupSlotState(slot)
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local slotNumber = numberKeys[input.KeyCode]
    if slotNumber then
        local player = Players.LocalPlayer
        local hotbarGui = player.PlayerGui:WaitForChild("Hotbar")
        local hotbarSlotsFrame = hotbarGui:WaitForChild("Main"):WaitForChild("SlotsFrame")
        local slot = hotbarSlotsFrame:FindFirstChild("Slot" .. slotNumber)
        
        if slot then
            -- Check if there's actually an item in the slot
            if not hasItemInSlot(slot) then
                cleanupSlotState(slot)
                return
            end

            if currentlyEquippedSlot == slot or not currentlyEquippedSlot then
                HotkeyRemote:FireServer(slotNumber)
                playHotbarEffect(slotNumber)
            end
        end
    end
end)

-- Clean up highlights when player leaves
Players.LocalPlayer.CharacterRemoving:Connect(function()
    currentlyEquippedSlot = nil
    for slot, highlight in pairs(slotHighlights) do
        highlight:Destroy()
    end
    slotHighlights = {}
end)

-- Periodically check and clean up slot states
task.spawn(function()
    while true do
        task.wait(1)
        checkAndCleanupAllSlots()
    end
end) 