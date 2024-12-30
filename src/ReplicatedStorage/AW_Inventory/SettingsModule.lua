local SettingsModule = {}

SettingsModule.ShowQuantity = false -- Set to true to group similar items and show quantities

-- Grid and slot configuration
SettingsModule.SlotSize = Vector2.new(0.12, 0.05) -- Base size for a single slot
SettingsModule.GridPadding = Vector2.new(0.0, 0.0) -- Padding between slots
SettingsModule.MaxSlotsPerRow = 8 -- Maximum number of slots per row

SettingsModule.RarityGradient = {
    ["Common"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Common,
    ["Uncommon"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Uncommon,
    ["Rare"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Rare,
    ["Epic"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Epic,
    ["Legendary"] = game.ReplicatedStorage.AW_Inventory.RarityGradient.Legendary,
}

return SettingsModule 