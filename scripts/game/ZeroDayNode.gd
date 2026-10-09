extends ServerNode
class_name ZeroDayNode

## Grid centerpiece: hack once to trigger a timed burst that spreads to all nodes.

signal activation_requested(node: ZeroDayNode)

var on_cooldown: bool = false
var bursting: bool = false


func _ready() -> void:
	super._ready()
	device_variant = "quantum_core"
	device_tex = KHArt.tex("props", "quantum_core")
	col_border_locked = Color8(200, 80, 255)
	col_border_ready = Color8(255, 120, 255)
	col_bar_fill = Color8(216, 110, 255)


func reset_locked(_vulnerable: bool = false, _honeypot: bool = false) -> void:
	if bursting:
		return
	state = State.LOCKED
	progress = 0.0
	is_vulnerable = false
	is_honeypot = false
	honeypot_t = 0.0
	queue_redraw()


func set_cooldown(active: bool) -> void:
	on_cooldown = active
	if active:
		state = State.LOCKED
		progress = 0.0
	queue_redraw()


func begin_burst() -> void:
	bursting = true
	state = State.READY
	progress = 1.0
	queue_redraw()


func end_burst() -> void:
	bursting = false
	reset_locked(false, false)


func add_progress(amount: float) -> bool:
	if on_cooldown or bursting or state != State.LOCKED:
		return false
	progress = min(1.0, progress + amount)
	queue_redraw()
	if progress >= 1.0:
		state = State.READY
		activation_requested.emit(self)
		return true
	return false


func _draw() -> void:
	super._draw()
	var label_col := Color8(216, 110, 255) if not on_cooldown else Color8(90, 70, 110)
	draw_string(ThemeDB.fallback_font, Vector2(-SIZE.x / 2.0, SIZE.y / 2.0 + 22), "0-DAY", HORIZONTAL_ALIGNMENT_CENTER, int(SIZE.x), 9, label_col)
	if on_cooldown:
		draw_arc(Vector2.ZERO, 28, -PI / 2.0, -PI / 2.0 + TAU * 0.75, 24, Color8(120, 60, 160, 0.5), 2.0)
