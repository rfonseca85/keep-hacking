extends Node2D
class_name ServerNode

enum State { LOCKED, READY }

const SIZE := Vector2(52, 52)
const COL_BG := Color8(18, 22, 32)
const COL_BORDER_LOCKED := Color8(0, 194, 255)
const COL_BORDER_VULN := Color8(255, 46, 146)
const COL_BORDER_READY := Color8(57, 255, 106)
const COL_BORDER_HONEYPOT := Color8(255, 60, 60)
const COL_BAR_BG := Color8(10, 12, 18)
const COL_BAR_FILL := Color8(0, 229, 255)
const COL_TEXT := Color8(220, 240, 255)

const HONEYPOT_LIFETIME := 2.6

var state: int = State.LOCKED
var progress: float = 0.0
var is_vulnerable: bool = false
var is_honeypot: bool = false
var honeypot_t: float = 0.0
var pulse_t: float = 0.0
var led_phase: float = 0.0
var device_variant: String = "terminal"
var device_tex: Texture2D
var lock_tex: Texture2D
var unlock_tex: Texture2D

signal honeypot_expired(node)

func _ready() -> void:
	set_process(true)
	var visual_seed := int(position.x) * 10007 + int(position.y)
	device_variant = KHArt.pick_device_variant(visual_seed)
	device_tex = KHArt.tex("props", device_variant)
	lock_tex = KHArt.tex("icons", "lock")
	unlock_tex = KHArt.tex("icons", "unlock")
	var phase_rng := RandomNumberGenerator.new()
	phase_rng.seed = visual_seed + 1
	led_phase = phase_rng.randf_range(0.0, TAU)

func reset_locked(vulnerable: bool, honeypot: bool = false) -> void:
	state = State.LOCKED
	progress = 0.0
	is_vulnerable = vulnerable
	is_honeypot = honeypot
	honeypot_t = 0.0
	queue_redraw()

func add_progress(amount: float) -> bool:
	if state != State.LOCKED:
		return false
	progress = min(1.0, progress + amount)
	queue_redraw()
	if progress >= 1.0:
		state = State.READY
		honeypot_t = 0.0
		return true
	return false

func _process(delta: float) -> void:
	if state == State.READY:
		pulse_t += delta
		queue_redraw()
		if is_honeypot:
			honeypot_t += delta
			if honeypot_t >= HONEYPOT_LIFETIME:
				honeypot_expired.emit(self)
	else:
		queue_redraw()

func _draw() -> void:
	var r := Rect2(-SIZE / 2.0, SIZE)
	draw_rect(r, COL_BG, true)

	var border_col := COL_BORDER_LOCKED
	if state == State.READY:
		if is_honeypot:
			var pulse := (sin(pulse_t * 14.0) + 1.0) * 0.5
			border_col = COL_BORDER_HONEYPOT.lerp(Color8(255,255,255), pulse * 0.3)
		else:
			var pulse := (sin(pulse_t * 6.0) + 1.0) * 0.5
			border_col = COL_BORDER_READY.lerp(Color8(255,255,255), pulse * 0.4)
	elif is_vulnerable:
		border_col = COL_BORDER_VULN

	_draw_device(border_col)
	draw_rect(r, border_col, false, 2.0)

	if state == State.LOCKED:
		var bar_r := Rect2(-SIZE.x / 2.0 + 4, SIZE.y / 2.0 - 10, SIZE.x - 8, 5)
		draw_rect(bar_r, COL_BAR_BG, true)
		var fill_r := Rect2(bar_r.position, Vector2(bar_r.size.x * progress, bar_r.size.y))
		draw_rect(fill_r, COL_BAR_FILL, true)
		_draw_status_icon(lock_tex, border_col)
	else:
		_draw_status_icon(unlock_tex, border_col)
		if is_honeypot:
			var remain := 1.0 - (honeypot_t / HONEYPOT_LIFETIME)
			draw_arc(Vector2.ZERO, 24, -PI / 2.0, -PI / 2.0 + TAU * remain, 20, COL_BORDER_HONEYPOT, 2.0)

	_draw_leds(border_col)

	if DevMode.show_debug_info:
		var state_name := "LOCKED" if state == State.LOCKED else "READY"
		var info := "%s %d%%" % [state_name, int(progress * 100)]
		draw_string(ThemeDB.fallback_font, Vector2(-SIZE.x / 2.0, -SIZE.y / 2.0 - 6), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(255, 220, 120))
		draw_string(ThemeDB.fallback_font, Vector2(-SIZE.x / 2.0, SIZE.y / 2.0 + 14), device_variant, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(140, 200, 255))

func _draw_device(tint: Color) -> void:
	var scale_pulse := 1.0
	if state == State.READY and not is_honeypot:
		scale_pulse = 1.0 + sin(pulse_t * 5.0) * 0.045
	var inner := SIZE - Vector2(10, 10)
	var draw_size := inner * scale_pulse
	var rect := Rect2(-draw_size / 2.0, draw_size)
	if device_tex:
		var modulate_col := Color(1, 1, 1, 1).lerp(tint, 0.18)
		draw_texture_rect(device_tex, rect, false, modulate_col)
	else:
		draw_rect(rect, Color8(30, 38, 52), true)

func _draw_status_icon(icon: Texture2D, col: Color) -> void:
	if icon == null:
		return
	var icon_size := Vector2(16, 16)
	var pos := Vector2(SIZE.x / 2.0 - icon_size.x - 2, -SIZE.y / 2.0 + 2)
	draw_texture_rect(icon, Rect2(pos, icon_size), false, col)

func _draw_leds(col: Color) -> void:
	var t := pulse_t + led_phase
	for i in range(2):
		var on := fmod(t * 0.6 + i * 0.9, 2.0) < 1.0
		var c := col if on else Color8(30, 36, 44)
		draw_rect(Rect2(-SIZE.x / 2.0 + 4 + i * 8, -SIZE.y / 2.0 + 4, 5, 3), c, true)
