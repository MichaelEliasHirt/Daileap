extends Window

@onready var item_list: ItemList = $MarginContainer/VBoxContainer/ItemList
@onready var load_btn: Button = $MarginContainer/VBoxContainer/HBoxContainer/LoadBtn

signal load_btn_pressed(selected_UID:StringName)
signal cancel_btn_pressed

func throw_dialog():
	update()
	%GreyOut.show()
	show()
	item_list.deselect_all()
	load_btn.disabled = true


func update():
	item_list.clear()
	owner.load_files()
	for chunk in owner.all_chunks:
		var idx = item_list.add_item(chunk.name)
		item_list.set_item_metadata(idx,chunk.UID)


func _on_item_list_item_selected(_index: int) -> void:
	load_btn.disabled = false


func _on_load_btn_pressed() -> void:
	hide()
	%GreyOut.hide()
	load_btn_pressed.emit(item_list.get_item_metadata(item_list.get_selected_items()[0]))


func _on_cancel_btn_pressed() -> void:
	hide()
	%GreyOut.hide()
	cancel_btn_pressed.emit()


func _on_item_list_item_activated(index: int) -> void:
	hide()
	%GreyOut.hide()
	load_btn_pressed.emit(item_list.get_item_metadata(index))
