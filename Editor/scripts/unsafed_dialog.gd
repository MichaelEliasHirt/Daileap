extends AcceptDialog

signal save_btn_pressed
signal discard_btn_pressed
signal cancel_btn_pressed


func throw_dialog(filename):
	dialog_text = """Current file [{0}] is not saved
Do you want to safe it?""".format([filename])
	show()
	%GreyOut.show()

func _ready() -> void:
	get_ok_button().pressed.connect(_save_btn_pressed)
	add_button("Discard",true).pressed.connect(_discard_btn_pressed)
	add_button("Cancel",true).pressed.connect(_cancel_btn_pressed)

func _save_btn_pressed():
	hide()
	%GreyOut.hide()
	save_btn_pressed.emit()
	
func _discard_btn_pressed():
	hide()
	%GreyOut.hide()
	discard_btn_pressed.emit()
	
func _cancel_btn_pressed():
	hide()
	%GreyOut.hide()
	cancel_btn_pressed.emit()
