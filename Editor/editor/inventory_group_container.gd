extends Control
class_name InventoryGroupContainer

@onready var group_name_label: Label = $VBoxContainer/GroupNameLabel
@onready var theme_selector: OptionButton = $VBoxContainer/ThemeSelector

@onready var original_theme_container: ScrollContainer = $VBoxContainer/ThemeContainerContainer/ThemeContainer
@onready var original_subgroup_container: InventorySubgroupContainer = $VBoxContainer/ThemeContainerContainer/ThemeContainer/VBoxContainer/SubgroupContainer


var title: String
var groups: Dictionary[String,InventoryItem.groups]
var themes: Dictionary[String,int]

var color: Color = Color(1.0, 1.0, 1.0, 1.0)


func populate_group():
	group_name_label.text = title
	for theme_name in themes:
		theme_selector.add_item(theme_name)
		var theme_container = original_theme_container.duplicate(DUPLICATE_GROUPS|DUPLICATE_SCRIPTS|DUPLICATE_SIGNALS)
		theme_container.name = theme_name
		$VBoxContainer/ThemeContainerContainer.add_child(theme_container)
		
		for subgroup_name in groups:
			var subgroup_container = original_subgroup_container.duplicate(DUPLICATE_GROUPS|DUPLICATE_SCRIPTS|DUPLICATE_SIGNALS)
			subgroup_container.name = subgroup_name
			theme_container.get_child(0).add_child(subgroup_container)
			
			subgroup_container.title = subgroup_name
			subgroup_container.item_theme = themes[theme_name]
			subgroup_container.filter = groups[subgroup_name]
			subgroup_container.populate_list()
		
		theme_container.get_child(0).get_child(0).queue_free()
	original_theme_container.queue_free()
	
	_on_theme_selector_item_selected(theme_selector.selected+1)


func _on_theme_selector_item_selected(index: int) -> void:
	for child in $VBoxContainer/ThemeContainerContainer.get_children():
		child.hide()
	$VBoxContainer/ThemeContainerContainer.get_child(index).show()
