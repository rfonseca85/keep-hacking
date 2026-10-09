extends Panel
class_name TierCard

## Tier index 0–3; bound to GameState.TIERS. Edit layout and default textures in the scene.
@export var tier_index: int = 0
@export var emblem_prop: String = "terminal_desk"

@export_group("Style")
@export var card_texture: Texture2D
@export var backdrop_color: Color = Color8(4, 5, 8)

@onready var header: Panel = $Header
@onready var decor: Node2D = $Decor
@onready var name_label: Label = $NameLabel
@onready var emblem: Node2D = $Emblem
@onready var mult_label: Label = $MultLabel
@onready var trait_label: Label = $TraitLabel
@onready var lock_label: Label = $LockLabel
@onready var cost_label: Label = $CostLabel
@onready var action_button: Button = $ActionButton

signal breach_pressed(tier_index: int)
signal unlock_pressed(tier_index: int)

func _ready() -> void:
	if card_texture == null:
		card_texture = KHArt.tex("ui", "selection_card")
	decor.draw.connect(_draw_card_decor)
	emblem.prop_name = emblem_prop
	action_button.pressed.connect(_on_action_pressed)
	refresh()

func refresh() -> void:
	var tier: Dictionary = GameState.TIERS[tier_index]
	var tier_color: Color = tier["color"]
	name_label.text = "> %s" % str(tier["name"])
	name_label.add_theme_color_override("font_color", tier_color)
	emblem.accent_color = tier_color

	if card_texture:
		var csb := StyleBoxTexture.new()
		csb.texture = card_texture
		csb.set_texture_margin_all(10)
		csb.modulate_color = Color(1, 1, 1, 1).lerp(tier_color, 0.22)
		add_theme_stylebox_override("panel", csb)
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color8(10, 12, 18)
		sb.border_color = tier_color
		sb.set_border_width_all(2)
		add_theme_stylebox_override("panel", sb)

	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(tier_color.r, tier_color.g, tier_color.b, 0.14)
	hsb.border_color = tier_color
	hsb.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", hsb)

	var unlocked: bool = GameState.unlocked_tiers[tier_index]
	mult_label.visible = unlocked
	trait_label.visible = unlocked
	lock_label.visible = not unlocked
	cost_label.visible = not unlocked

	if unlocked:
		mult_label.text = "node value  x%.1f" % tier["node_mult"]
		var trait_text: String = tier.get("trait_name", "")
		trait_label.text = trait_text
		trait_label.visible = trait_text != ""
		trait_label.add_theme_color_override("font_color", tier_color)
		action_button.text = "BREACH ▸"
		_style_button(action_button, tier_color)
	else:
		lock_label.text = "[ LOCKED ]"
		cost_label.text = "unlock: %d◈ credits" % tier["unlock_cost"]
		var teaser: String = tier.get("trait_name", "")
		trait_label.text = teaser
		trait_label.add_theme_color_override("font_color", Color8(110, 120, 135))
		trait_label.visible = teaser != ""
		action_button.text = "UNLOCK"
		_style_button(action_button, Color8(110, 120, 135))

	decor.queue_redraw()

func _on_action_pressed() -> void:
	if GameState.unlocked_tiers[tier_index]:
		breach_pressed.emit(tier_index)
	else:
		unlock_pressed.emit(tier_index)

func _style_button(btn: Button, border: Color) -> void:
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = backdrop_color
	bsb.border_color = border
	bsb.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", bsb)
	btn.add_theme_color_override("font_color", border)

func _draw_card_decor() -> void:
	var tier: Dictionary = GameState.TIERS[tier_index]
	var col: Color = tier["color"]
	var dim := Color(col.r, col.g, col.b, 0.14)
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + tier_index
	var panel_w := size.x
	for i in range(10):
		var x: float = rng.randf_range(10, panel_w - 10)
		var y: float = rng.randf_range(60, 430)
		if y > 230 and y < 400:
			continue
		var w: float = rng.randf_range(10, 36)
		decor.draw_rect(Rect2(x, y, w, 2), dim, true)
		decor.draw_circle(Vector2(x, y), 1.6, dim)
	for i in range(5):
		var cx: float = rng.randf_range(20, panel_w - 20)
		var cy: float = rng.randf_range(300, 395)
		decor.draw_rect(Rect2(cx, cy, 14, 18), Color(col.r, col.g, col.b, 0.1), true)
		decor.draw_rect(Rect2(cx, cy, 14, 18), dim, false, 1.0)
