extends Control

@onready var tile_maps: TileMapManager = %TileMaps
@onready var highlight_grid: ColorRect = %HighlightGrid

signal viewport_scrolled(value:int)
signal mouse_moved(coords:Vector2)


func _ready():
	get_viewport().size_changed.connect(fit_to_screen)
	await get_tree().process_frame
	fit_to_screen()
	
	
func fit_to_screen() -> void:
	var factor = ($MarginContainer/TileMapViewportContainer.size.x / (owner.chunk_width * 16))
	tile_maps.scale = Vector2.ONE * factor
	highlight_grid.material.set_shader_parameter("grid_size",16 * factor)

func _gui_input(event: InputEvent) -> void:
	## handle the scrolling with the mousewheel
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				viewport_scrolled.emit(1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				viewport_scrolled.emit(-1)
	elif event is InputEventMouseMotion:
		mouse_moved.emit(event.global_position)
