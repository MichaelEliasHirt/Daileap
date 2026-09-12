extends Control

@onready var tile_maps: TileMapManager = %TileMaps
@onready var settings: settingsUI = %Settings
@onready var save_buttons: saveUI = %SaveButtons
@onready var filename_edit: LineEdit = %FilenameEdit
@onready var vertical_slider: VSlider = %VerticalSlider

@onready var mainground: TileMapLayer = %Mainground
@onready var background: TileMapLayer = %Background
@onready var decor_1_layer: TileMapLayer = %Decor1Layer
@onready var decor_2_layer: TileMapLayer = %Decor2Layer
@onready var decor_3_layer: TileMapLayer = %Decor3Layer

@onready var entrance_arrow: Node2D = %EntranceArrow
@onready var exit_arrow: Node2D = %ExitArrow

@export var tiles_tileset: TileSet
@export var tiles_tileset_info: TileSetInfo
@export var traps_tileset_info: TileSetInfo

@export var walls_tileset: TileSet
@export var walls_tileset_info: TileSetInfo
@export var decor1_tileset: TileSet
@export var decor1_tileset_info: TileSetInfo
@export var decor2_tileset: TileSet
@export var decor2_tileset_info: TileSetInfo
@export var decor3_tileset: TileSet
@export var decor3_tileset_info: TileSetInfo
@export_dir var level_chunks_path: String

@export_subgroup("Settings")
@export var chunk_width: int = 14
@export var max_side_chunks: int = 5
@export var height_view_over: int = 5

signal tool_changed(current_tool:int)

var current_height: float
var current_side_chunk_index: int

var current_tool_index: int = 0


var chunk_data: LevelChunkRes
var viewport_position: Vector2

var all_UIDs: Array[StringName]
var all_chunks: Array[LevelChunkRes]


func _ready() -> void:
	
	
	#get_viewport().size_changed.connect(fit_to_screen)
	#fit_to_screen()
	#fix_all_terrains(tiles_tileset)
	#fix_all_terrains(walls_tileset)
	mainground.tile_set = tiles_tileset
	background.tile_set = walls_tileset
	decor_1_layer.tile_set = decor1_tileset
	decor_2_layer.tile_set = decor2_tileset
	decor_3_layer.tile_set = decor3_tileset
	
	#_on_vertical_slider_value_changed(0)
	
	load_filenames()
	await get_tree().process_frame
	generate_blank_chunk()


#func fit_to_screen() -> void:
	#var viewport_size = get_viewport_rect().size
	#camera.offset = viewport_size / 2 / 2
	#change_camera_y()
	#update_valid_build_region()


func _on_ui_selection_changed(_selection: SelectionRes) -> void:
	pass # Replace with function body.

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
	current_height = value - 1
	move_viewport()


func _on_world_viewport_viewport_scrolled(value: int) -> void:
	vertical_slider.value += value * 3. / chunk_data.height


func move_viewport():
	_check_move_btn_visibility()
	#viewport_position.y = (((chunk_data.height+1) * 16) + height_view_over * 32) * -current_height - height_view_over*16
	viewport_position.y = current_height * ((chunk_data.height  + height_view_over * 2) * 16 - tile_maps.get_parent().size.y / tile_maps.scale.y) + height_view_over*16
	viewport_position.x = -(current_side_chunk_index - chunk_data.chunks_left)  * ((chunk_width-1) * 16)
	
	var tween = get_tree().create_tween()
	tween.tween_property(tile_maps,"position",Vector2(viewport_position * tile_maps.scale),0.1)
	await tween.finished
	tween.kill()


func update_valid_build_region():
	_set_entrance_arrow()
	_check_move_btn_visibility()
	var placeable_rect = Rect2i(-abs(chunk_data.chunks_left * (chunk_width-1)),0,
		abs(((chunk_data.chunks_right + chunk_data.chunks_left) * (chunk_width-1)) + chunk_width),chunk_data.height)
		
	%HighlightGrid.position = placeable_rect.position * 16
	%HighlightGrid.size = placeable_rect.size * 16


## sets the level data
func _on_new_chunk_loaded(data: LevelChunkRes) -> void:
	
	current_side_chunk_index = data.chunks_left # center the view to the main chunk
	move_viewport()
	update_valid_build_region()
	

	await get_tree().create_timer(0.25).timeout
	%VerticalSlider.value = 0.01


func _set_entrance_arrow():
	entrance_arrow.position.y = chunk_data.height * 16
	@warning_ignore("integer_division")
	entrance_arrow.position.x = chunk_width / 2 * 16
	
	exit_arrow.position.y = 0
	@warning_ignore("integer_division")
	exit_arrow.position.x = (chunk_width / 2 * 16) + ((chunk_width - 1) * 16 * (chunk_data.exit_position - chunk_data.chunks_left))


func _check_move_btn_visibility() -> void:
	%MoveLeftBtn.visible = current_side_chunk_index > 0
	%MoveRightBtn.visible = current_side_chunk_index < (chunk_data.chunks_left + chunk_data.chunks_right)


func _on_move_left_btn_pressed() -> void:
	current_side_chunk_index = clampi(current_side_chunk_index - 1,0,chunk_data.chunks_left + chunk_data.chunks_right)
	move_viewport()


