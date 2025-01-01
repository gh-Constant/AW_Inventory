return {
    Name = "rawcheckinv";
    Aliases = {"rawinventory", "rawinv"};
    Description = "Checks a player's raw inventory data";
    Group = "Inventory";
    Args = {
        {
            Type = "player";
            Name = "player";
            Description = "Player to check raw inventory data of";
        }
    };
} 