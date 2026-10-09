extends Control
class_name SkillNodeCard

## Edit layout, textures, and copy in the scene. Gameplay stats sync from these exports at run time.
@export var skill_id: String = "speed1"
@export var display_name: String = "SKILL"
@export var icon_key: String = "bolt"
@export var base_cost: int = 18
@export var max_level: int = 5
@export_multiline var description: String = ""
@export var reveal_threshold: int = 0

@export_group("Card art (optional overrides)")
@export var card_texture_available: Texture2D
@export var card_texture_active: Texture2D
@export var card_texture_locked: Texture2D

@export_group("Colors")
@export var col_panel: Color = Color8(12, 15, 22)
@export var col_green: Color = Color8(57, 255, 106)
@export var col_cyan: Color = Color8(0, 229, 255)
@export var col_dim: Color = Color8(90, 100, 115)
@export var col_locked: Color = Color8(255, 90, 120)

@onready var header_panel: Panel = $HeaderPanel
@onready var header_dots: Node = $HeaderPanel/Dots
@onready var hit_button: Button = $HitButton
@onready var icon_node: Node2D = $Icon
@onready var name_label: Label = $NameLabel
@onready var sub_label: Label = $SubLabel

signal pressed(skill_id: String)
signal hover_changed(skill_id: String, entered: bool)

func _ready() -> void:
	add_to_group("skill_card")
	icon_node.icon_key = icon_key
	icon_node.max_level = max_level
	hit_button.pressed.connect(func(): pressed.emit(skill_id))
	hit_button.mouse_entered.connect(func(): hover_changed.emit(skill_id, true))
	hit_button.mouse_exited.connect(func(): hover_changed.emit(skill_id, false))
	if card_texture_available == null:
		card_texture_available = KHArt.tex("ui", "skill_available")
	if card_texture_active == null:
		card_texture_active = KHArt.tex("ui", "skill_active")
	if card_texture_locked == null:
		card_texture_locked = KHArt.tex("ui", "skill_locked")
	refresh()

func get_skill_snapshot() -> Dictionary:
	return {
		"id": skill_id,
		"label": display_name,
		"icon": icon_key,
		"cost": base_cost,
		"max_level": max_level,
		"desc": description,
		"reveal_threshold": reveal_threshold,
	}

func is_revealed() -> bool:
	return GameState.lifetime_credits_earned >= reveal_threshold

func state_color() -> Color:
	if not is_revealed() or max_level == 0:
		return col_locked
	var lvl: int = GameState.skill_levels.get(skill_id, 0)
	if lvl > 0:
		return col_green
	return col_cyan

func refresh() -> void:
	icon_node.set_icon_key(icon_key)
	var lvl: int = GameState.skill_levels.get(skill_id, 0)
	icon_node.level = lvl
	icon_node.max_level = max_level
	_style_header()
	if not is_revealed():
		name_label.text = "???"
		sub_label.text = "locked"
		name_label.add_theme_color_override("font_color", col_locked)
		sub_label.add_theme_color_override("font_color", Color8(140, 70, 85))
		_apply_card_style("locked")
		icon_node.accent_color = col_locked
	elif max_level == 0:
		name_label.text = display_name
		sub_label.text = "—"
		name_label.add_theme_color_override("font_color", col_dim)
		sub_label.add_theme_color_override("font_color", col_dim)
		_apply_card_style("locked")
		icon_node.accent_color = col_dim
	elif lvl >= max_level:
		name_label.text = display_name
		sub_label.text = "MAX %d/%d" % [lvl, max_level]
		name_label.add_theme_color_override("font_color", col_green)
		sub_label.add_theme_color_override("font_color", col_green)
		_apply_card_style("active")
		icon_node.accent_color = col_green
	else:
		var cost: int = int(base_cost * pow(1.5, lvl))
		name_label.text = display_name
		if GameState.credits >= cost:
			sub_label.text = "%d◈  Lv %d→%d" % [cost, lvl, lvl + 1]
			name_label.add_theme_color_override("font_color", col_cyan)
			sub_label.add_theme_color_override("font_color", col_cyan)
			_apply_card_style("available")
			icon_node.accent_color = col_cyan
		else:
			sub_label.text = "%d◈ credits" % cost
			name_label.add_theme_color_override("font_color", Color8(150, 170, 185))
			sub_label.add_theme_color_override("font_color", col_dim)
			_apply_card_style("available")
			icon_node.accent_color = col_dim
	icon_node.queue_redraw()

func _style_header() -> void:
	var col := state_color()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(col.r, col.g, col.b, 0.16)
	hsb.border_width_bottom = 1
	hsb.border_color = col
	header_panel.add_theme_stylebox_override("panel", hsb)
	for dot in header_dots.get_children():
		if dot is ColorRect:
			dot.color = Color(col.r, col.g, col.b, 0.7)

func _apply_card_style(state: String) -> void:
	var tex: Texture2D = card_texture_available
	match state:
		"active":
			tex = card_texture_active
		"locked":
			tex = card_texture_locked
	if tex:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.set_texture_margin_all(6)
		hit_button.add_theme_stylebox_override("normal", sb)
		hit_button.add_theme_stylebox_override("hover", sb)
		hit_button.add_theme_stylebox_override("pressed", sb)
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col_panel
		sb.set_border_width_all(2)
		match state:
			"active":
				sb.border_color = col_green
				sb.bg_color = Color8(10, 24, 18)
			"locked":
				sb.border_color = col_locked
				sb.bg_color = Color8(16, 10, 13)
			_:
				sb.border_color = col_cyan
				sb.bg_color = Color8(10, 18, 26)
		hit_button.add_theme_stylebox_override("normal", sb)
