extends Node

var credits: int = 0
var exploits: int = 0
var zerodays: int = 0
var lifetime_credits_earned: int = 0

func add_credits(amount: int) -> void:
	credits += amount
	lifetime_credits_earned += amount

var decrypt_speed: float = 0.715
var decrypt_radius: float = 34.0
var bot_level: int = 0
var yield_mult: float = 1.0
var round_duration: float = 20.0
var honeypot_penalty_mult: float = 1.0
var max_nodes: int = 5
var weaken_mult: float = 1.0
var hunter_bot_count: int = 0
var row_wipe_level: int = 0
var ultimate_wipe_level: int = 0
var link_mesh_level: int = 0

var skill_levels: Dictionary = {}

var selected_tier: int = 0

const TIERS := [
	{
		"name": "HOME NETWORK", "color": Color8(57, 255, 106), "unlock_cost": 0, "node_mult": 1.0,
		"trait_name": "", "chain_crack": 0.0, "honeypots": false, "swarm_bots": false,
	},
	{
		"name": "OFFICE LAN", "color": Color8(0, 229, 255), "unlock_cost": 400, "node_mult": 1.8,
		"trait_name": "LATERAL MOVEMENT: exfiltrating has a 15% chance to auto-crack an adjacent node free",
		"chain_crack": 0.15, "honeypots": false, "swarm_bots": false,
	},
	{
		"name": "CORP NETWORK", "color": Color8(255, 46, 146), "unlock_cost": 2500, "node_mult": 3.2,
		"trait_name": "HONEYPOTS: rare high-value traps appear — grab them fast or they trip an alarm",
		"chain_crack": 0.15, "honeypots": true, "swarm_bots": false,
	},
	{
		"name": "BOTNET ARRAY", "color": Color8(255, 184, 48), "unlock_cost": 15000, "node_mult": 5.5,
		"trait_name": "SWARM: deployed bots crack two nodes per cycle instead of one",
		"chain_crack": 0.2, "honeypots": true, "swarm_bots": true,
	},
]

var unlocked_tiers: Array[bool] = [true, false, false, false]

func is_tier_unlocked(i: int) -> bool:
	return unlocked_tiers[i]

func try_unlock_tier(i: int) -> bool:
	var cost: int = TIERS[i]["unlock_cost"]
	if credits >= cost:
		credits -= cost
		unlocked_tiers[i] = true
		return true
	return false

func reset_all() -> void:
	credits = 0
	exploits = 0
	zerodays = 0
	lifetime_credits_earned = 0
	decrypt_speed = 0.715
	decrypt_radius = 34.0
	bot_level = 0
	yield_mult = 1.0
	round_duration = 20.0
	honeypot_penalty_mult = 1.0
	max_nodes = 5
	weaken_mult = 1.0
	hunter_bot_count = 0
	row_wipe_level = 0
	ultimate_wipe_level = 0
	link_mesh_level = 0
	skill_levels = {}
	selected_tier = 0
	unlocked_tiers = [true, false, false, false]
