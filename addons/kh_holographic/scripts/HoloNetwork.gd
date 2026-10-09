extends Node2D
## Cosmetic realtime network visualization. Uses the actual ServerNode list and
## state, adds pulses and signal paths, never changes gameplay or input.

var game: Node2D
var _time: float = 0.0
var _paint_accum: float = 0.0
var _poll_accum: float = 0.0
var _known_ready: Dictionary = {}
var _hd_applied: Dictionary = {}
var _bursts: Array[Dictionary] = []

const GRID_POS: Vector2 = Vector2(160.0, 140.0)
const GRID_SIZE: Vector2 = Vector2(768.0, 448.0)
const CYAN: Color = Color(0.18, 0.91, 0.99)
const GREEN: Color = Color(0.16, 0.98, 0.64)
const RED: Color = Color(1.0, 0.25, 0.43)

var _console_tex: Texture2D = preload("res://addons/kh_holographic/art/sprites_game/command_console_hd.png")
var _tower_tex: Texture2D = preload("res://addons/kh_holographic/art/sprites_game/neon_column_hd.png")
var _cooling_tex: Texture2D = preload("res://addons/kh_holographic/art/sprites_game/cooling_fan_hd.png")

const HD_ART: Dictionary = {
    "server_rack":"server_rack_hd",
    "server_cluster":"server_cluster_hd",
    "mainframe":"server_rack_hd",
    "terminal":"retro_terminal_hd",
    "router":"router_hd",
    "database":"database_hd",
    "data_cache":"database_hd",
    "firewall":"firewall_hd",
    "firewall_gate":"firewall_hd",
    "secure_node":"firewall_hd",
    "cooling_fan":"cooling_fan_hd",
    "packet_transmitter":"signal_hub_hd",
    "relay_tower":"relay_tower_hd",
    "wifi_beacon":"router_hd",
    "bot_drone":"packet_drone_hd"
}

func _ready() -> void:
    set_process(true)
    _poll_nodes()

func _process(delta: float) -> void:
    _time += delta
    _paint_accum += delta
    _poll_accum += delta
    if _poll_accum >= 0.18:
        _poll_accum = 0.0
        _poll_nodes()
    # FPS cap for the decorative layer. Game logic keeps its normal rate.
    if _paint_accum >= 1.0 / 30.0:
        _paint_accum = 0.0
        queue_redraw()

func _nodes() -> Array[ServerNode]:
    if not is_instance_valid(game):
        return []
    var value: Variant = game.get("cells")
    if typeof(value) != TYPE_ARRAY:
        return []
    var output: Array[ServerNode] = []
    for node in value:
        if is_instance_valid(node) and node is ServerNode:
            output.append(node)
    return output

func _poll_nodes() -> void:
    var next_known: Dictionary = {}
    var next_hd: Dictionary = {}
    for n in _nodes():
        var id: int = n.get_instance_id()
        var ready: bool = int(n.state) == 1
        if _known_ready.has(id) and not bool(_known_ready[id]) and ready:
            _bursts.append({"pos": n.position, "start": _time, "red": bool(n.is_honeypot)})
        next_known[id] = ready
        if not _hd_applied.has(id):
            _set_hd_sprite(n)
        next_hd[id] = true
    _known_ready = next_known
    _hd_applied = next_hd
    var alive: Array[Dictionary] = []
    for burst in _bursts:
        if _time - float(burst["start"]) < 0.85:
            alive.append(burst)
    _bursts = alive

func _set_hd_sprite(node: ServerNode) -> void:
    # The base ServerNode already renders the sprite and handles its own logic.
    # Repointing ONLY device_tex leaves all states, interactions and collisions.
    var base_name: String = str(node.device_variant)
    if not HD_ART.has(base_name):
        return
    var filename: String = str(HD_ART[base_name])
    var tex: Texture2D = load("res://addons/kh_holographic/art/sprites_game/%s.png" % filename)
    if tex != null:
        node.device_tex = tex
        node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        node.queue_redraw()

