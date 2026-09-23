extends Resource
class_name InventoryItem

enum groups {
	na,
	terraintile,
	slab,
	wall,
	decor1,
	decor2,
	decor3
}

const SHORTHANDS = {
	"tt": groups.terraintile,
	"sl": groups.slab,
	"wa": groups.wall,
	"de": groups.na,
	}

const CAN_BE_BUCK_PLACED = [
	groups.terraintile,
	groups.slab,
	groups.wall,
]

@export var name: String

@export var group: groups

@export var root: RootRes
@export var layer: int
@export var theme: int

@export var bulk_placement: bool

func _init(name_: String, root_: RootRes) -> void:
	root = root_
	var split_name = name_.trim_prefix("#").split("_",true,2)
	group = SHORTHANDS[split_name[0]]
	if group == groups.na:
		match root.tileset.resource_name:
			"Decor1 Tileset": group = groups.decor1
			"Decor2 Tileset": group = groups.decor2
			"Decor3 Tileset": group = groups.decor3
	
	theme = int(split_name[1])
	name = split_name[2]
	bulk_placement = group in CAN_BE_BUCK_PLACED

	
	
