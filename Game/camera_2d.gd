extends Camera2D

@export var screen_width: int = 208

var screen_change_tween: Tween
var screen_idx : int
var last_screen_idx : int



func change_screens():
	screen_change_tween = get_tree().create_tween()
	
	screen_change_tween.tween_property(self,"limit_left",screen_width * screen_idx,0.3)
	screen_change_tween.parallel().tween_property(self,"limit_right",screen_width * (screen_idx +1),0.3)
	
	await screen_change_tween.finished
	limit_left = screen_width * screen_idx
	limit_right = screen_width * (screen_idx +1)
	screen_change_tween.kill()
