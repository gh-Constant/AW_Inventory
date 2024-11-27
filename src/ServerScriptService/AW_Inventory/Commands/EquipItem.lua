return {
    Name = "equipitem";
    Aliases = {"equip"};
    Description = "Equips an item to a specific slot";
    Group = "Inventory";
    Args = {
        {
            Type = "player";
            Name = "player";
            Description = "Player to equip item for";
        },
        {
            Type = "string";
            Name = "itemId";
            Description = "Item ID to equip";
        },
        {
            Type = "number";
            Name = "slotId";
            Description = "Slot to equip item to";
        }
    };
} 