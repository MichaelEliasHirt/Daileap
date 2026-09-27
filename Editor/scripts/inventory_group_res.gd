extends Resource
class_name InventoryGroupRes


@export var name: String

@export var groups: Dictionary[String,InventoryItem.groups]
@export var themes: Dictionary[String,int]

@export var color: Color = Color(1.0, 1.0, 1.0, 1.0)
