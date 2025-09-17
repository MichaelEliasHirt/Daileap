extends Label

func update_info(coords:Vector2i):
	text = "X: %s Y: %s" % [coords.x,coords.y]
