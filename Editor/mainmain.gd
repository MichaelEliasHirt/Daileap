extends Node

@export var GameMain: PackedScene
@export var EditorMain: PackedScene

@export var LaunchinEditor: bool

func _ready() -> void:
	if LaunchinEditor:
		launch_editor()
	else:
		launch_game()

func launch_editor():
	get_tree().change_scene_to_packed.call_deferred(EditorMain)
	
func launch_game():
	get_tree().change_scene_to_packed.call_deferred(GameMain)
