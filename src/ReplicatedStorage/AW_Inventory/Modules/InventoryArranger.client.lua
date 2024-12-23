local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Remote event for viewport updates
local ViewportRemote = ReplicatedStorage.AW_Inventory.Remotes.Viewport

-- Constants for viewport camera
local CAMERA_FIELD_OF_VIEW = 45
local ROTATION_SPEED = 1
local CAMERA_DISTANCE_MULTIPLIER = 0.75

-- Function to create and setup viewport camera
local function setupViewportCamera()
    local camera = Instance.new("Camera")
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = CAMERA_FIELD_OF_VIEW
    return camera
end

-- Function to calculate optimal camera distance
local function calculateCameraDistance(boundingSize)
    local maxDimension = math.max(boundingSize.X, boundingSize.Y, boundingSize.Z)
    local distance = (maxDimension / math.tan(math.rad(CAMERA_FIELD_OF_VIEW))) * CAMERA_DISTANCE_MULTIPLIER
    return (maxDimension/2) + distance
end

-- Handle viewport updates
ViewportRemote.OnClientEvent:Connect(function(viewportFrame, itemName)
    -- Validate inputs
    if not viewportFrame or not itemName then return end
    
    -- Setup camera
    local viewportCamera = setupViewportCamera()
    viewportFrame.CurrentCamera = viewportCamera
    
    -- Create random position for item
    local viewportPosition = Vector3.new(
        math.random(-5, 5),
        math.random(-5, 5),
        math.random(-5, 5)
    )
    
    -- Clone and setup item
    local itemTemplate = ReplicatedStorage.AW_Inventory.Items:WaitForChild(itemName).ViewModel:FindFirstChildOfClass("Model")

    if not itemTemplate then
        warn("Item template not found for: " .. itemName)
        return
    end

    local itemClone = itemTemplate:Clone()
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
        local cameraAngle = CFrame.Angles(math.rad(90), math.rad(rotation), 0)
        local cameraOffset = Vector3.new(0, 0, distance)
        
        -- Update camera
        viewportCamera.CFrame = cameraAngle * CFrame.new(viewportPosition + cameraOffset, viewportPosition)
        
        -- Increment rotation
        rotation = rotation + ROTATION_SPEED
    end)
end)