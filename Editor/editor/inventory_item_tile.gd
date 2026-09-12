extends Resource
class_name InventoryItemTile

@export var name: String

@export var tileset: TileSet
@export var source_id: int
@export var tile_coords: Vector2i
@export var alt_id: int

@export var theme: StringName
@export var texture: Texture2D


func _init(name_: String,tileset_: TileSet, source_id_: int, tile_coords_: Vector2i, alt_id_: int) -> void:
	name = name_
	tileset = tileset_
	source_id = source_id_
	tile_coords = tile_coords_ 
	alt_id = alt_id_
	
	var src = tileset.get_source(source_id)
	texture = AtlasTexture.new()
	texture.atlas = src.texture
	texture.region = src.get_tile_texture_region(tile_coords_,0)
