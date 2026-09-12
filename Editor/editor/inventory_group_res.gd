extends Resource
class_name InventoryGroupRes

enum tileset_names {tiles,walls,decor1,decor2,decor3}

@export var name: String
@export var specifics: Dictionary[String,PackedStringArray]
@export var themes: Dictionary[String,String]

@export var color: Color = Color(1.0, 1.0, 1.0, 1.0)
## when using multible tilesets, the specifics have to have the names of the tilesets
@export var tilesets: Dictionary[String,tileset_names]
