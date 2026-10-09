extends Control
## Non-interactive HUD with actual node readings and resource delta log.
## The world map is static ART, but radar, bars, blips and text are LIVE draw calls.

var game: Node2D
var _clock: float = 0.0
var _paint_accum: float = 0.0
var _poll_accum: float = 0.0
var _last_credits: int = -1
var _last_exploits: int = -1
var _last_zerodays: int = -1
var _events: Array[String] = []
var _map: Texture2D = preload("res://addons/kh_holographic/art/ui/world_map_dots.png")
const CYAN: Color = Color(0.19, 0.88, 0.96)
const GREEN: Color = Color(0.25, 0.99, 0.66)
const MUTED: Color = Color(0.51, 0.68, 0.75)
const PANEL: Color = Color(0.016, 0.055, 0.10, 0.96)

func _ready() -> void:
    position = Vector2(949.0, 137.0)
    size = Vector2(308.0, 418.0)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _last_credits = GameState.credits
    _last_exploits = GameState.exploits
    _last_zerodays = GameState.zerodays
    _add_event("LINK ESTABLISHED")
    set_process(true)

func _process(delta: float) -> void:
    _clock += delta
    _poll_accum += delta
    _paint_accum += delta
    if _poll_accum > 0.18:
        _poll_accum = 0.0
        _read_resources()
    if _paint_accum >= 1.0 / 20.0:
        _paint_accum = 0.0
        queue_redraw()

func _read_resources() -> void:
    if GameState.credits > _last_credits and _last_credits >= 0:
        _add_event("+%d CREDITS" % (GameState.credits - _last_credits))
    if GameState.exploits > _last_exploits and _last_exploits >= 0:
        _add_event("+%d EXPLOIT" % (GameState.exploits - _last_exploits))
    if GameState.zerodays > _last_zerodays and _last_zerodays >= 0:
        _add_event("+%d ZERO-DAY" % (GameState.zerodays - _last_zerodays))
    _last_credits = GameState.credits
    _last_exploits = GameState.exploits
    _last_zerodays = GameState.zerodays

func _add_event(message: String) -> void:
    _events.push_front(message)
    if _events.size() > 5:
        _events.resize(5)

func _nodes() -> Array[ServerNode]:
    if not is_instance_valid(game):
        return []
    var value: Variant = game.get("cells")
    if typeof(value) != TYPE_ARRAY:
        return []
    var result: Array[ServerNode] = []
    for n in value:
        if is_instance_valid(n) and n is ServerNode:
            result.append(n)
    return result

func _label(p: Vector2, txt: String, col: Color=Color.WHITE, font_size: int=13) -> void:
    draw_string(ThemeDB.fallback_font, p, txt,
        HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

func _draw() -> void:
    var font_color: Color = Color(0.82,0.95,0.97)
    draw_rect(Rect2(0,0,308,418), PANEL, true)
    draw_rect(Rect2(0,0,308,418), Color(0.1,0.76,0.87,0.88), false, 2.0)
    draw_rect(Rect2(6,6,296,406), Color(0.11,0.24,0.34,0.7), false, 1.0)
    # Read-only decorative panel: no Control consumes mouse events.
    _label(Vector2(16,29), "NETWORK TELEMETRY", GREEN, 15)
    var beacon: float = 0.38 + 0.62*(0.5+0.5*sin(_clock*3.0))
    draw_circle(Vector2(287,24),4.0,Color(0.12,0.99,0.66,beacon))
    draw_texture_rect(_map, Rect2(18,42,272,112), false)
    draw_rect(Rect2(18,42,272,112), Color(0.16,0.68,0.76,0.55), false, 1.0)
    # Radar sweep and independently pulsing connection dots.
    var pivot: Vector2 = Vector2(152,98)
    var a: float = _clock * 0.9
    var end: Vector2 = pivot + Vector2(cos(a),sin(a)) * 49.0
    draw_line(pivot,end,Color(0.19,1.0,0.7,0.42),1.0)
    draw_arc(pivot,47.0,0.0,TAU,64,Color(0.11,0.8,0.73,0.19),1.0)
    for i in range(4):
        var pp: Vector2 = Vector2(54 + i*58, 75 + (i%2)*42)
        var opacity: float = 0.2 + 0.8*(0.5+0.5*sin(_clock*2.5+i*1.6))
        draw_circle(pp,2.3,Color(0.19,1.0,0.71,opacity))
    _label(Vector2(20,178),"ACTIVE SYSTEMS", CYAN, 13)
    draw_line(Vector2(18,186),Vector2(290,186),Color(0.14,0.38,0.48,0.8),1.0)

    var items: Array[ServerNode] = _nodes()
    var ready_count: int = 0
    var count: int = mini(4,items.size())
    for i in range(count):
        var node = items[i]
        var ready: bool = int(node.state) == 1
        if ready:
            ready_count += 1
        var node_name: String = str(node.device_variant).to_upper().replace("_", " ")
        if node_name.length() > 17:
            node_name = node_name.substr(0,17)
        var y: float = 204.0 + 30.0 * i
        var c: Color = Color(1.0,0.35,0.52) if bool(node.is_honeypot) and ready else (GREEN if ready else MUTED)
        _label(Vector2(19,y),node_name,c,11)
        draw_rect(Rect2(180,y-10,101,6),Color(0.10,0.22,0.26),true)
        var fill: float = 1.0 if ready else clampf(float(node.progress), 0.0,1.0)
        draw_rect(Rect2(180,y-10,101*fill,6),c,true)
    for i in range(count,4):
        _label(Vector2(19,204+30*i),"AWAITING SIGNAL",Color(0.34,0.45,0.49),11)
    _label(Vector2(19,324),"NODES %d / READY %d" % [items.size(),_count_ready(items)],GREEN,11)
    draw_line(Vector2(18,334),Vector2(290,334),Color(0.14,0.38,0.48,0.8),1.0)
    _label(Vector2(19,354),"RECENT ACTIVITY",CYAN,13)
    for j in range(mini(3,_events.size())):
        _label(Vector2(19,373+j*15),"> " + _events[j], font_color if j==0 else MUTED,11)

func _count_ready(items: Array[ServerNode]) -> int:
    var n: int = 0
    for node in items:
        if int(node.state) == 1:
            n += 1
    return n
