return {
    Name = "additem";
    Aliases = {"give"};
    Description = "Adds an item to a player's inventory";
    Group = "Inventory";
    Args = {
        {
            Type = "player";
            Name = "player";
            Description = "Player to give item to";
        },
        {
            Type = "string";
            Name = "itemId";
            Description = "Item ID to give";
        },
        {
            Type = "number";
            Name = "quantity";
            Description = "Amount to give";
            Default = 1;
        },
        {
            Type = "table";
            Name = "itemData";
            Description = "Additional data for the item";
            Default = {};
        }
    };
} 