extends Node2D

@onready var tile_maps: TileMapManager = %TileMaps
@onready var camera: Camera2D = $Camera2D

@onready var UI: Control = %UI
@onready var mainground: TileMapLayer = %Mainground
@onready var background: TileMapLayer = %Background
@onready var decor_1_layer: TileMapLayer = %Decor1Layer
@onready var decor_2_layer: TileMapLayer = %Decor2Layer

@onready var entrance_arrow: Node2D = %EntranceArrow
@onready var exit_arrow: Node2D = %ExitArrow


@export var tiles_tileset: TileSet
@export var tiles_tileset_info: TileSetInfo
@export var walls_tileset: TileSet
@export var walls_tileset_info: TileSetInfo
@export var decor1_tileset: TileSet
@export var decor1_tileset_info: TileSetInfo
@export var decor2_tileset: TileSet
@export var decor2_tileset_info: TileSetInfo

@export_subgroup("Settings")
@export var chunk_width: int = 14
@export var max_chunks: int = 5
@export var height_view_over: int = 5

signal send_save_data(data: LevelChunkRes)
signal data_updated(data: LevelChunkRes)

signal tool_changed(current_tool:int)

@export var camera_pos = Vector2()
var last_vslider_value: float
var current_side_chunk_index: int

var current_tool_index: int = 0


var chunk_name: String = ""
var valid: bool = true
var difficulty: int = 0
var UID: String

###Level Settings
var chunks_left:int = 0
var chunks_right:int = 0
var height:int = 0
var exit_chunk:int = 0


func _ready() -> void:
	get_viewport().size_changed.connect(fit_to_screen)
	fit_to_screen()
	#fix_all_terrains(tiles_tileset)
	#fix_all_terrains(walls_tileset)
	mainground.tile_set = tiles_tileset
	background.tile_set = walls_tileset
	decor_1_layer.tile_set = decor1_tileset
	decor_2_layer.tile_set = decor2_tileset
	
	_on_vertical_slider_value_changed(0)


func fit_to_screen() -> void:
	var viewport_size = get_viewport_rect().size
	camera.offset = viewport_size / 2 / 2
	change_camera_y()
	update_valid_build_region()


func _on_ui_selection_changed(_selection: SelectionRes) -> void:
	pass # Replace with function body.

#
#func fix_all_terrains(tileset:TileSet):
	#var terrains: Array
	#pass
	##for terrain_sets_idx in range(tileset.get_terrain_sets_count()):
		##var terrains_ := []
		##for terrain_idx in range(tileset.get_terrains_count(terrain_sets_idx)):
			##terrains_.append([])
		##terrains.append(terrains_)
			##
			##
	##for src_idx in tileset.get_source_count():
		##var src := tileset.get_source(tileset.get_source_id(src_idx))
		##
		##for tiles_idx in range(src.get_tiles_count()):
			##var tile_id := src.get_tile_id(tiles_idx)
			##var tiledata = src.get_tile_data(tile_id, 0)
			##
			##if tiledata.terrain_set != -1 and tiledata.terrain != -1:
				##for bit in range(15):
					##if tiledata.is_valid_terrain_peering_bit(bit):
						##if tiledata.get_terrain_peering_bit(bit) != -1:
							##tiledata.set_meta("has_perring_bit_source",src)
							##break
							##
				##terrains[tiledata.terrain_set][tiledata.terrain].append(tiledata)
				##
	##for terrains_ in terrains:
		##for terrain in terrains_:
			##if terrain.all(func(x): return x.has_meta("has_perring_bit_source")):
				##var src = terrain[terrain.find_custom(func(x): return x.has_meta("has_perring_bit_source"))].get_meta("has_perring_bit_source") as TileSetAtlasSource
				##var altid = src.create_alternative_tile(Vector2i(0,0))
				##var alt_tiledata = src.get_tile_data(Vector2i(0,0),altid) as TileData
				##alt_tiledata.terrain_set = terrain.front().terrain_set
				##alt_tiledata.terrain = terrain.front().terrain
#

func _on_vertical_slider_value_changed(value: float) -> void:
	last_vslider_value = value -1
	change_camera_y()


