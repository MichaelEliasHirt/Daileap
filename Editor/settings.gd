extends VBoxContainer

signal settings_changed(settings:ChunkSettings)
signal settings_updated(settings:ChunkSettings)

var height: int
var chunks_left: int
var chunks_right: int
var exit_chunk: int


func update_settings(settings:ChunkSettings):
	height = settings.height
	chunks_left = settings.chunks_left
	chunks_right = settings.chunks_right
	exit_chunk = settings.exit_chunk
	
	settings_updated.emit(settings)
	$HBoxContainer/HeightEdit.value = settings.height

func _on_height_edit_value_changed(value: float) -> void:
	height = int(value)


func _on_side_chunk_manager_update_chunks(chunks_left_: int, chunks_right_: int, exit_chunk_: int) -> void:
	chunks_left = chunks_left_
	chunks_right = chunks_right_
	exit_chunk = exit_chunk_


func _on_side_chunk_manager_update_exit(exit_chunk_: int) -> void:
	exit_chunk = exit_chunk_
	

func _on_ui_settings_closed() -> void:
	var settings = ChunkSettings.new()
	
	settings.height = height
	settings.chunks_left = chunks_left
	settings.chunks_right = chunks_right
	settings.exit_chunk = exit_chunk
	settings_changed.emit(settings)


func _on_editor_data_updated(data: LevelChunkRes) -> void:
	height = data.height
	chunks_left = data.chunks_left
	chunks_right = data.chunks_right
	exit_chunk = data.exit_chunk
	
	settings_updated.emit(data)
	$HBoxContainer/HeightEdit.value = data.height
