local SettingsModule = {}

-- Inventory display settings
SettingsModule.ShowQuantity = false -- Set to true to group similar items and show quantities

-- Grid and slot configuration
SettingsModule.SlotSize = Vector2.new(0.12, 0.05) -- Base size for a single slot
SettingsModule.GridPadding = Vector2.new(0.0, 0.0) -- Padding between slots
SettingsModule.MaxSlotsPerRow = 8 -- Maximum number of slots per row
SettingsModule.HotbarSlots = 9 -- Number of slots in the hotbar (matches the number keys 1-9)

-- Rarity configuration
SettingsModule.RarityGradient = {
    ["Common"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Common,
    ["Uncommon"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Uncommon,
    ["Rare"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Rare,
    ["Epic"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Epic,
    ["Legendary"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Legendary,
}

-- Gradient settings
SettingsModule.BGGradientDarkness = 0.7 -- How much darker the BG gradient should be (0-1)

-- View type settings
SettingsModule.ViewTypes = {
    VIEWPORT = "Viewport",
    IMAGE = "Image"
}

-- Frame naming settings
SettingsModule.FrameNameSeparator = "_" -- Separator between item name and properties
SettingsModule.PropertyValueSeparator = "-" -- Separator between property name and value

-- Debug settings
SettingsModule.Debug = {
    EnablePrints = true, -- Master switch for all debug prints
    ShowGridDebug = false, -- Whether to show grid debug information
    ShowItemProcessing = false, -- Whether to show item processing debug information
    MinDebugRows = 10, -- Minimum number of rows to show in grid debug
    Commands = {
        CheckInventory = {
            EnablePrints = false, -- Enable any prints for CheckInventory command
            DetailedPrints = false -- Enable detailed information in prints
        }
    }
}

-- Paths
SettingsModule.Paths = {
    ItemsFolder = "AW_Inventory.Items", -- Path relative to ReplicatedStorage
    InventoryFrame = { -- Individual parts of the inventory frame path
        Gui = "Inventory",
        Main = "Main",
        Container = "InventoryFrame",
        Frame = "Inventory"
    },
    ViewportRemote = "AW_Inventory.Remotes.Viewport" -- Path relative to ReplicatedStorage
}

-- Viewport settings
SettingsModule.Viewport = {
    Camera = {
        Type = Enum.CameraType.Scriptable,
        RotationSpeed = 0.5,
        DistanceMultiplier = 0.4, -- Reduced from 0.6 to 0.4
        HeightMultiplier = 0.2,   -- Reduced from 0.25 to 0.2
        DepthMultiplier = 0.5,    -- Reduced from 0.7 to 0.5
        ViewAngle = -5,          -- Changed from -20 to -5 for a more level view
    },
    Model = {
        ViewModelPath = "ViewModel",
    },
}

-- Equip effect settings
SettingsModule.EquipEffect = {
    Duration = 0.3, -- Duration of the effect in seconds
    Color = Color3.fromRGB(255, 255, 255), -- Color of the glow effect
    Transparency = {
        Start = 0,
        End = 1
    },
    Size = {
        Start = UDim2.fromScale(1.2, 1.2),
        End = UDim2.fromScale(1, 1)
    }
}

-- Highlight settings for equipped items
SettingsModule.EquipHighlight = {
    Color = Color3.fromRGB(255, 255, 255), -- Color of the highlight
    Transparency = 0.8, -- How transparent the highlight should be (0-1)
    BorderSize = UDim.new(0, 2) -- Size of the highlight border
}

return SettingsModule 