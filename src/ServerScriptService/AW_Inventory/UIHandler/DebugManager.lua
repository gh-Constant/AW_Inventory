local SettingsModule = require(game.ReplicatedStorage.AW_Inventory.SettingsModule)

local DebugManager = {}

function DebugManager.print(message, ...)
	if not SettingsModule.Debug.EnablePrints then return end
	print(string.format(message, ...))
end

function DebugManager.warn(message, ...)
	if not SettingsModule.Debug.EnablePrints then return end
	warn(string.format(message, ...))
end

function DebugManager.printItemProcessing(message, ...)
	if not SettingsModule.Debug.EnablePrints or not SettingsModule.Debug.ShowItemProcessing then return end
	print(string.format(message, ...))
end

return DebugManager 