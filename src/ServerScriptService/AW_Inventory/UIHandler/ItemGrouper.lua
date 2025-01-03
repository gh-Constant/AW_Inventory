local ItemGrouper = {}

-- Helper function to compare item data
local function areItemsEqual(data1, data2)
	if not data1 or not data2 then return false end
	
	-- Compare basic properties
	if data1.name ~= data2.name then return false end
	
	-- Compare data tables
	if not data1.data or not data2.data then
		return not data1.data and not data2.data -- true if both are nil
	end
	
	-- Compare all properties in data
	for k, v in pairs(data1.data) do
		if data2.data[k] ~= v then return false end
	end
	for k, v in pairs(data2.data) do
		if data1.data[k] ~= v then return false end
	end
	
	return true
end

function ItemGrouper.groupItems(inventory)
	local groupedItems = {}
	
	for itemId, itemData in pairs(inventory.Items) do
		local found = false
		for _, group in ipairs(groupedItems) do
			if areItemsEqual(group.data, itemData) then
				table.insert(group.ids, itemId)
				found = true
				break
			end
		end
		if not found then
			table.insert(groupedItems, {
				data = itemData,
				ids = {itemId}
			})
		end
	end
	
	return groupedItems
end

function ItemGrouper.getUngroupedItems(inventory)
	local items = {}
	for uniqueId, itemData in pairs(inventory.Items) do
		table.insert(items, {
			id = uniqueId,
			data = itemData
		})
	end
	return items
end

return ItemGrouper 