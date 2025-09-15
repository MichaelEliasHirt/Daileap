extends Node2D

var all_chunks

func _ready() -> void:
	ResourceLoader.list_directory("res://Game/LevelChunks")