func change_camera_y():
	camera_pos.y = (((height+1) * 16 - (get_viewport_rect().size.y/camera.zoom.y)) + height_view_over * 32) * -last_vslider_value - height_view_over*16
	
	var tween = get_tree().create_tween()
	tween.tween_property(camera,"position",Vector2(camera_pos),0.1)
	await tween.finished
	tween.kill()


func change_camera_x():
	_check_move_btn_visibility()
	camera_pos.x = (current_side_chunk_index - chunks_left) * ((chunk_width-1) * 16)
	
	var tween = get_tree().create_tween()
	tween.tween_property(camera,"position",Vector2(camera_pos),0.2)
	await tween.finished
	tween.kill()


func update_valid_build_region():
	_set_entrance_arrow()
	_check_move_btn_visibility()
	var placeable_rect = Rect2i(-abs(chunks_left * (chunk_width-1)),0,
		abs(((chunks_right + chunks_left) * (chunk_width-1)) + chunk_width),height)
		
	%HighlightGrid.position = placeable_rect.position * 16
	%HighlightGrid.size = placeable_rect.size * 16


func _on_save_menu_request_save_data() -> void:
	
	var data = LevelChunkRes.new()
	data.name = chunk_name
	data.valid = valid
	data.difficulty = difficulty
	data.mainground_tile_map_data = mainground.tile_map_data
	data.background_tile_map_data = background.tile_map_data
	data.chunks_left = chunks_left
	data.chunks_right = chunks_right
	data.exit_chunk = exit_chunk
	data.height = height
	data.UID = UID
	
	send_save_data.emit(data)


func _on_settings_settings_changed(settings: ChunkSettings) -> void:
	height = settings.height
	chunks_left = settings.chunks_left
	chunks_right = settings.chunks_right
	exit_chunk = settings.exit_chunk
	update_valid_build_region()


func _on_save_menu_name_changed(_name: String) -> void:
	chunk_name = _name


func _on_save_menu_new_chunk_loaded(data: LevelChunkRes) -> void:
	UID = data.UID
	chunk_name = data.name
	valid = data.valid
	difficulty = data.difficulty
	mainground.tile_map_data = data.mainground_tile_map_data
	background.tile_map_data = data.background_tile_map_data
	chunks_left = data.chunks_left
	chunks_right = data.chunks_right
	exit_chunk = data.exit_chunk
	height = data.height
	
	current_side_chunk_index = chunks_left # the main chunk is counted from the left so...
	change_camera_x()
	
	update_valid_build_region()
	
	
	data_updated.emit(data)
	await get_tree().create_timer(0.25).timeout
	%VerticalSlider.value = 0.01


func _set_entrance_arrow():
	entrance_arrow.position.y = height * 16
	entrance_arrow.position.x = chunk_width / 2 * 16
	
	exit_arrow.position.y = 0
	exit_arrow.position.x = (chunk_width / 2 * 16) + ((chunk_width - 1) * 16 * (exit_chunk - chunks_left))


func _check_move_btn_visibility() -> void:
	%MoveLeftBtn.visible = current_side_chunk_index > 0
	%MoveRightBtn.visible = current_side_chunk_index < (chunks_left + chunks_right)


func _on_move_left_btn_pressed() -> void:
	current_side_chunk_index = clampi(current_side_chunk_index - 1,0,chunks_left + chunks_right)
	change_camera_x()


func _on_move_right_btn_pressed() -> void:
	current_side_chunk_index = clampi(current_side_chunk_index + 1,0,chunks_left + chunks_right)
	change_camera_x()


func _on_paint_btn_pressed() -> void:
	_reset_tools()
	current_tool_index = 0
	tool_changed.emit(current_tool_index)


func _on_line_btn_pressed() -> void:
	_reset_tools()
	current_tool_index = 1
	tool_changed.emit(current_tool_index)


func _on_rect_btn_pressed() -> void:
	_reset_tools()
	current_tool_index = 2
	tool_changed.emit(current_tool_index)


func _on_fill_cell_btn_pressed() -> void:
	_reset_tools()
	current_tool_index = 3
	tool_changed.emit(current_tool_index)


func _on_fill_auto_btn_pressed() -> void:
	_reset_tools()
	current_tool_index = 4
	tool_changed.emit(current_tool_index)


func _reset_tools() -> void:
	tile_maps.clear_temp()
