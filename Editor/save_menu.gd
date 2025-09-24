extends Control

@export_dir var directory_path: String
@export var default_new_res: LevelChunkRes

@onready var name_edit: LineEdit = $NameEdit
@onready var load_dialog: FileDialog = $LoadDialog
@onready var error_label: Label = $ErrorLabel

signal request_save_data
signal name_changed(name:String)
signal new_chunk_loaded(data:LevelChunkRes)

signal save_status_changed(saved:bool)

var all_chunks: Array[LevelChunkRes]

var saved := false
var save_buffer := false

func _ready() -> void:
	_update()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save"):
		_save()


func _on_load_btn_pressed() -> void:
	load_dialog.show()


func _on_file_dialog_file_selected(path: String) -> void:
	_load(path)


func _check_line_edit() -> void:
	var new_text = name_edit.text.validate_filename().remove_chars(r"!@#$%^&*()+{}|:<>?-'=[]\;,./~").remove_chars(r'"').to_pascal_case()
	name_edit.text = new_text
	name_changed.emit(new_text)


func _update():
	all_chunks.clear()
	for subpath in ResourceLoader.list_directory(directory_path):
		var res = ResourceLoader.load(directory_path + "/" + subpath, "LevelChunkRes")
		all_chunks.append(res)


func display_error(error:String):
	error_label.text = error
	error_label.modulate.a = 1
	var tween = get_tree().create_tween()
	tween.tween_interval(3)
	tween.tween_property(error_label,"modulate:a",0,1)
	await tween.finished
	tween.kill()


func _new():
	var res = default_new_res.duplicate(true)
	res.UID = get_random_UID()
	display_error("Succesfully created a new Level Chunk")
	new_chunk_loaded.emit(res)
	saved = false
	save_status_changed.emit(false)


func _load(path: String):
	var res = ResourceLoader.load(path, "LevelChunkRes",ResourceLoader.CACHE_MODE_IGNORE)
	if res:
		display_error("Succesfully loaded " + path.get_file())
		saved = true
		_save_buffer()
		new_chunk_loaded.emit(res)



func _save():
	request_save_data.emit()


func _on_editor_send_save_data(data: LevelChunkRes) -> void:
	var chunk_name = data.name
	if chunk_name.is_empty():
		display_error("Name can not be emtpy")
		return
	if data.height <= 0:
		display_error("Height can not be Zero")
		return
	if all_chunks.any(func(x): return x.name == chunk_name):
		for x in all_chunks.filter(func(x): return x.name == chunk_name):
			print(x.UID,data.UID)
			if x.UID == data.UID:
				var error = ResourceSaver.save(data,directory_path + "/" + chunk_name + ".tres")
				if error:
					display_error(error_string(error))
				else:
					display_error(chunk_name + ".tres updated")
					saved = true
					_save_buffer()
				return
		display_error("Name already exits")
	else:
		data.UID = get_random_UID()
		var error = ResourceSaver.save(data,directory_path + "/" + chunk_name + ".tres")
		if error:
			display_error(error_string(error))
		else:
			display_error("Level Chunks saved succesfully as '%s'" % (chunk_name + ".tres"))
			saved = true
			_save_buffer()
			all_chunks.append(data)


func _save_buffer():
	save_status_changed.emit(true)
	save_buffer = true
	#await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	save_buffer = false

func _something_changed():
	if not save_buffer:
		if saved:
			save_status_changed.emit(false)
		saved = false


func _on_editor_data_updated(data: LevelChunkRes) -> void:
	name_edit.text = data.name


func get_random_UID():
	randomize()
	var string: String = ""
	for x in range(16):
		string += str(randi_range(0,9))
	return string
