local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerObjectModule = require(script.Parent.Player.PlayerObject)
local SettingsModule = require(ReplicatedStorage.AW_Inventory.SettingsModule)

-- Get the items folder
local ItemsFolder = ReplicatedStorage.AW_Inventory.Items

-- Helper function for debug prints
local function debugPrint(message, ...)
    if not SettingsModule.Debug.EnablePrints then return end
    print(string.format("[EquipHandler] " .. message, ...))
end

-- Function to create tool with data
local function createToolWithData(itemName, itemData)
    local itemFolder = ItemsFolder:FindFirstChild(itemName)
    if not itemFolder then return nil end
    
    -- Find and clone the tool template
    local toolTemplate = itemFolder:FindFirstChild("Tool")
    if not toolTemplate then return nil end
    
    local tool = toolTemplate:Clone()
    
    -- Create a Data folder to store item data
    local dataFolder = Instance.new("Folder")
    dataFolder.Name = "Data"
    
    -- Store the item data
    for key, value in pairs(itemData.data or {}) do
        local stringValue = Instance.new("StringValue")
        stringValue.Name = key
        stringValue.Value = tostring(value)
        stringValue.Parent = dataFolder
    end
    
    dataFolder.Parent = tool
    return tool
end

-- Setup remote event handler
local EquipItemRemote = ReplicatedStorage.AW_Inventory.Remotes.EquipItem

EquipItemRemote.OnServerEvent:Connect(function(player, slotNumber, itemId)
    debugPrint("Player %s attempting to equip item %s to slot %d", player.Name, itemId, slotNumber)
    
    -- Get player's inventory data
    local PlayerObject = PlayerObjectModule.GetPlayerObject(player)
    if not PlayerObject then return end
    
    local inventory = PlayerObject:getInventory()
    if not inventory then return end
    
    -- Find the item in inventory
    local itemData = inventory.Items[itemId]
    if not itemData then
        debugPrint("Item %s not found in player's inventory", itemId)
        return
    end
    
    -- Create the tool with data
    local tool = createToolWithData(itemData.name, itemData)
    if not tool then
        debugPrint("Failed to create tool for item %s", itemData.name)
        return
    end
    
    -- Remove any existing tool in that slot
    for _, existingTool in ipairs(player.Backpack:GetChildren()) do
        if existingTool:IsA("Tool") and existingTool:GetAttribute("SlotNumber") == slotNumber then
            existingTool:Destroy()
        end
    end
    
    -- Also check equipped tools
    if player.Character then
        for _, existingTool in ipairs(player.Character:GetChildren()) do
            if existingTool:IsA("Tool") and existingTool:GetAttribute("SlotNumber") == slotNumber then
                existingTool:Destroy()
            end
        end
    end
    
    -- Set the slot number attribute
    tool:SetAttribute("SlotNumber", slotNumber)
    
    -- Update equipped items data
    local equipped = PlayerObject:getEquipped() -- This will initialize if needed
    equipped[tostring(slotNumber)] = itemId
    PlayerObject:setEquipped(equipped)
    
    -- Give the tool to the player
    tool.Parent = player.Backpack
    
    debugPrint("Successfully equipped item %s to slot %d for player %s", itemData.name, slotNumber, player.Name)
end) 