extends Node2D
class_name SkillNodeIcon

@export var icon_key: String = "bolt"
@export var icon_texture: Texture2D

var accent_color: Color = Color8(0, 229, 255)
var level: int = 0
var max_level: int = 0
var hovered: bool = false

var _tex: Texture2D

func _ready() -> void:
	reload_texture()
	queue_redraw()

func reload_texture() -> void:
	if icon_texture != null:
		_tex = icon_texture
	elif icon_key != "":
		_tex = KHArt.tex("icons", icon_key)

func set_icon_key(key: String) -> void:
	icon_key = key
	reload_texture()
	queue_redraw()

func _draw() -> void:
	var glow_r := 24.0 if hovered else 20.0
	draw_circle(Vector2.ZERO, glow_r, Color(accent_color.r, accent_color.g, accent_color.b, 0.14))
	draw_arc(Vector2.ZERO, glow_r, 0, TAU, 28, Color(accent_color.r, accent_color.g, accent_color.b, 0.5), 1.0)
	if _tex:
		var sz := 30.0 if hovered else 26.0
		draw_texture_rect(_tex, Rect2(-sz / 2.0, -sz / 2.0, sz, sz), false, accent_color)
	if max_level > 0:
		var pip_w := 10.0
		var gap := 4.0
		var total_w := max_level * pip_w + (max_level - 1) * gap
		var start_x := -total_w / 2.0
		var track := Rect2(start_x - 3, 25, total_w + 6, 10)
		draw_rect(track, Color8(8, 10, 15), true)
		draw_rect(track, Color(accent_color.r, accent_color.g, accent_color.b, 0.3), false, 1.0)
		for i in range(max_level):
			var filled := i < level
			var c := accent_color if filled else Color8(42, 48, 58)
			draw_rect(Rect2(start_x + i * (pip_w + gap), 27, pip_w, 6), c, true)
