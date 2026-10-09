@tool
extends TextureRect

## Fills the parent screen Control; texture stretches with the viewport.


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_LINEAR
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	_apply_full_rect()
	if not Engine.is_editor_hint():
		get_viewport().size_changed.connect(_apply_full_rect)


func _apply_full_rect() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	set_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_KEEP_SIZE)
