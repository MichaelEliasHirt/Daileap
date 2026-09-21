extends RootRes
class_name RootResTile

@export var tileset: TileSet
@export var source_id: int
@export var tile_coords: Vector2i
@export var alt_id: int

@export var icon_texture: Texture2D
@export var icon_offset: Vector2i

func _init(tileset_: TileSet,source_id_: int,tile_coords_: Vector2i, alt_id_: int) -> void:
	tileset = tileset_
	source_id = source_id_
	tile_coords = tile_coords_
	alt_id = alt_id_

	var src = tileset.get_source(source_id)

	icon_texture = AtlasTexture.new()
	icon_texture.atlas = src.texture
	icon_texture.region = src.get_tile_texture_region(tile_coords,0)
	icon_offset = src.get_tile_data(tile_coords,alt_id).texture_origin
	
