-- ClientFlyingScript in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

-- Get remotes
local FlyingRemotes = ReplicatedStorage:WaitForChild("FlyingRemotes")
local StartFlyingRemote = FlyingRemotes:WaitForChild("StartFlying")
local StopFlyingRemote = FlyingRemotes:WaitForChild("StopFlying")
local UpdateMovementRemote = FlyingRemotes:WaitForChild("UpdateMovement")

-- Flying state
local isFlying = false
local currentAnimation = nil
local currentCameraTween = nil
local targetCameraOffset = Vector3.new(0, 2, 10)
local currentSpeed = 0
local maxSpeed = 100
local acceleration = 2
local deceleration = 1

-- Camera settings
local cameraConfig = {
    distance = 10,
    height = 2,
    smoothness = 0.1,
    minY = -70, -- Minimum vertical angle in degrees
    maxY = 70,  -- Maximum vertical angle in degrees
    currentX = 0, -- Current horizontal rotation
    currentY = 0  -- Current vertical rotation
}

-- Animation IDs
local FLYING_ANIMATION_ID = "rbxassetid://84379061438490" -- Replace with your animation ID
local IDLE_ANIMATION_ID = "rbxassetid://81979718118680" -- Replace with your animation ID

-- Near the top with other variables
local Animator = humanoid:WaitForChild("Animator")
local defaultAnimations = {}

-- Store default animations when the script starts
for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
    table.insert(defaultAnimations, track)
end

-- Handle animations
local function playAnimation(animationId)
    -- Stop all default animations
    for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    
    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation:Destroy()
        currentAnimation = nil
    end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    currentAnimation = humanoid:LoadAnimation(animation)
    currentAnimation:Play()
end

-- Add this function to restore default animations
local function restoreDefaultAnimations()
    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation:Destroy()
        currentAnimation = nil
    end
    
    -- Resume default animations
    for _, track in ipairs(defaultAnimations) do
        track:Play()
    end
end

-- Smooth camera movement
local function updateCamera(deltaTime)
    if not isFlying then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Update camera angles based on mouse movement
    local delta = UserInputService:GetMouseDelta()
    local sensitivity = 0.5

    cameraConfig.currentX = cameraConfig.currentX - delta.X * sensitivity
    cameraConfig.currentY = math.clamp(
        cameraConfig.currentY - delta.Y * sensitivity,
        cameraConfig.minY,
        cameraConfig.maxY
    )

    -- Calculate camera position using spherical coordinates
    local angle = math.rad(cameraConfig.currentX)
    local height = math.rad(cameraConfig.currentY)
    
    local offset = Vector3.new(
        math.sin(angle) * math.cos(height),
        math.sin(height),
        math.cos(angle) * math.cos(height)
    ) * cameraConfig.distance

    -- Calculate target camera position
    local targetPosition = humanoidRootPart.Position - offset + Vector3.new(0, cameraConfig.height, 0)
    
    -- Smooth camera movement
    camera.CFrame = camera.CFrame:Lerp(
        CFrame.new(targetPosition, humanoidRootPart.Position),
        cameraConfig.smoothness
    )

    -- Update character rotation to match camera direction
    local flatForward = (humanoidRootPart.Position - camera.CFrame.Position) * Vector3.new(1, 0, 1)
    if flatForward.Magnitude > 0.1 then
        local targetCF = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + flatForward)
        humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(targetCF, 0.1)
    end
end

-- Smooth movement handling
local function updateMovement(deltaTime)
    if not isFlying then return end
    
    local moveDirection = Vector3.new(0, 0, 0)
    local isMoving = false
    
    -- Only use W for forward movement
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDirection = camera.CFrame.LookVector
        isMoving = true
    end
    
    -- Smooth acceleration/deceleration
    if isMoving then
        currentSpeed = math.min(currentSpeed + acceleration * deltaTime, maxSpeed)
    else
        currentSpeed = math.max(currentSpeed - deceleration * deltaTime, 0)
    end
    
    -- Apply movement
    if currentSpeed > 0 then
        moveDirection = moveDirection.Unit * currentSpeed
        
        -- Send movement data to server
        UpdateMovementRemote:FireServer({
            X = moveDirection.X,
            Y = moveDirection.Y,
            Z = moveDirection.Z
        })
    end
end

-- Connect mouse movement when flying starts
local function startMouseControl()
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function stopMouseControl()
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

-- Toggle flying
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F then
        if not isFlying then
            isFlying = true
            StartFlyingRemote:FireServer()
            startMouseControl()
            RunService:BindToRenderStep("FlyingUpdate", Enum.RenderPriority.Character.Value, function(deltaTime)
                updateMovement(deltaTime)
                updateCamera(deltaTime)
            end)
        else
            isFlying = false
            StopFlyingRemote:FireServer()
            stopMouseControl()
            RunService:UnbindFromRenderStep("FlyingUpdate")
            restoreDefaultAnimations()
        end
    end
end)

-- Handle animation updates from server
UpdateMovementRemote.OnClientEvent:Connect(function(animationType)
    if animationType == "PlayFlyingAnimation" then
        playAnimation(FLYING_ANIMATION_ID)
    elseif animationType == "PlayIdleAnimation" then
        playAnimation(IDLE_ANIMATION_ID)
    end
end)

-- Cleanup
player.CharacterRemoving:Connect(function()
    if isFlying then
        isFlying = false
        StopFlyingRemote:FireServer()
        stopMouseControl()
        RunService:UnbindFromRenderStep("FlyingUpdate")
        restoreDefaultAnimations()
    end
end)