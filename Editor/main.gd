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


var current_height: float
var current_side_chunk_index: int


var chunk_data: LevelChunkRes
var viewport_position: Vector2

var all_UIDs: Array[StringName]
var all_chunks: Array[LevelChunkRes]

signal chunk_data_updated(chunk_data: LevelChunkRes)


func _ready() -> void:
	mainground.tile_set = tiles_tileset
	background.tile_set = walls_tileset
	decor_1_layer.tile_set = decor1_tileset
	decor_2_layer.tile_set = decor2_tileset
	decor_3_layer.tile_set = decor3_tileset
	
	#_on_vertical_slider_value_changed(0)
	
	load_filenames()
	await get_tree().process_frame
	generate_blank_chunk()


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
	_update_chunk_data_from_map()
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
	_update_chunk_data_from_map()
	
	var error = ResourceSaver.save(chunk_data,level_chunks_path + "/" + UID + ".tres")
	if error:
		print(error_string(error))
	
	
	filename_edit.unlock()
	filename_edit.update(chunk_data.name)
	settings.update_settings(chunk_data.height,chunk_data.chunks_left,chunk_data.chunks_right,chunk_data.exit_position)
	save_buttons.data_saved()


func _update_chunk_data_from_map():
	chunk_data.background_tile_map_data = background.tile_map_data
	chunk_data.decor3_tile_map_data = decor_3_layer.tile_map_data
	chunk_data.mainground_tile_map_data = mainground.tile_map_data
	chunk_data.decor2_tile_map_data = decor_2_layer.tile_map_data
	chunk_data.decor1_tile_map_data = decor_1_layer.tile_map_data


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
	chunk_data_updated.emit(chunk_data)
	


func data_changed():
	save_buttons.data_changed()


func _on_filename_edit_text_changed(new_text: String) -> void:
	chunk_data.name = new_text
	data_changed()


func _on_save_buttons_load_data(UID: StringName) -> void:
	load_files()
	#load chunk with UID
	chunk_data = all_chunks[all_chunks.find_custom(func(x): return x.UID == UID)].duplicate(true)
	
	filename_edit.unlock()
	filename_edit.update(chunk_data.name)
	settings.update_settings(chunk_data.height,chunk_data.chunks_left,chunk_data.chunks_right,chunk_data.exit_position)
	save_buttons.data_saved()
	chunk_data_updated.emit(chunk_data)


func _on_save_buttons_discard_data() -> void:
	load_files()
	#if there is no UID generate new chunk
	if chunk_data.UID == "":
		generate_blank_chunk()
		return
	#if there is a UID reset the chunk
	chunk_data = all_chunks[all_chunks.find_custom(func(x): return x.UID == chunk_data.UID)].duplicate(true)
	
	filename_edit.unlock()
	filename_edit.update(chunk_data.name)
	settings.update_settings(chunk_data.height,chunk_data.chunks_left,chunk_data.chunks_right,chunk_data.exit_position)
	save_buttons.data_saved()
	chunk_data_updated.emit(chunk_data)
