extends Node2D

@onready var tile_maps: Node2D = %TileMaps
@onready var camera: Camera2D = $Camera2D

@onready var UI: Control = %UI
@onready var mainground: TileMapLayer = %Mainground
@onready var background: TileMapLayer = %Background
@onready var control: Control = $BeforeMap/MarginContainer/Control


@export var MaingroundTileset: TileSet
@export var BackgroundTileset: TileSet

@export_subgroup("Settings")
@export var chunk_width: int = 14
@export var max_chunks: int = 5
@export var height_view_over: int = 5

var camera_pos = Vector2()
var last_vslider_value: float

###Level Settings
var chunks_left:int = 0
var chunks_right:int = 0
var height:int = 40



func _ready() -> void:
	get_viewport().size_changed.connect(fit_to_screen)
	fit_to_screen()
	fix_all_terrains(MaingroundTileset)
	fix_all_terrains(BackgroundTileset)
	mainground.tile_set = MaingroundTileset
	background.tile_set = BackgroundTileset
	
	_on_vertical_slider_value_changed(0)


func fit_to_screen() -> void:
	var viewport_size = get_viewport_rect().size
	camera.offset = viewport_size / camera.zoom / 2
	change_camera_y()
	update_valid_build_region()





func _on_control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if event.button_mask == 1:
			if not event.is_echo():
				if control.get_rect().has_point(control.get_local_mouse_position()):
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


func _on_vertical_slider_value_changed(value: float) -> void:
	last_vslider_value = value -1
	change_camera_y()


func change_camera_y():
	camera_pos.y = (((height+1) * 16 - (get_viewport_rect().size.y/camera.zoom.y)) + height_view_over * 32) * -last_vslider_value - height_view_over*16
	
	var tween = get_tree().create_tween()
	tween.tween_property(camera,"position",Vector2(camera_pos),0.1)
	await tween.finished
	tween.kill()


func update_valid_build_region():
	var placeable_rect = Rect2i(-abs(chunks_left * (chunk_width-1)),0,
		abs(chunks_right * (chunk_width-1)+chunk_width),height)
	print(placeable_rect)
		
	%HighlightGrid.position = placeable_rect.position * 16
	%HighlightGrid.size = placeable_rect.size * 16
