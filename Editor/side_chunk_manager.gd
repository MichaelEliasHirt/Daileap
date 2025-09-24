extends Control

const BTN_LEFT = preload("uid://dcwntegp1ayiv")
const BTN_RIGHT = preload("uid://xxpn1n72cild")

@onready var container: HBoxContainer = $HboxContainer
@onready var add_btn_left: TextureButton = $HboxContainer/AddBtnLeft
@onready var add_btn_right: TextureButton = $HboxContainer/AddBtnRight
@onready var h_slider: HSlider = $HSlider

signal update_chunks(chunks_left:int,chunks_right:int,exit_chunk:int)
signal update_exit(exit_chunk:int)

var chunks_left: int
var chunks_right: int

var chunk_btns_left: Array[TextureButton]
var chunk_btns_right: Array[TextureButton]

var exit_chunk: int 

var exit_chunk_beginning: int
var exit_chunk_end: int

func _ready() -> void:
	chunks_left = owner.chunks_left
	chunks_right = owner.chunks_right
	exit_chunk = owner.exit_chunk
	_update_btns()


func _update_btns() -> void:
	add_btn_left.visible = chunks_left < (owner.max_chunks-1)/2
	add_btn_right.visible = chunks_right < (owner.max_chunks-1)/2
	if add_btn_left.visible:
		exit_chunk_beginning = 1
	else:
		exit_chunk_beginning = 0
		
	if add_btn_right.visible:
		exit_chunk_end =  1
	else:
		exit_chunk_end = 0
			
	if chunks_left > chunk_btns_left.size():
		var new_btn = BTN_LEFT.instantiate() as TextureButton
		container.add_child(new_btn)
		container.move_child(new_btn,1)
		chunk_btns_left.append(new_btn)
		new_btn.pressed.connect(_on_remove_btn_left)
		
	elif chunks_left < chunk_btns_left.size():
		chunk_btns_left.pop_back().queue_free()

	if chunks_right > chunk_btns_right.size():
		var new_btn = BTN_RIGHT.instantiate() as TextureButton
		container.add_child(new_btn)
		container.move_child(new_btn,-2)
		chunk_btns_right.append(new_btn)
		new_btn.pressed.connect(_on_remove_btn_right)
	elif chunks_right < chunk_btns_right.size():
		chunk_btns_right.pop_back().queue_free()
		
	h_slider.value = exit_chunk + exit_chunk_beginning
	_update_slider(exit_chunk)
	
	update_chunks.emit(chunks_left,chunks_right,exit_chunk)


func _update_slider(_value):
	h_slider.value = clamp(h_slider.value,exit_chunk_beginning,chunks_left + chunks_right + exit_chunk_beginning)
	h_slider.max_value = chunks_left + chunks_right + exit_chunk_beginning + exit_chunk_end
	exit_chunk = int(h_slider.value - exit_chunk_beginning)
	if not _value is int:
		update_exit.emit(exit_chunk)


func _on_remove_btn_left() -> void:
	exit_chunk -= 1
	chunks_left -= 1
	_update_btns()


func _on_remove_btn_right() -> void:
	chunks_right -= 1
	_update_btns()


func _on_add_btn_left_pressed() -> void:
	exit_chunk += 1
	chunks_left += 1
	_update_btns()


func _on_add_btn_right_pressed() -> void:
	chunks_right += 1
	_update_btns()


func _on_settings_settings_updated(settings) -> void:
	chunks_left = settings.chunks_left
	chunks_right = settings.chunks_right
	exit_chunk = settings.exit_chunk
	for x in range(3):
		_update_btns()
