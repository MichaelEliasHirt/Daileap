extends Node2D

const PLAYER = preload("uid://7ybaa4xotguu")
const PLAYER_HEAD = preload("uid://bruxso3gr60bm")

@export_dir var level_chunks_path: String

@export var MaingroundTileset: TileSet
@export var BackgroundTileset: TileSet
@export var Decor1LayerTileset: TileSet
@export var Decor2LayerTileset: TileSet
@export var Decor3LayerTileset: TileSet

@export var level_length: int = 5
@export var end_chunk: PackedScene
@export var test_chunk: LevelChunkRes

@export_subgroup("Settings")
@export var chunk_width: int = 14

@onready var mainground: TileMapLayer = %Mainground
@onready var background: TileMapLayer = %Background
@onready var decor_1_layer: TileMapLayer = %Decor1Layer
@onready var decor_2_layer: TileMapLayer = %Decor2Layer
@onready var decor_3_layer: TileMapLayer = %Decor3Layer

@onready var camera_2d: Camera2D = %Camera2D
@onready var player_spawn_location: Node2D = %PlayerSpawnLocation


var level_height: int
var lastest_level_exit_position: int
var all_chunks: Array

var current_player: PlayerController

func _ready() -> void:
	mainground.tile_set = MaingroundTileset
	background.tile_set = BackgroundTileset
	background.tile_set = BackgroundTileset
	decor_1_layer.tile_set = Decor1LayerTileset
	decor_2_layer.tile_set = Decor2LayerTileset
	decor_3_layer.tile_set = Decor3LayerTileset
	_update_dir()
	load_level(randi())
	_spawn_player()
	

func _respawn_player():
	_free_player()
	
	var player_head = _spawn_bounce_head()
	
	await get_tree().create_timer(5).timeout
	player_head.queue_free()

	_spawn_player()


func _spawn_bounce_head() -> RigidBody2D:
	var player_head: RigidBody2D = PLAYER_HEAD.instantiate()
	player_head.global_position = current_player.head_spawn_position.global_position
	player_head.linear_velocity = current_player.velocity * 1.5
	camera_2d.follow_player = player_head
	call_deferred("add_child",player_head)
	return player_head

func _spawn_player():
	var player: PlayerController = PLAYER.instantiate() 
	call_deferred("add_child",player,true)
	player.position = player_spawn_location.position
	player.world_position_particle_generators = %WorldPositionParticleGenerators
	camera_2d.follow_player = player
	current_player = player
	player.died.connect(_respawn_player)


func _free_player():
	if current_player:
		current_player.queue_free()
		call_deferred("remove_child",current_player)


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
	_merge_tilemaps(decor_1_layer,level_chunk.decor1_tile_map_data,offset*2) # smaller tiles so *2
	_merge_tilemaps(decor_2_layer,level_chunk.decor2_tile_map_data,offset*2)
	_merge_tilemaps(decor_3_layer,level_chunk.decor3_tile_map_data,offset*2)
	
	lastest_level_exit_position += (level_chunk.exit_chunk - level_chunk.chunks_left)



func _merge_tilemaps(tilemap:TileMapLayer,merge_tile_map_data: PackedByteArray,offset:Vector2i):
	var temp_tilemap = tilemap.duplicate()
	temp_tilemap.tile_map_data = merge_tile_map_data
	for cell_coords in temp_tilemap.get_used_cells():
		var cell_source_id = temp_tilemap.get_cell_source_id(cell_coords)
		var cell_atlas_coords = temp_tilemap.get_cell_atlas_coords(cell_coords)
		var cell_alternative_tile = temp_tilemap.get_cell_alternative_tile(cell_coords)
		
		tilemap.set_cell(cell_coords + offset,cell_source_id,cell_atlas_coords,cell_alternative_tile)