func _on_move_right_btn_pressed() -> void:
	current_side_chunk_index = clampi(current_side_chunk_index + 1,0,chunk_data.chunks_left + chunk_data.chunks_right)
	move_viewport()


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


func _on_rotate_left_btn_pressed() -> void:
	pass # Replace with function body.


func _on_rotate_right_btn_pressed() -> void:
	pass # Replace with function body.


func _on_settings_settings_changed(height: int, chunks_left: int, chunks_right: int, exit_position: int) -> void:
	chunk_data.height = height
	chunk_data.chunks_left = chunks_left
	chunk_data.chunks_right = chunks_right
	chunk_data.exit_position = exit_position
	
	current_side_chunk_index = chunks_left 
	update_valid_build_region()
	
	vertical_slider.step = .3 / chunk_data.height
	## ka geogebra formel
	vertical_slider.value = (((chunk_data.height  + height_view_over * 2) * 16 - tile_maps.get_parent().size.y / tile_maps.scale.y) - (height_view_over*16) +  viewport_position.y) / ((chunk_data.height  + height_view_over * 2) * 16 - tile_maps.get_parent().size.y / tile_maps.scale.y)
	
	move_viewport()
	data_changed()


func _on_settings_settings_discarded() -> void:
	settings.update_settings(chunk_data.height,chunk_data.chunks_left,chunk_data.chunks_right,chunk_data.exit_position)


func _on_save_buttons_save_data() -> void:

	
	var error = ResourceSaver.save(chunk_data,level_chunks_path + "/" + chunk_data.UID + ".tres")
	if error:
		print(error_string(error))
	
	
	filename_edit.update(chunk_data.name)
	settings.update_settings(chunk_data.height,chunk_data.chunks_left,chunk_data.chunks_right,chunk_data.exit_position)
	save_buttons.data_saved()

func _on_save_buttons_save_as_data(res_name: String) -> void:
	var UID: StringName
	load_filenames()
	while true:
		UID = generate_random_UID()
		if UID not in all_UIDs:
			break
	
	load_files()
	
	var name_extra_number: int = 0
	if res_name in all_chunks.map(func(i): return i.name):
		while true:
			name_extra_number += 1
			if res_name + "_" + str(name_extra_number) not in all_chunks.map(func(i): return i.name):
				break
		res_name = res_name + "_" + str(name_extra_number)
	
	chunk_data.UID = UID
	chunk_data.name = res_name
	
	var error = ResourceSaver.save(chunk_data,level_chunks_path + "/" + UID + ".tres")
	if error:
		print(error_string(error))
	
	
	filename_edit.unlock()
	filename_edit.update(chunk_data.name)
	settings.update_settings(chunk_data.height,chunk_data.chunks_left,chunk_data.chunks_right,chunk_data.exit_position)
	save_buttons.data_saved()

func load_filenames():
	all_UIDs.clear()
	for subpath in ResourceLoader.list_directory(level_chunks_path):
		if ResourceLoader.exists(level_chunks_path + "/" + subpath):
			all_UIDs.append(StringName(subpath))


func load_files():
	all_chunks.clear()
	for subpath in ResourceLoader.list_directory(level_chunks_path):
		if ResourceLoader.exists(level_chunks_path + "/" + subpath):
			var res = ResourceLoader.load(level_chunks_path + "/" + subpath)
			if res is LevelChunkRes:
				all_chunks.append(res)


func generate_random_UID() -> String:
	var string: StringName = ""
	for i in range(8):
		string += Array("1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ".rsplit()).pick_random()
	return string


func _on_save_buttons_load_new_data() -> void:
	generate_blank_chunk()


func generate_blank_chunk():
	chunk_data = LevelChunkRes.new()
	chunk_data.UID = StringName()
	chunk_data.chunks_left = 0
	chunk_data.chunks_right = 0
	chunk_data.difficulty = 0
	chunk_data.height = 30
	chunk_data.name = "unsaved_chunk"
	chunk_data.valid = false
	chunk_data.exit_position = 0
	
	filename_edit.lock()
	filename_edit.update(chunk_data.name)
	settings.update_settings(chunk_data.height,chunk_data.chunks_left,chunk_data.chunks_right,chunk_data.exit_position)
	data_changed()
	


func data_changed():
	save_buttons.data_changed()


func _on_filename_edit_text_changed(new_text: String) -> void:
	chunk_data.name = new_text
	data_changed()


func _on_save_buttons_load_data(UID: StringName) -> void:
	load_files()
	chunk_data = all_chunks[all_chunks.find_custom(func(x): return x.UID == UID)].duplicate(true)
	
	filename_edit.unlock()
	filename_edit.update(chunk_data.name)
	settings.update_settings(chunk_data.height,chunk_data.chunks_left,chunk_data.chunks_right,chunk_data.exit_position)
	save_buttons.data_saved()


func _on_save_buttons_discard_data() -> void:
	load_files()
	if chunk_data.UID == "":
		generate_blank_chunk()
		return
	
	chunk_data = all_chunks[all_chunks.find_custom(func(x): return x.UID == chunk_data.UID)].duplicate(true)
	
	filename_edit.unlock()
	filename_edit.update(chunk_data.name)
	settings.update_settings(chunk_data.height,chunk_data.chunks_left,chunk_data.chunks_right,chunk_data.exit_position)
	save_buttons.data_saved()
