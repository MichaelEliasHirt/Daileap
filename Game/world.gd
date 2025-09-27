extends Node2D

@export_dir var level_chunks_path: String

@export var MaingroundTileset: TileSet
@export var BackgroundTileset: TileSet

@export var level_length: int = 5
@export var end_chunk: PackedScene
@export var test_chunk: LevelChunkRes

@export_subgroup("Settings")
@export var chunk_width: int = 14

@onready var mainground: TileMapLayer = %Mainground
@onready var background: TileMapLayer = %Background
@onready var camera_2d: Camera2D = %Camera2D

var level_height: int
var lastest_level_exit_position: int
var all_chunks: Array


func _ready() -> void:
	mainground.tile_set = MaingroundTileset
	background.tile_set = BackgroundTileset
	_update_dir()
	load_level(randi())



func load_level(rand_seed:int):
	seed(rand_seed)
	
	
	camera_2d.limit_bottom = 13 * 16 - int(camera_2d.offset.y)
	level_height = 0
	lastest_level_exit_position = 0
	
	if test_chunk:
		_add_chunk(test_chunk)
		return
		
	var allready_chosen_chunks: Array[LevelChunkRes]
	
	for x in range(level_length):
		var chunk: LevelChunkRes
		while true:
			chunk = all_chunks.pick_random()
			if not chunk in allready_chosen_chunks:
				allready_chosen_chunks.append(chunk)
				break
				
		_add_chunk(chunk)
	
	var ending = end_chunk.instantiate() as Node2D
	$TileMaps.add_child(ending)
	ending.position = Vector2i(((lastest_level_exit_position) * (chunk_width - 1) * 16),-(level_height + 11) * 16)
	ending.regen_btn_pressed.connect(regen_btn_pressed)


func regen_btn_pressed():
	get_tree().reload_current_scene()


func _update_dir():
	all_chunks.clear()
	for subpath in ResourceLoader.list_directory(level_chunks_path):
		if ResourceLoader.exists(level_chunks_path + "/" + subpath):
			var res = ResourceLoader.load(level_chunks_path + "/" + subpath)
			if res is LevelChunkRes:
				if res.difficulty >= 1:
					all_chunks.append(res)


func _add_chunk(level_chunk:LevelChunkRes):
	level_height += level_chunk.height
	var offset = Vector2i(lastest_level_exit_position * (chunk_width - 1),-level_height)
	
	_merge_tilemaps(mainground,level_chunk.mainground_tile_map_data,offset)
	_merge_tilemaps(background,level_chunk.background_tile_map_data,offset)
	
	lastest_level_exit_position += (level_chunk.exit_chunk - level_chunk.chunks_left)



func _merge_tilemaps(tilemap:TileMapLayer,merge_tile_map_data: PackedByteArray,offset:Vector2i):
	var temp_tilemap = tilemap.duplicate()
	temp_tilemap.tile_map_data = merge_tile_map_data
	for cell_coords in temp_tilemap.get_used_cells():
		var cell_source_id = temp_tilemap.get_cell_source_id(cell_coords)
		var cell_atlas_coords = temp_tilemap.get_cell_atlas_coords(cell_coords)
		var cell_alternative_tile = temp_tilemap.get_cell_alternative_tile(cell_coords)
		
		tilemap.set_cell(cell_coords + offset,cell_source_id,cell_atlas_coords,cell_alternative_tile)
