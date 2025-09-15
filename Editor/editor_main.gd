extends Node2D

@onready var UI: Control = $UI
@onready var mainground: TileMapLayer = $Mainground
@onready var background: TileMapLayer = $Background

@export var MaingroundTileset: TileSet
@export var BackgroundTileset: TileSet

func _process(_delta: float) -> void:
	pass




func _on_control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	print(event)
