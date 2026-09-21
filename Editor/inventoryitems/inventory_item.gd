extends Resource
class_name InventoryItem

enum groups {
	na,
	terraintile,
	slab,
	wall,
	decor
}

const SHORTHANDS = {
	"tt": groups.terraintile,
	"sl": groups.slab,
	"wa": groups.wall,
	"de": groups.decor,
	}

@export var name: String

@export var group: groups

@export var root: RootRes
@export var layer: int
@export var theme: int

func _init(name_: String, root_: RootRes) -> void:
	var split_name = name_.trim_prefix("#").split("_",true,2)
	group = SHORTHANDS[split_name[0]]
	theme = int(split_name[1])
	name = split_name[2]

	root = root_
	
