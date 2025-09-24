extends Camera2D

@export var follow_player: Node2D
@export var smoothing_enabled: bool
@export_range(1,10) var smoothing_distance : int = 8

@export var screen_width: int = 208

var screen_change_tween: Tween
var screen_idx : int
var last_screen_idx : int

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	var camera_position : Vector2
	
	if smoothing_enabled:
		var weight = float (11 - smoothing_distance) / 100
		camera_position = lerp(global_position, follow_player.global_position, weight)
	else:
		camera_position = follow_player.global_position
	
	global_position = camera_position.floor()

	@warning_ignore("integer_division")
	screen_idx = floor(follow_player.global_position.x / screen_width)
	if last_screen_idx != screen_idx:
		change_screens()
	
	last_screen_idx = screen_idx
	

func change_screens():
	screen_change_tween = get_tree().create_tween()
	
	screen_change_tween.tween_property(self,"limit_left",screen_width * screen_idx,0.3)
	screen_change_tween.parallel().tween_property(self,"limit_right",screen_width * (screen_idx +1),0.3)
	
	await screen_change_tween.finished
	limit_left = screen_width * screen_idx
	limit_right = screen_width * (screen_idx +1)
	screen_change_tween.kill()
