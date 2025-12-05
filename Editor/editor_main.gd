extends Node2D

@onready var tile_maps: TileMapManager = %TileMaps
@onready var camera: Camera2D = $Camera2D

@onready var UI: Control = %UI
@onready var mainground: TileMapLayer = %Mainground
@onready var background: TileMapLayer = %Background
@onready var control: Control = $BeforeMap/Control
@onready var entrance_arrow: Node2D = %EntranceArrow
@onready var exit_arrow: Node2D = %ExitArrow


@export var tiles_tileset: TileSet
@export var tiles_tileset_info: TileSetInfo
@export var walls_tileset: TileSet
@export var walls_tileset_info: TileSetInfo

@export_subgroup("Settings")
@export var chunk_width: int = 14
@export var max_chunks: int = 5
@export var height_view_over: int = 5

signal send_save_data(data: LevelChunkRes)
signal data_updated(data: LevelChunkRes)

@export var camera_pos = Vector2()
var last_vslider_value: float
var current_side_chunk_index: int

var current_tool_index: int = 0

var tool_start: bool
var tool_first_coord: Vector2
var erase_tool_start: bool
var erase_tool_first_coord: Vector2


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
	
	_on_vertical_slider_value_changed(0)


func fit_to_screen() -> void:
	var viewport_size = get_viewport_rect().size
	camera.offset = viewport_size / 2 / 2
	change_camera_y()
	update_valid_build_region()


func _on_control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		if control.get_rect().has_point(control.get_local_mouse_position()):
			match current_tool_index:
				0:
					if event is InputEventMouseMotion:
						if abs(event.screen_relative.x) > 16 or abs(event.screen_relative.x) > 16:
							if event.button_mask == 1:
								tile_maps.place(get_global_mouse_position() - (event.screen_relative/2))
							elif event.button_mask == 2:
								tile_maps.place(get_global_mouse_position() - (event.screen_relative/2),true)
					if event.button_mask == 1:
						tile_maps.place(get_global_mouse_position())
					elif event.button_mask == 2:
						tile_maps.place(get_global_mouse_position(),true)
				1:
					if event is InputEventMouseButton:
						if not event.is_echo():
							if event.button_mask == 1:
								tool_start = true
								tool_first_coord = get_global_mouse_position()
							if event.button_mask == 2:
								erase_tool_start = true
								erase_tool_first_coord = get_global_mouse_position()
								
					if tool_start:
						if event.button_mask == 1:
							tile_maps.line(tool_first_coord,get_global_mouse_position(),false,true)
							
						elif event.is_released():
							tool_start = false
							tile_maps.clear_temp()
							tile_maps.line(tool_first_coord,get_global_mouse_position())
						
					if erase_tool_start:
						if event.button_mask == 2:
							tile_maps.line(erase_tool_first_coord,get_global_mouse_position(),true,true)
							
						elif event.is_released():
							erase_tool_start = false
							tile_maps.clear_temp()
							tile_maps.line(erase_tool_first_coord,get_global_mouse_position(),true)
				2:
					if event is InputEventMouseButton:
						if not event.is_echo():
							if event.button_mask == 1:
								tool_start = true
								tool_first_coord = get_global_mouse_position()
							if event.button_mask == 2:
								erase_tool_start = true
								erase_tool_first_coord = get_global_mouse_position()
								
					if tool_start:
						if event.button_mask == 1:
							tile_maps.rect(tool_first_coord,get_global_mouse_position(),false,true)
							
						elif event.is_released():
							tool_start = false
							tile_maps.clear_temp()
							tile_maps.rect(tool_first_coord,get_global_mouse_position())
						
					if erase_tool_start:
						if event.button_mask == 2:
							tile_maps.rect(erase_tool_first_coord,get_global_mouse_position(),true,true)
							
						elif event.is_released():
							erase_tool_start = false
							tile_maps.clear_temp()
							tile_maps.rect(erase_tool_first_coord,get_global_mouse_position(),true)
				#3:
					#if event is InputEventMouseButton:
						#if not event.is_echo():
							#if event.button_mask == 1:
								#if tool_start:
									#tool_start = false
									#if tile_maps.is_hovering_temp(get_global_mouse_position()):
										#tile_maps.fill_by_tile(get_global_mouse_position())
									#tile_maps.clear_temp()
								#else:
									#tool_start = true
									#tile_maps.fill_by_tile(get_global_mouse_position(),true)
								#
							#elif event.button_mask == 2:
								#if erase_tool_start:
									#erase_tool_start = false
									#if tile_maps.is_hovering_temp(get_global_mouse_position()):
										#tile_maps.erase_fill_by_tile(get_global_mouse_position())
									#tile_maps.clear_temp()
								#else:
									#erase_tool_start = true
									#tile_maps.erase_fill_by_tile(get_global_mouse_position(),true)
				3:
					if event is InputEventMouseButton:
						if not event.is_echo():
							if event.button_mask == 1:
								if tool_start:
									tool_start = false
									if tile_maps.is_hovering_temp(get_global_mouse_position()):
										tile_maps.fill(get_global_mouse_position())
									tile_maps.clear_temp()
								else:
									var success = tile_maps.fill(get_global_mouse_position(),false,true)
									if success:
										tool_start = true
									else: tool_start = false

							elif event.button_mask == 2:
								if erase_tool_start:
									erase_tool_start = false
									if tile_maps.is_hovering_temp(get_global_mouse_position()):
										tile_maps.fill(get_global_mouse_position(),true)
									tile_maps.clear_temp()
								else:
									var success = tile_maps.fill(get_global_mouse_position(),true,true)
									if success:
										erase_tool_start = true
									else: erase_tool_start = false


func _on_ui_selection_changed(_selection: Dictionary) -> void:
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


func _on_line_btn_pressed() -> void:
	_reset_tools()
	current_tool_index = 1


func _on_rect_btn_pressed() -> void:
	_reset_tools()
	current_tool_index = 2


func _on_fill_cell_btn_pressed() -> void:
	_reset_tools()
	current_tool_index = 3


func _on_fill_auto_btn_pressed() -> void:
	_reset_tools()
	current_tool_index = 4


func _reset_tools() -> void:
	tool_start = false
	erase_tool_start = false
	tile_maps.clear_temp()
