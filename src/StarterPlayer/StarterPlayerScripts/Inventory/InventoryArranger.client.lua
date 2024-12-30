local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local ViewportRemote = ReplicatedStorage.AW_Inventory.Remotes.Viewport

-- Function to create and setup viewport camera
local function setupViewportCamera()
    local camera = Instance.new("Camera")
    camera.CameraType = SettingsModule.Viewport.Camera.Type
    camera.FieldOfView = SettingsModule.Viewport.Camera.FieldOfView
    return camera
end

-- Function to calculate optimal camera distance
local function calculateCameraDistance(boundingSize)
    local maxDimension = math.max(boundingSize.X, boundingSize.Y, boundingSize.Z)
    local distance = (maxDimension / math.tan(math.rad(SettingsModule.Viewport.Camera.FieldOfView))) 
        * SettingsModule.Viewport.Camera.DistanceMultiplier
    return (maxDimension/2) + distance
end

-- Function to get random position for item
local function getRandomPosition()
    local min = SettingsModule.Viewport.Model.RandomPosition.Min
    local max = SettingsModule.Viewport.Model.RandomPosition.Max
    return Vector3.new(
        math.random(min, max),
        math.random(min, max),
        math.random(min, max)
    )
end

-- Function to find and clone the view model
local function getViewModel(itemFolder)
    -- First try to find a direct Model in ViewModel folder
    local viewModel = itemFolder:FindFirstChild(SettingsModule.Viewport.Model.ViewModelPath)
    if viewModel then
        local model = viewModel:FindFirstChildOfClass("Model")
        if model then
            return model:Clone()
        end
    end
    
    -- If no model found, try to find any Model in the item folder
    local model = itemFolder:FindFirstChildOfClass("Model")
    if model then
        return model:Clone()
    end
    
    return nil
end

-- Handle viewport updates
ViewportRemote.OnClientEvent:Connect(function(viewportFrame, itemName)

    if SettingsModule.Debug.EnablePrints then
        print("DEBUG: Received viewport update for:", itemName)
    end

    -- Validate inputs
    if not viewportFrame or not itemName then 
        warn("Invalid viewport update parameters")
        return 
    end
    
    -- Get item folder
    local itemFolder = ReplicatedStorage.AW_Inventory.Items:WaitForChild(itemName)
    if not itemFolder then
        warn("Item folder not found for:", itemName)
        return
    end
    
    -- Setup camera
    local viewportCamera = setupViewportCamera()
    viewportFrame.CurrentCamera = viewportCamera
    
    -- Get random position and clone model
    local viewportPosition = getRandomPosition()
    local itemClone = getViewModel(itemFolder)
    
    if not itemClone then
        warn("No valid model found for item:", itemName)
        return
    end
    
    -- Setup model in viewport
    itemClone:SetPrimaryPartCFrame(CFrame.new(viewportPosition))
    itemClone.Parent = viewportFrame
    
    -- Get bounding box for camera positioning
    local boundingCFrame, boundingSize = itemClone:GetBoundingBox()
    
    -- Setup rotation animation
    local rotation = 0
    local connection = RunService.RenderStepped:Connect(function()
        -- Only update if viewport still exists
        if not viewportFrame.Parent then
            connection:Disconnect()
            return
        end
        
            -- Calculate camera position
        local distance = calculateCameraDistance(boundingSize)
        local cameraAngle = CFrame.Angles(
            math.rad(SettingsModule.Viewport.Camera.InitialAngle), 
            math.rad(rotation), 
            0
        )
        local cameraOffset = Vector3.new(0, 0, distance)
        
        -- Update camera
        viewportCamera.CFrame = cameraAngle * CFrame.new(viewportPosition + cameraOffset, viewportPosition)
        
        -- Increment rotation
        rotation = rotation + SettingsModule.Viewport.Camera.RotationSpeed
    end)
end)