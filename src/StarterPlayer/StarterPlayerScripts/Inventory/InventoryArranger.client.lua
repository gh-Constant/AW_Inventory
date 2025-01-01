local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local ViewportRemote = ReplicatedStorage.AW_Inventory.Remotes.Viewport
local Maid = require(ReplicatedStorage.AW_Inventory.Modules.Maid)

-- Function to create and setup viewport camera
local function setupViewportCamera()
    local camera = Instance.new("Camera")
    camera.CameraType = SettingsModule.Viewport.Camera.Type
    camera.FieldOfView = 30 -- Smaller FOV for better perspective
    return camera
end

-- Function to calculate optimal camera distance and position
local function calculateCameraPosition(boundingSize)
    local maxDimension = math.max(boundingSize.X, boundingSize.Y, boundingSize.Z)
    -- Use settings for distance calculation
    local distance = (maxDimension / math.tan(math.rad(15))) * SettingsModule.Viewport.Camera.DistanceMultiplier
    
    -- Use settings for camera position
    return Vector3.new(
        0, 
        distance * SettingsModule.Viewport.Camera.HeightMultiplier, 
        distance * SettingsModule.Viewport.Camera.DepthMultiplier
    )
end

-- Function to get centered position for item
local function getCenteredPosition()
    return Vector3.new(0, 0, 0)
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
    -- Create new maid for this viewport
    local maid = Maid.new()

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
    
    -- Center the model in the viewport
    local viewportPosition = getCenteredPosition()
    local itemClone = getViewModel(itemFolder)
    
    if not itemClone then
        warn("No valid model found for item:", itemName)
        return
    end
    
    -- Setup model in viewport
    -- Add primary part check before setting CFrame
    if not itemClone.PrimaryPart then
        -- First try to find a part named "Handle" which is common for tools
        local handle = itemClone:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            itemClone.PrimaryPart = handle
        else
            -- If no Handle, use the first BasePart found
            for _, part in ipairs(itemClone:GetDescendants()) do
                if part:IsA("BasePart") then
                    itemClone.PrimaryPart = part
                    break
                end
            end
        end
    end

    if itemClone.PrimaryPart then
        -- Position the model and rotate it to stand upright
        itemClone:SetPrimaryPartCFrame(
            CFrame.new(viewportPosition) * 
            CFrame.Angles(math.rad(90), 0, 0) -- Rotate around X axis to stand upright
        )
        itemClone.Parent = viewportFrame
    else
        warn("Could not set PrimaryPart for model:", itemName)
        return
    end

    -- Get bounding box for camera positioning
    local boundingCFrame, boundingSize = itemClone:GetBoundingBox()
    local cameraPosition = calculateCameraPosition(boundingSize)
    
    -- Setup rotation animation
    local rotation = 0
    maid:GiveTask(RunService.RenderStepped:Connect(function()
        -- Only update if viewport still exists
        if not viewportFrame.Parent then
            maid:Destroy()
            return
        end
        
        -- Keep camera fixed, looking straight at the model with slight tilt
        local cameraAngle = CFrame.Angles(
            math.rad(SettingsModule.Viewport.Camera.ViewAngle), -- Small tilt for perspective
            0,
            0
        )
        
        -- Position camera and look at center
        viewportCamera.CFrame = CFrame.new(cameraPosition) * cameraAngle
        viewportCamera.Focus = CFrame.new(viewportPosition)
        
        -- Rotate the model itself around its vertical axis while keeping it upright
        if itemClone.PrimaryPart then
            itemClone:SetPrimaryPartCFrame(
                CFrame.new(viewportPosition) * 
                CFrame.Angles(math.rad(90), math.rad(rotation), 0) -- Keep upright (X) while rotating around Y
            )
        end
        
        -- Increment rotation (slower rotation)
        rotation = rotation + SettingsModule.Viewport.Camera.RotationSpeed * 0.5
    end))

    -- Clean up maid when viewport is destroyed
    maid:GiveTask(viewportFrame.AncestryChanged:Connect(function(_, parent)
        if not parent then
            maid:Destroy()
        end
    end))
end)