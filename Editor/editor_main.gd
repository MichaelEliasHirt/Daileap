extends Node2D

@onready var tile_maps: Node2D = %TileMaps

@onready var UI: Control = %UI
@onready var mainground: TileMapLayer = %Mainground
@onready var background: TileMapLayer = %Background

@export var MaingroundTileset: TileSet
@export var BackgroundTileset: TileSet

func _ready() -> void:
	fix_all_terrains(MaingroundTileset)
	fix_all_terrains(BackgroundTileset)


func _process(_delta: float) -> void:
	mainground.tile_set = MaingroundTileset
	background.tile_set = BackgroundTileset

func _on_control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if event.button_mask == 1:
			if not event.is_echo():
				tile_maps.place_mouse_coords(get_global_mouse_position())


func _on_ui_selection_changed(_selection: Dictionary) -> void:
	pass # Replace with function body.


func fix_all_terrains(tileset:TileSet):
	var terrains: Array
	
	for terrain_sets_idx in range(tileset.get_terrain_sets_count()):
		var terrains_ := []
		for terrain_idx in range(tileset.get_terrains_count(terrain_sets_idx)):
			terrains_.append([])
		terrains.append(terrains_)
			
			
	for src_idx in tileset.get_source_count():
		var src := tileset.get_source(tileset.get_source_id(src_idx))
		
		for tiles_idx in range(src.get_tiles_count()):
			var tile_id := src.get_tile_id(tiles_idx)
			var tiledata = src.get_tile_data(tile_id, 0)
			
			if tiledata.terrain_set != -1 and tiledata.terrain != -1:
				for bit in range(15):
					if tiledata.is_valid_terrain_peering_bit(bit):
						if tiledata.get_terrain_peering_bit(bit) != -1:
							tiledata.set_meta("has_perring_bit_source",src)
							break
							
				terrains[tiledata.terrain_set][tiledata.terrain].append(tiledata)
				
	for terrains_ in terrains:
		for terrain in terrains_:
			if terrain.all(func(x): return x.has_meta("has_perring_bit_source")):
				var src = terrain[terrain.find_custom(func(x): return x.has_meta("has_perring_bit_source"))].get_meta("has_perring_bit_source") as TileSetAtlasSource
				var altid = src.create_alternative_tile(Vector2i(0,0))
				var alt_tiledata = src.get_tile_data(Vector2i(0,0),altid) as TileData
				alt_tiledata.terrain_set = terrain.front().terrain_set
				alt_tiledata.terrain = terrain.front().terrain
