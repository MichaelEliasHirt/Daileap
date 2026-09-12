extends Window

signal save_btn_pressed(text: String)
signal cancel_btn_pressed

@onready var line_edit: LineEdit = $MarginContainer/VBoxContainer/LineEdit
@onready var feedback_label: Label = $MarginContainer/VBoxContainer/FeedbackLabel


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter"):
		_on_save_btn_pressed()

func throw_dialog(filename):
	line_edit.text = ""
	line_edit.placeholder_text = filename
	show()
	%GreyOut.show()


func _on_save_btn_pressed() -> void:
	var save_name = line_edit.text
	
	if save_name.length() < 4:
		feedback_label.text = "Filename is too short"
	
	else:
		hide()
		%GreyOut.hide()
		save_btn_pressed.emit(save_name)


func _on_cancel_btn_pressed() -> void:
	hide()
	%GreyOut.hide()
	cancel_btn_pressed.emit()


func _on_line_edit_text_changed(_new_text: String) -> void:
	feedback_label.text = ""
