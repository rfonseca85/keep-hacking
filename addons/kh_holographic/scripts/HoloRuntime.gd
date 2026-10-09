extends Node
## Holographic Network presentation only. No inputs, no GameState mutations.

var game: Node2D
var _world_fx: Node2D
var _ui_layer: CanvasLayer

func _ready() -> void:
    if not is_instance_valid(game):
        push_warning("KH Holographic: no Main node bound")
        return

    var world := game.get_node_or_null("World")
    if world == null:
        push_warning("KH Holographic: expected $World in Main")
        return

    # Drawn after World background but BEFORE sibling $NodesLayer, so target
    # hitboxes, server sprites and gameplay visuals remain clear.
    _world_fx = preload("res://addons/kh_holographic/scripts/HoloNetwork.gd").new()
    _world_fx.name = "HoloNetworkFX"
    _world_fx.set("game", game)
    world.add_child(_world_fx)

    # High-level HUD decoration only. No clickable components are created.
    _ui_layer = CanvasLayer.new()
    _ui_layer.name = "HoloHUDLayer"
    _ui_layer.layer = 2
    game.add_child(_ui_layer)
    var telemetry: Control = preload("res://addons/kh_holographic/scripts/HoloTelemetry.gd").new()
    telemetry.set("game", game)
    telemetry.name = "TelemetryPanel"
    _ui_layer.add_child(telemetry)

    var styler = preload("res://addons/kh_holographic/scripts/HoloStyler.gd").new()
    styler.apply_to(game)
