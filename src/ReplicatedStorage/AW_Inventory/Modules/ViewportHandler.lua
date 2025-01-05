local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)
local Maid = require(ReplicatedStorage.AW_Inventory.Modules.Maid)

local ViewportHandler = {}

function ViewportHandler.setupViewportCamera()
    local camera = Instance.new("Camera")
    camera.CameraType = SettingsModule.Viewport.Camera.Type
    camera.FieldOfView = 30
    return camera
end

function ViewportHandler.calculateCameraPosition(boundingSize)
    local maxDimension = math.max(boundingSize.X, boundingSize.Y, boundingSize.Z)
    local distance = (maxDimension / math.tan(math.rad(15))) * SettingsModule.Viewport.Camera.DistanceMultiplier
    
    return Vector3.new(
        0, 
        distance * SettingsModule.Viewport.Camera.HeightMultiplier, 
        distance * SettingsModule.Viewport.Camera.DepthMultiplier
    )
end

function ViewportHandler.getCenteredPosition()
    return Vector3.new(0, 0, 0)
end

function ViewportHandler.getViewModel(itemFolder)
    local viewModel = itemFolder:FindFirstChild(SettingsModule.Viewport.Model.ViewModelPath)
    if viewModel then
        local model = viewModel:FindFirstChildOfClass("Model")
        if model then
            return model:Clone()
        end
    end
    
    local model = itemFolder:FindFirstChildOfClass("Model")
    if model then
        return model:Clone()
    end
    
    return nil
end

function ViewportHandler.setupModel(itemClone)
    if not itemClone.PrimaryPart then
        local handle = itemClone:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            itemClone.PrimaryPart = handle
        else
            for _, part in ipairs(itemClone:GetDescendants()) do
                if part:IsA("BasePart") then
                    itemClone.PrimaryPart = part
                    break
                end
            end
        end
    end
    return itemClone.PrimaryPart ~= nil
end

function ViewportHandler.setupViewport(viewportFrame, itemName)
    local maid = Maid.new()
    
    if SettingsModule.Debug.EnablePrints then
        print("DEBUG: Received viewport update for:", itemName)
    end
    
    if not viewportFrame or not itemName then 
        warn("Invalid viewport update parameters")
        return 
    end
    
    local itemFolder = ReplicatedStorage.AW_Inventory.Items:WaitForChild(itemName)
    if not itemFolder then
        warn("Item folder not found for:", itemName)
        return
    end
    
    local viewportCamera = ViewportHandler.setupViewportCamera()
    viewportFrame.CurrentCamera = viewportCamera
    
    local viewportPosition = ViewportHandler.getCenteredPosition()
    local itemClone = ViewportHandler.getViewModel(itemFolder)
    
    if not itemClone then
        warn("No valid model found for item:", itemName)
        return
    end
    
    if not ViewportHandler.setupModel(itemClone) then
        warn("Could not set PrimaryPart for model:", itemName)
        return
    end
    
    itemClone:SetPrimaryPartCFrame(
        CFrame.new(viewportPosition) * 
        CFrame.Angles(math.rad(90), 0, 0)
    )
    itemClone.Parent = viewportFrame
    
    local boundingCFrame, boundingSize = itemClone:GetBoundingBox()
    local cameraPosition = ViewportHandler.calculateCameraPosition(boundingSize)
    
    local rotation = 0
    maid:GiveTask(RunService.RenderStepped:Connect(function()
        if not viewportFrame.Parent then
            maid:Destroy()
            return
        end
        
        local cameraAngle = CFrame.Angles(
            math.rad(SettingsModule.Viewport.Camera.ViewAngle),
            0,
            0
        )
        
        viewportCamera.CFrame = CFrame.new(cameraPosition) * cameraAngle
        viewportCamera.Focus = CFrame.new(viewportPosition)
        
        if itemClone.PrimaryPart then
            itemClone:SetPrimaryPartCFrame(
                CFrame.new(viewportPosition) * 
                CFrame.Angles(math.rad(90), math.rad(rotation), 0)
            )
        end
        
        rotation = rotation + SettingsModule.Viewport.Camera.RotationSpeed * 0.5
    end))
    
    maid:GiveTask(viewportFrame.AncestryChanged:Connect(function(_, parent)
        if not parent then
            maid:Destroy()
        end
    end))
end

return ViewportHandler 