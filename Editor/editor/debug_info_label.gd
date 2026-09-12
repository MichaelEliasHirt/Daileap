extends Label

func update_info(coords:Vector2i):
	if visible:
		text = "X:%s Y:%s" % [coords.x,coords.y]


func _on_world_viewport_mouse_moved(coords: Vector2) -> void:
	coords = %Mainground.local_to_map(%Mainground.to_local(coords))
	update_info(coords)


func _on_world_viewport_mouse_entered() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self,"modulate:a",1,0.1)
	await tween.finished
	tween.kill()

func _on_world_viewport_mouse_exited() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self,"modulate:a",0,0.2)
	await tween.finished
	tween.kill()
