extends Control
class_name InventoryGroup

@onready var inventory_subgroup_container: Control = $VBoxContainer/InventorySubgroupContainer
@onready var original_inventory_themegroup: ScrollContainer = $VBoxContainer/InventorySubgroupContainer/InventoryThemegroup
@onready var original_inventory_subgroup: InventorySubgroup = $VBoxContainer/InventorySubgroupContainer/InventoryThemegroup/InventoryThemegroupContainer/InventorySubgroup

var title: String
var specifics: Dictionary[String,PackedStringArray]
var themes: Dictionary[String,String]

var color: Color = Color(1.0, 1.0, 1.0, 1.0)
var tilesets: Dictionary[String,TileSet]


func populate_group():
	for theme_name in themes:
		var theme_group = original_inventory_themegroup.duplicate(DUPLICATE_GROUPS|DUPLICATE_SCRIPTS|DUPLICATE_SIGNALS)
		theme_group.name = theme_name
		inventory_subgroup_container.add_child(theme_group)
		theme_group.show()
		
		for subgroup_name in specifics:
			var inventory_subgroup = original_inventory_subgroup.duplicate(DUPLICATE_GROUPS|DUPLICATE_SCRIPTS|DUPLICATE_SIGNALS)
			inventory_subgroup.name = subgroup_name
			theme_group.get_child(0).add_child(inventory_subgroup)
			inventory_subgroup.show()
			
			inventory_subgroup.title = subgroup_name
			inventory_subgroup.item_theme = themes[theme_name]
			inventory_subgroup.filter = specifics[subgroup_name]
			inventory_subgroup.populate_list()
