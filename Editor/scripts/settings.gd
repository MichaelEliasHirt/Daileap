class_name settingsUI extends Control

@onready var height_edit: SpinBox = $MarginContainer/VBoxContainer/HeightSettingContainer/HeightEdit
@onready var side_chunk_manager: VBoxContainer = $MarginContainer/VBoxContainer/SideChunksSettingContainer/Control/MarginContainer/SideChunkManager

@onready var edit_settings_buttons_container: VBoxContainer = $MarginContainer/VBoxContainer/EditSettingsButtonsContainer
@onready var difficulty_edit: SpinBox = $MarginContainer/VBoxContainer/DifficultySettingContainer/DifficultyEdit
@onready var valid_edit: CheckBox = $MarginContainer/VBoxContainer/ValidSettingContainer/ValidEdit


signal settings_changed(height: int, chunks_left: int, chunks_right: int, exit_position: int, difficulty: int, validility: bool)
signal settings_discarded

var height: int
var chunks_left: int
var chunks_right: int
var exit_position: int
var difficulty: int
var validility: bool

var has_unapplied_changes: bool:
	set(value):
		has_unapplied_changes = value
		edit_settings_buttons_container.visible = value
		if value:
			self_modulate = Color(0.81, 0.743, 0.138, 0.714)
		else:
			self_modulate = Color(1.0, 1.0, 1.0, 1.0)


## update the settings after e.g. loading a new chunk
func update_settings(new_height: int, new_chunks_left: int, new_chunks_right: int, new_exit_position: int, new_difficulty: int, new_validility: bool):
	
	height = new_height
	chunks_left = new_chunks_left
	chunks_right = new_chunks_right
	exit_position = new_exit_position
	difficulty = new_difficulty
	validility = new_validility
	
	#update the setting ui
	height_edit.value = height
	side_chunk_manager.update(chunks_left,chunks_right,exit_position)
	edit_settings_buttons_container.hide()
	
	difficulty_edit.value = float(difficulty)
	valid_edit.button_pressed = validility
	
	has_unapplied_changes = false
	settings_changed.emit(new_height,new_chunks_left,new_chunks_right,new_exit_position, new_difficulty, new_validility)


func _on_height_edit_value_changed(value: float) -> void:
	has_unapplied_changes = true
	height = int(value)


func _on_side_chunk_manager_update_chunks(new_chunks_left: int, new_chunks_right: int, new_exit_position: int) -> void:
	has_unapplied_changes = true
	chunks_left = new_chunks_left
	chunks_right = new_chunks_right
	exit_position = new_exit_position


func _on_side_chunk_manager_update_exit(new_exit_position: int) -> void:
	has_unapplied_changes = true
	exit_position = new_exit_position


func _on_discard_btn_pressed() -> void:
	settings_discarded.emit()


func _on_apply_btn_pressed() -> void:
	has_unapplied_changes = false
	settings_changed.emit(height,chunks_left,chunks_right,exit_position,difficulty,validility)


func _on_difficulty_edit_value_changed(value: int) -> void:
	has_unapplied_changes = true
	difficulty = value


func _on_valid_edit_toggled(toggled_on: bool) -> void:
	has_unapplied_changes = true
	validility = toggled_on