func _draw() -> void:
    # Modular room props, *not* an image of the whole game screen.
    # They sit in otherwise unoccupied margins and softly pulse in brightness.
    var lamp: float = 0.78 + 0.15 * sin(_time*1.4)
    draw_texture_rect(_console_tex, Rect2(34, 407, 104, 104), false,
        Color(lamp,lamp,1.0,0.94))
    draw_texture_rect(_tower_tex, Rect2(931, 579, 49, 100), false,
        Color(0.85,0.91,lamp,0.87))
    draw_texture_rect(_cooling_tex, Rect2(675, 594, 82, 82), false,
        Color(lamp,0.98,1.0,0.66))
    # Frame and scanner line are purely decorative and never consume input.
    var rect := Rect2(GRID_POS - Vector2(4, 4), GRID_SIZE + Vector2(8, 8))
    draw_rect(rect, Color(0.05, 0.57, 0.75, 0.50), false, 1.0)
    var corners: Array[Vector2] = [
        GRID_POS, GRID_POS + Vector2(GRID_SIZE.x, 0),
        GRID_POS + Vector2(0, GRID_SIZE.y), GRID_POS + GRID_SIZE
    ]
    for p in corners:
        draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color(0.18, 0.99, 0.77, 0.68), false, 2.0)

    var scan_y: float = GRID_POS.y + fposmod(_time * 45.0, GRID_SIZE.y)
    draw_line(Vector2(GRID_POS.x+2.0, scan_y),
        Vector2(GRID_POS.x+GRID_SIZE.x-2.0, scan_y),
        Color(0.09,0.88,0.86,0.10), 2.0)

    # Short, sparse signal links between actual current nodes (visual only).
    var nodes: Array[ServerNode] = _nodes()
    for i in range(nodes.size()):
        var a: ServerNode = nodes[i]
        var nearest: ServerNode = null
        var best: float = 250.0
        for j in range(nodes.size()):
            if i == j:
                continue
            var b: ServerNode = nodes[j]
            var dist: float = a.position.distance_to(b.position)
            if dist >= 75.0 and dist < best:
                nearest = b
                best = dist
        if nearest == null:
            continue
        if a.get_instance_id() > nearest.get_instance_id():
            continue
        var p: Vector2 = a.position
        var q: Vector2 = nearest.position
        var a_red: bool = bool(a.is_honeypot) and int(a.state) == 1
        var color: Color = RED if a_red else CYAN
        draw_line(p, q, Color(color.r, color.g, color.b, 0.24), 1.0)
        var phase: float = fposmod(_time * 0.35 + float(i) * 0.27, 1.0)
        var point: Vector2 = p.lerp(q, phase)
        draw_circle(point, 4.5, Color(color.r,color.g,color.b,0.10))
        draw_circle(point, 1.6, Color(color.r,color.g,color.b,0.95))

    # Short celebration rings only after real LOCKED -> READY transitions.
    for burst in _bursts:
        var elapsed: float = _time - float(burst["start"])
        var alpha: float = maxf(0.0, 1.0 - elapsed / 0.85)
        var radius: float = 22.0 + elapsed * 42.0
        var base: Color = RED if bool(burst["red"]) else GREEN
        draw_arc(burst["pos"], radius, 0.0, TAU, 36,
            Color(base.r,base.g,base.b, alpha*0.9), 2.0)

    # Rail lamps softly cycle around the board edge.
    for k in range(24):
        var x: float = GRID_POS.x + 10.0 + float(k) * 31.0
        var opacity: float = 0.12 + 0.26 * (0.5 + 0.5*sin(_time*2.5+float(k)*0.4))
        draw_rect(Rect2(Vector2(x, GRID_POS.y-12.0), Vector2(9,2)), Color(0.13,0.96,0.77,opacity), true)
