extends Node2D

## Backdrop matches the fixed design frame centered on the main camera.

const DESIGN_VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const DESIGN_VIEWPORT_CENTER := Vector2(640.0, 360.0)

@onready var _backdrop: TextureRect = $Backdrop
@onready var _scrim: ColorRect = $Scrim


func _ready() -> void:
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	sync_to_camera()
	get_viewport().size_changed.connect(sync_to_camera)


func sync_to_camera() -> void:
	var cam := get_viewport().get_camera_2d()
	var center: Vector2 = DESIGN_VIEWPORT_CENTER
	if cam != null:
		center = cam.get_screen_center_position()
	var top_left: Vector2 = center - DESIGN_VIEWPORT_SIZE * 0.5
	_backdrop.position = top_left
	_backdrop.size = DESIGN_VIEWPORT_SIZE
	_scrim.position = top_left
	_scrim.size = DESIGN_VIEWPORT_SIZE
