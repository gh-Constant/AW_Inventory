local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

local UIEffects = {}

function UIEffects.createEquipEffect(slot)
    local effectFrame = Instance.new("Frame")
    effectFrame.Name = "EquipEffect"
    effectFrame.BackgroundColor3 = SettingsModule.EquipEffect.Color
    effectFrame.BackgroundTransparency = SettingsModule.EquipEffect.Transparency.Start
    effectFrame.Size = SettingsModule.EquipEffect.Size.Start
    effectFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    effectFrame.Position = UDim2.fromScale(0.5, 0.5)
    effectFrame.Parent = slot
    effectFrame.ZIndex = 999

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = effectFrame

    local tweenInfo = TweenInfo.new(
        SettingsModule.EquipEffect.Duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(effectFrame, tweenInfo, {
        Size = SettingsModule.EquipEffect.Size.End,
        BackgroundTransparency = SettingsModule.EquipEffect.Transparency.End
    })

    tween:Play()
    tween.Completed:Connect(function()
        effectFrame:Destroy()
    end)
end

function UIEffects.createHighlight(slot)
    local highlightFrame = Instance.new("Frame")
    highlightFrame.Name = "EquipHighlight"
    highlightFrame.BackgroundColor3 = SettingsModule.EquipHighlight.Color
    highlightFrame.BackgroundTransparency = SettingsModule.EquipHighlight.Transparency
    highlightFrame.Size = UDim2.fromScale(1, 1)
    highlightFrame.Position = UDim2.fromScale(0, 0)
    highlightFrame.ZIndex = 2

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = highlightFrame

    highlightFrame.Parent = slot
    return highlightFrame
end

function UIEffects.createInventoryTween(frame, show, originalPosition, offscreenPosition)
    local tweenInfo = TweenInfo.new(
        0.3,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    )
    
    local targetPosition = show and originalPosition or offscreenPosition
    return TweenService:Create(frame, tweenInfo, {
        Position = targetPosition
    })
end

function UIEffects.createBlurTween(blurEffect, show)
    local blurTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
    local targetBlurSize = show and SettingsModule.InventoryUI.BlurEffect.Size or 0
    return TweenService:Create(blurEffect, blurTweenInfo, {
        Size = targetBlurSize
    })
end

return UIEffects 