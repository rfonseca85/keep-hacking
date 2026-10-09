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

signal honeypot_expired(node)

func _ready() -> void:
	set_process(true)

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
	draw_rect(r, border_col, false, 2.0)

	if state == State.LOCKED:
		_draw_lock(border_col)
		var bar_r := Rect2(-SIZE.x / 2.0 + 4, SIZE.y / 2.0 - 10, SIZE.x - 8, 5)
		draw_rect(bar_r, COL_BAR_BG, true)
		var fill_r := Rect2(bar_r.position, Vector2(bar_r.size.x * progress, bar_r.size.y))
		draw_rect(fill_r, COL_BAR_FILL, true)
	else:
		_draw_unlock(border_col)
		if is_honeypot:
			var remain := 1.0 - (honeypot_t / HONEYPOT_LIFETIME)
			draw_arc(Vector2.ZERO, 22, -PI / 2.0, -PI / 2.0 + TAU * remain, 20, COL_BORDER_HONEYPOT, 2.0)

func _draw_lock(col: Color) -> void:
	var shackle_r := 9.0
	draw_arc(Vector2(0, -6), shackle_r, PI, TAU, 16, col, 2.0)
	draw_line(Vector2(-shackle_r, -6), Vector2(-shackle_r, 2), col, 2.0)
	draw_line(Vector2(shackle_r, -6), Vector2(shackle_r, 2), col, 2.0)
	var body := Rect2(Vector2(-12, 0), Vector2(24, 16))
	draw_rect(body, col, false, 2.0)
	draw_circle(Vector2(0, 7), 2.0, col)

func _draw_unlock(col: Color) -> void:
	var shackle_r := 9.0
	draw_arc(Vector2(-4, -8), shackle_r, PI * 1.1, TAU * 0.95, 16, col, 2.0)
	draw_line(Vector2(5, -2), Vector2(5, 2), col, 2.0)
	var body := Rect2(Vector2(-12, 0), Vector2(24, 16))
	draw_rect(body, col, false, 2.0)
	for i in range(3):
		draw_line(Vector2(-7 + i * 7, 5), Vector2(-7 + i * 7, 11), col, 1.5)
