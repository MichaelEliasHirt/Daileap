extends VBoxContainer
class_name InventorySubgroupContainer

@onready var label: Label = $HBoxContainer/SubgroupNameLabel
@onready var inventory_item_list: ItemList = $InventoryItemList

var title: String:
	set(value):
		title = value
		label.text = title

var item_theme: int
var filter: InventoryItem.groups

func populate_list():
	for tileset in get_tree().get_first_node_in_group("Inventory").all_items_from_tilesets:
		for item in tileset.values():
			if item.theme == item_theme:
				if filter == item.group:
					var idx = inventory_item_list.add_icon_item(item.root.icon_texture,true)
					inventory_item_list.set_item_metadata(idx,item)
					inventory_item_list.set_item_tooltip_enabled(idx,true)
					inventory_item_list.set_item_tooltip(idx,item.name)
