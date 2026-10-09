extends Node2D

## Keeps Main gameplay backdrop + scrim matched to the camera view when the window resizes.

@onready var _backdrop: TextureRect = $Backdrop
@onready var _scrim: ColorRect = $Scrim


func _ready() -> void:
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	_sync_to_camera()
	get_viewport().size_changed.connect(_sync_to_camera)


func _sync_to_camera() -> void:
	var size := get_viewport().get_visible_rect().size
	var cam := get_viewport().get_camera_2d()
	var top_left := Vector2.ZERO
	if cam != null:
		top_left = cam.get_screen_center_position() - size * 0.5
	_backdrop.position = top_left
	_backdrop.size = size
	_scrim.position = top_left
	_scrim.size = size
