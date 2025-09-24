extends Node2D

@export var MaingroundTileset: TileSet
@export var BackgroundTileset: TileSet

@export var start_chunk: LevelChunkRes
@export_subgroup("Settings")
@export var chunk_width: int = 14

@onready var mainground: TileMapLayer = %Mainground
@onready var background: TileMapLayer = %Background
@onready var camera_2d: Camera2D = %Camera2D

var level_height: int
var lastest_level_exit_position: int


func _ready() -> void:
	mainground.tile_set = MaingroundTileset
	background.tile_set = BackgroundTileset
	
	load_level(0)



func load_level(rand_seed:int):
	seed(rand_seed)
	
	mainground.clear()
	background.clear()
	
	
	
	camera_2d.limit_bottom = start_chunk.height * 16 - int(camera_2d.offset.y)
	level_height = -start_chunk.height
	lastest_level_exit_position = 0
	
	_add_chunk(start_chunk)
	_add_chunk(load("uid://cmex37aagcvqo"))
	_add_chunk(load("uid://cmex37aagcvqo"))
	_add_chunk(load("uid://cmex37aagcvqo"))
	_add_chunk(load("uid://cmex37aagcvqo"))
	_add_chunk(load("uid://clf56qwcumc4a"))
	
	

func _add_chunk(level_chunk:LevelChunkRes):
	level_height += level_chunk.height
	var offset = Vector2i(lastest_level_exit_position * (chunk_width - 1),-level_height)
	
	print("current offset:" + str(offset))
	_merge_tilemaps(mainground,level_chunk.mainground_tile_map_data,offset)
	_merge_tilemaps(background,level_chunk.background_tile_map_data,offset)
	
	
	print("current height:" + str(level_height))
	lastest_level_exit_position += (level_chunk.exit_chunk - level_chunk.chunks_left)



func _merge_tilemaps(tilemap:TileMapLayer,merge_tile_map_data: PackedByteArray,offset:Vector2i):
	var temp_tilemap = tilemap.duplicate()
	temp_tilemap.tile_map_data = merge_tile_map_data
	for cell_coords in temp_tilemap.get_used_cells():
		var cell_source_id = temp_tilemap.get_cell_source_id(cell_coords)
		var cell_atlas_coords = temp_tilemap.get_cell_atlas_coords(cell_coords)
		var cell_alternative_tile = temp_tilemap.get_cell_alternative_tile(cell_coords)
		
		tilemap.set_cell(cell_coords + offset,cell_source_id,cell_atlas_coords,cell_alternative_tile)
