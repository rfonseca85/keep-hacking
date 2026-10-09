extends Node2D
class_name TierIcon

@export var accent_color: Color = Color8(0, 229, 255)
@export var prop_name: String = "server_cluster"

var _tex: Texture2D
var _t: float = 0.0

func _ready() -> void:
	_tex = KHArt.tex("props", prop_name)
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var glow := (sin(_t * 2.2) + 1.0) * 0.5
	var plate := Rect2(-46, -46, 92, 92)
	draw_rect(plate, Color8(6, 8, 13), true)
	draw_rect(plate, Color(accent_color.r, accent_color.g, accent_color.b, 0.35 + glow * 0.45), false, 2.0)
	if _tex:
		draw_texture_rect(_tex, Rect2(-36, -36, 72, 72), false)
	else:
		draw_rect(Rect2(-30, -30, 60, 60), accent_color, false, 2.0)
	for i in range(3):
		var on := fmod(_t * 1.4 + i * 0.5, 2.0) < 1.0
		var c := accent_color if on else Color(accent_color.r, accent_color.g, accent_color.b, 0.18)
		draw_rect(Rect2(-40 + i * 10, 38, 6, 3), c, true)
