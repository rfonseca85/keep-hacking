extends RefCounted
class_name KHArt

const ROOT := "res://assets/game/"

static var _cache: Dictionary = {}

static func tex(group: String, name: String) -> Texture2D:
	var key := group + "/" + name
	if _cache.has(key):
		return _cache[key]
	var path := "%s%s/%s.png" % [ROOT, group, name]
	if not ResourceLoader.exists(path):
		push_warning("Missing Keep Hacking asset: " + path)
		return null
	var t := load(path) as Texture2D
	_cache[key] = t
	return t

static func fx_frames(prefix: String, count: int, fps: float = 16.0) -> SpriteFrames:
	var cache_key := "fx_frames/" + prefix
	if _cache.has(cache_key):
		return _cache[cache_key]
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", fps)
	frames.set_animation_loop(&"run", false)
	for i in range(count):
		var path := "%sfx/%s_%02d.png" % [ROOT, prefix, i]
		if not ResourceLoader.exists(path):
			break
		var img := tex("fx", "%s_%02d" % [prefix, i])
		if img != null:
			frames.add_frame(&"run", img)
	_cache[cache_key] = frames
	return frames

const DEVICE_VARIANTS := [
	"terminal", "server_rack", "router", "database",
	"processor", "server_cluster", "mainframe", "data_cache",
	"access_port", "code_console", "secure_node",
]

static func pick_device_variant(visual_seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed
	return DEVICE_VARIANTS[rng.randi_range(0, DEVICE_VARIANTS.size() - 1)]
