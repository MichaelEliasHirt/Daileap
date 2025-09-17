extends Control

func _ready():
	get_viewport().size_changed.connect(fit_to_screen)
	
func fit_to_screen() -> void:
	var viewport_size = get_viewport_rect().size
	size = viewport_size/scale
