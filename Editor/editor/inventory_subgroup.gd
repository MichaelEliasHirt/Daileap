extends VBoxContainer
class_name InventorySubgroup

@onready var label: Label = $InventorySeperator/Label
@onready var iventory_item_list: ItemList = $IventoryItemList

var title: String:
	set(value):
		title = value
		label.text = title

var item_theme: StringName
var filter: PackedStringArray

func populate_list():
	for tileset in get_tree().get_first_node_in_group("Inventory").all_items_from_tilesets:
		for item in tileset.values():
			if item.theme == item_theme:
				if filter.has(item.name):
					var idx = iventory_item_list.add_icon_item(item.texture,true)
					iventory_item_list.set_item_metadata(idx,item)
					iventory_item_list.set_item_tooltip_enabled(idx,true)
					iventory_item_list.set_item_tooltip(idx,item.name)
