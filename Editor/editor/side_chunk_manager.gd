extends Control

const BTN_LEFT = preload("uid://dcwntegp1ayiv")
const BTN_RIGHT = preload("uid://xxpn1n72cild")

@onready var spacer: Control = $HboxContainer/Spacer
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

var old_slider_value: int


func _update_btns() -> void:
	add_btn_left.visible = chunks_left < (owner.max_side_chunks-1)/2
	add_btn_right.visible = chunks_right < (owner.max_side_chunks-1)/2

		
	if add_btn_right.visible:
		exit_chunk_end =  1
	else:
		exit_chunk_end = 0
			
	if chunks_left > chunk_btns_left.size():
		var new_btn = BTN_LEFT.instantiate() as TextureButton
		container.add_child(new_btn)
		container.move_child(new_btn,2)
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
	
	


func _update_slider(_value):
	
	@warning_ignore("narrowing_conversion")
	var value := clampi(h_slider.value,exit_chunk_beginning,chunks_left + chunks_right + exit_chunk_beginning)
	h_slider.value = value
	exit_chunk = int(h_slider.value - exit_chunk_beginning)
	
	if value == old_slider_value:
		return
	old_slider_value = value
	if not _value is int:
		update_exit.emit(exit_chunk)


func _on_remove_btn_left() -> void:
	exit_chunk -= 1
	chunks_left -= 1
	check_spacer()
	_update_btns()
	update_chunks.emit(chunks_left,chunks_right,exit_chunk)


func _on_remove_btn_right() -> void:
	chunks_right -= 1
	_update_btns()
	update_chunks.emit(chunks_left,chunks_right,exit_chunk)


func _on_add_btn_left_pressed() -> void:
	exit_chunk += 1
	chunks_left += 1
	check_spacer()
	_update_btns()
	update_chunks.emit(chunks_left,chunks_right,exit_chunk)


func _on_add_btn_right_pressed() -> void:
	chunks_right += 1
	_update_btns()
	update_chunks.emit(chunks_left,chunks_right,exit_chunk)


func update(new_chunks_left: int, new_chunks_right: int, new_exit_chunk: int) -> void:
	chunks_left = new_chunks_left
	chunks_right = new_chunks_right
	exit_chunk = new_exit_chunk
	check_spacer()
	for x in range(3):
		_update_btns()

func check_spacer():
	if chunks_left == 0:
		exit_chunk_beginning = 2
	elif chunks_left == 1:
		exit_chunk_beginning = 1
	else:
		exit_chunk_beginning = 0
	spacer.visible = chunks_left < 1
