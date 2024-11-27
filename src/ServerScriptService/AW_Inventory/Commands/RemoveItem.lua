return {
    Name = "removeitem";
    Aliases = {"take"};
    Description = "Removes an item from a player's inventory";
    Group = "Inventory";
    Args = {
        {
            Type = "player";
            Name = "player";
            Description = "Player to remove item from";
        },
        {
            Type = "string";
            Name = "itemId";
            Description = "Item ID to remove";
        },
        {
            Type = "number";
            Name = "quantity";
            Description = "Amount to remove";
            Default = 1;
        }
    };
} 