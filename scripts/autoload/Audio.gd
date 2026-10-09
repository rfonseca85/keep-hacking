extends Node

const SR := 22050
var players: Array[AudioStreamPlayer] = []
var next_player: int = 0
var ambient_player: AudioStreamPlayer

func _ready() -> void:
	for i in range(6):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.volume_db = -22.0
	add_child(ambient_player)

func _get_player() -> AudioStreamPlayer:
	var p := players[next_player]
	next_player = (next_player + 1) % players.size()
	return p

func _make_tone(segments: Array) -> AudioStreamWAV:
	var total_frames := 0
	for seg in segments:
		total_frames += int(seg["dur"] * SR)
	var data := PackedByteArray()
	data.resize(total_frames * 2)
	var idx := 0
	for seg in segments:
		var freq: float = seg["freq"]
		var dur: float = seg["dur"]
		var vol: float = seg.get("vol", 0.3)
		var wave: String = seg.get("wave", "sine")
		var frames := int(dur * SR)
		for f in range(frames):
			var t := float(f) / SR
			var env := 1.0
			var fade: float = min(frames * 0.15, 200.0)
			if f < fade:
				env = f / fade
			elif f > frames - fade:
				env = (frames - f) / fade
			var s: float
			if wave == "square":
				s = 1.0 if sin(TAU * freq * t) >= 0 else -1.0
			else:
				s = sin(TAU * freq * t)
			var sample := int(clamp(s * vol * env, -1.0, 1.0) * 32767)
			data.encode_s16(idx * 2, sample)
			idx += 1
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SR
	stream.stereo = false
	stream.data = data
	return stream

var _cache: Dictionary = {}

func _cached(key: String, segments: Array) -> AudioStreamWAV:
	if not _cache.has(key):
		_cache[key] = _make_tone(segments)
	return _cache[key]

func play_tick() -> void:
	var s := _cached("tick", [{"freq": 900, "dur": 0.03, "vol": 0.12}])
	var p := _get_player()
	p.stream = s
	p.pitch_scale = randf_range(0.95, 1.1)
	p.play()

func play_exfiltrate() -> void:
	var s := _cached("exfil", [
		{"freq": 660, "dur": 0.06, "vol": 0.25},
		{"freq": 990, "dur": 0.09, "vol": 0.25},
	])
	var p := _get_player()
	p.stream = s
	p.pitch_scale = 1.0
	p.play()

func play_exploit() -> void:
	var s := _cached("exploit", [
		{"freq": 523, "dur": 0.05, "vol": 0.25},
		{"freq": 784, "dur": 0.05, "vol": 0.25},
		{"freq": 1047, "dur": 0.1, "vol": 0.25},
	])
	var p := _get_player()
	p.stream = s
	p.play()

func play_upgrade() -> void:
	var s := _cached("upgrade", [
		{"freq": 440, "dur": 0.05, "vol": 0.22, "wave": "square"},
		{"freq": 660, "dur": 0.1, "vol": 0.22, "wave": "square"},
	])
	var p := _get_player()
	p.stream = s
	p.play()

func play_breach() -> void:
	var s := _cached("breach", [
		{"freq": 220, "dur": 0.12, "vol": 0.3, "wave": "square"},
		{"freq": 330, "dur": 0.12, "vol": 0.3, "wave": "square"},
		{"freq": 440, "dur": 0.18, "vol": 0.3, "wave": "square"},
	])
	var p := _get_player()
	p.stream = s
	p.play()

func play_denied() -> void:
	var s := _cached("denied", [{"freq": 160, "dur": 0.12, "vol": 0.2, "wave": "square"}])
	var p := _get_player()
	p.stream = s
	p.play()

func _build_ambient() -> AudioStreamWAV:
	var dur := 4.0
	var frames := int(dur * SR)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for f in range(frames):
		var t := float(f) / SR
		var s := 0.0
		s += sin(TAU * 55.0 * t) * 0.5
		s += sin(TAU * 55.0 * 1.003 * t) * 0.5
		s += sin(TAU * 110.0 * t) * 0.15
		s += (rng.randf() * 2.0 - 1.0) * 0.015
		var loop_fade := 1.0
		var fade_frames := int(0.3 * SR)
		if f < fade_frames:
			loop_fade = float(f) / fade_frames
		elif f > frames - fade_frames:
			loop_fade = float(frames - f) / fade_frames
		var sample := int(clamp(s * 0.5 * loop_fade, -1.0, 1.0) * 32767)
		data.encode_s16(f * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SR
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream

func play_ambient() -> void:
	if ambient_player.playing:
		return
	if not _cache.has("ambient"):
		_cache["ambient"] = _build_ambient()
	ambient_player.stream = _cache["ambient"]
	ambient_player.play()

func stop_ambient() -> void:
	ambient_player.stop()
