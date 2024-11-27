return {
    Name = "checkinv";
    Aliases = {"inventory", "inv"};
    Description = "Checks a player's inventory";
    Group = "Inventory";
    Args = {
        {
            Type = "player";
            Name = "player";
            Description = "Player to check inventory of";
        }
    };
} 