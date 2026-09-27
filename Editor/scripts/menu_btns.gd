extends HBoxContainer

@onready var valid_btn: TextureButton = $ValidBtn
@onready var save_btn: TextureButton = $SaveBtn
@onready var settings_btn: TextureButton = $SettingsBtn

@export var SaveBtnUnsafed: Array[Texture2D]
@export var SaveBtnSafed: Array[Texture2D]

func _on_save_menu_save_status_changed(saved: bool) -> void:
	if saved:
		save_btn.texture_normal = SaveBtnSafed[0]
		save_btn.texture_pressed = SaveBtnSafed[1]
		save_btn.texture_hover = SaveBtnSafed[2]
	else:
		save_btn.texture_normal = SaveBtnUnsafed[0]
		save_btn.texture_pressed = SaveBtnUnsafed[1]
		save_btn.texture_hover = SaveBtnUnsafed[2]
