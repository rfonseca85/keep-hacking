extends RefCounted
class_name VisualFX

const MAX_ACTIVE := 20
static var _active: int = 0

static func play(parent: Node2D, world_pos: Vector2, fx_name: String,
		count: int, fps: float = 18.0, tint: Color = Color.WHITE,
		scale: float = 1.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if _active >= MAX_ACTIVE:
		return
	var frames := KHArt.fx_frames(fx_name, count, fps)
	if frames == null or frames.get_frame_count(&"run") == 0:
		return
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = tint
	sprite.scale = Vector2(scale, scale)
	sprite.z_index = 15
	parent.add_child(sprite)
	sprite.position = world_pos
	_active += 1
	sprite.animation_finished.connect(func():
		_active -= 1
		if is_instance_valid(sprite):
			sprite.queue_free()
	, Object.CONNECT_ONE_SHOT)
	sprite.play(&"run")
