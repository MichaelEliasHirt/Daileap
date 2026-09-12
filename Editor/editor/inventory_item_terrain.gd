extends Resource
class_name InventoryItemTerrain

@export var name: String

@export var tileset: TileSet

@export var terrain_set_idx: int
@export var terrain_idx: int

@export var theme: StringName

@export var texture: Texture2D

func _init(name_: String,tileset_: TileSet, terrain_set_idx_: int, terrain_idx_: int) -> void:
	name = name_
	tileset = tileset_
	terrain_set_idx = terrain_set_idx_
	terrain_idx = terrain_idx_
	theme = name_.lstrip("#").get_slice("_",0)
	
	for src_id in tileset.get_source_count():
		var src = tileset.get_source(src_id)
		for tiles_idx in range(src.get_tiles_count()):
			var tile_id := src.get_tile_id(tiles_idx)
			var tiledata = src.get_tile_data(tile_id, 0)
			if tiledata.terrain_set == terrain_set_idx and tiledata.terrain == terrain_idx:
				texture = AtlasTexture.new()
				texture.atlas = src.texture
				texture.region = src.get_tile_texture_region(tile_id,0)
				break
