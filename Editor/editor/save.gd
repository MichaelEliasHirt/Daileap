class_name saveUI extends Control

@onready var save_btn: Button = $SaveBtn
@onready var unsaved_dialog: AcceptDialog = $UnsavedDialog
@onready var save_as_dialog: Window = $SaveAsDialog
@onready var save_buttons_container: PanelContainer = %SaveButtonsContainer
@onready var load_dialog: Window = $LoadDialog

signal load_new_data
signal load_data(UID:StringName)
signal save_data
signal save_as_data(name:String)
signal discard_data

var unsaved_changes: bool
var prevented_function

func data_changed():
	save_buttons_container.self_modulate = Color(0.81, 0.743, 0.138, 0.714)
	unsaved_changes = true


func data_saved():
	save_buttons_container.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	unsaved_changes = false


func _on_new_btn_pressed() -> void:
	if unsaved_changes:
		prevented_function = _on_new_btn_pressed
		unsaved_dialog.throw_dialog(owner.chunk_data.name)
	else:
		load_new_data.emit()


func _on_load_btn_pressed() -> void:
	if unsaved_changes:
		prevented_function = _on_load_btn_pressed
		unsaved_dialog.throw_dialog(owner.chunk_data.name)
	else:
		load_dialog.throw_dialog()
		prevented_function = null


func _on_save_btn_pressed() -> void:
	if owner.chunk_data.UID == StringName():
		save_as()
	else:
		save_data.emit()
		if prevented_function:
			unsaved_changes = false
			prevented_function.call()



func _on_unsafed_dialog_save_btn_pressed() -> void:
	if owner.chunk_data.UID == StringName():
		save_as()
	else:
		save_data.emit()
		if prevented_function:
			unsaved_changes = false
			prevented_function.call()


func _on_unsafed_dialog_discard_btn_pressed() -> void:
	discard_data.emit()
	if prevented_function:
		unsaved_changes = false
		prevented_function.call()


func save_as():
	save_as_dialog.throw_dialog(owner.chunk_data.name)


func _on_save_as_dialog_save_btn_pressed(text: String) -> void:
	save_as_data.emit(text)
	if prevented_function:
		unsaved_changes = false
		prevented_function.call()


func _on_load_dialog_load_btn_pressed(selected_UID: StringName) -> void:
	load_data.emit(selected_UID)
