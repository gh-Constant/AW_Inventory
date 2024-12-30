local SettingsModule = {}

-- Inventory display settings
SettingsModule.ShowQuantity = false -- Set to true to group similar items and show quantities

-- Grid and slot configuration
SettingsModule.SlotSize = Vector2.new(0.12, 0.05) -- Base size for a single slot
SettingsModule.GridPadding = Vector2.new(0.0, 0.0) -- Padding between slots
SettingsModule.MaxSlotsPerRow = 8 -- Maximum number of slots per row

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
        Background = "Background",
        Container = "InventoryFrame",
        Frame = "Inventory"
    },
    ViewportRemote = "AW_Inventory.Remotes.Viewport" -- Path relative to ReplicatedStorage
}

-- Viewport settings
SettingsModule.Viewport = {
    Camera = {
        FieldOfView = 45,
        Type = Enum.CameraType.Scriptable,
        DistanceMultiplier = 0.75,
        RotationSpeed = 1,
        InitialAngle = 90 -- degrees
    },
    Model = {
        RandomPosition = {
            Min = -5,
            Max = 5
        },
        ViewModelPath = "ViewModel" -- Path in item folder to find the model
    }
}

return SettingsModule 