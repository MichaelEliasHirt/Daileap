extends Label

var hided := true

func update_info(coords:Vector2i):
	if not hided:
		text = "X: %s Y: %s" % [coords.x,coords.y]


func _on_control_mouse_entered() -> void:
	hided = false


func _on_control_mouse_exited() -> void:
	hided = true
	text = ""
