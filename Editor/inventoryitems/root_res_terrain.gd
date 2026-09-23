extends RootRes
class_name RootResTerrain

@export var tileset: TileSet
@export var terrain_set_idx: int
@export var terrain_idx: int

@export var icon_texture: Texture2D
@export var icon_offset: Vector2i

func _init(tileset_: TileSet,terrain_set_idx_: int,terrain_idx_: int) -> void:
	tileset = tileset_
	terrain_set_idx = terrain_set_idx_
	terrain_idx = terrain_idx_

	for src_id in tileset.get_source_count():
		var src = tileset.get_source(src_id)
		for tiles_idx in range(src.get_tiles_count()):
			var tile_id := src.get_tile_id(tiles_idx)
			var tiledata = src.get_tile_data(tile_id, 0)
			if tiledata.terrain_set == terrain_set_idx and tiledata.terrain == terrain_idx:
				icon_texture = AtlasTexture.new()
				icon_texture.atlas = src.texture
				icon_texture.region = src.get_tile_texture_region(tile_id,0)
				icon_offset = tiledata.texture_origin
				
				break
	
