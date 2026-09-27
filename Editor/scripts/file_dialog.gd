extends FileDialog

func _ready() -> void:
	get_vbox().get_child(0).visible = false
	get_vbox().get_child(1).get_child(1).get_child(0).get_child(0).text = "Level Chunks:"
	get_vbox().get_child(1).get_child(1).get_child(3).visible = false
