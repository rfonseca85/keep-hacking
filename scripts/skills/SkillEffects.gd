extends RefCounted
class_name SkillEffects

## Applies gameplay changes when a skill is purchased (logic stays in code; cards hold display data).
static func apply(skill_id: String) -> void:
	match skill_id:
		"speed1":
			GameState.decrypt_speed += 0.2
		"radius1":
			GameState.decrypt_radius += 6.0
		"yield1":
			GameState.yield_mult += 0.15
		"footprint1":
			GameState.max_nodes += 2
		"duration1":
			GameState.round_duration += 4.0
		"bot1":
			GameState.bot_level += 1
		"weaken_all":
			GameState.weaken_mult += 0.1
		"forensics1":
			GameState.honeypot_penalty_mult = max(0.2, GameState.honeypot_penalty_mult - 0.25)
		"speed2":
			GameState.decrypt_speed += 0.5
		"radius2":
			GameState.decrypt_radius += 14.0
		"bot2":
			GameState.bot_level += 2
		"yield2":
			GameState.zerodays += 1
		"hunter_bot":
			GameState.hunter_bot_count += 1
		"row_wipe":
			GameState.row_wipe_level += 1
		"ultimate_wipe":
			GameState.ultimate_wipe_level += 1
		"filler1":
			pass
		_:
			push_warning("Unknown skill id: " + skill_id)
