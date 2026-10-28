extends Node
signal state_changed
const PASSIVE_RISK_PER_SECOND := 0.4
const STATS_PATH := "user://profile.json"
const RECENT_QUESTION_HISTORY_LIMIT := 72
const PERK_COSTS := {"intel_ping": 225, "time_buffer": 300, "signal_scrubber": 450, "ghost_protocol": 750, "cache_spike": 525}
var game_state := "menu"
var score := 0
var risk := 0.0
var mission_depth := 0
var unbanked_rewards := 0
var banked_rewards := 0
var run_credits_banked := 0
var run_credits_lost := 0
var run_result := ""
var last_resolution: Dictionary = {}
var fast_answer_streak := 0
var poor_answer_streak := 0
var difficulty_adjustment := 0
var profile: Dictionary = {}
var normal_questions_since_boss := 0
var boss_pending := false
var current_challenge_is_boss := false
var ghost_protocol_armed := false
var cache_spike_armed := false
var run_summary: Dictionary = {}

func _ready() -> void:
	_load_stats()

func _default_stats() -> Dictionary:
	return {"games_played": 0, "questions_answered": 0, "correct_answers": 0, "total_answer_seconds": 0.0, "banked_credits_total": 0, "credits_wallet": 0, "perk_inventory": {"intel_ping": 0, "time_buffer": 0, "signal_scrubber": 0, "ghost_protocol": 0, "cache_spike": 0}, "lost_unbanked_credits_total": 0, "extracted_runs": 0, "detected_runs": 0, "best_score": 0, "best_depth": 0, "recent_question_ids": [], "recent_question_keys": [], "sound_enabled": true}

func _load_stats() -> void:
	profile = _default_stats()
	if not FileAccess.file_exists(STATS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STATS_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in profile:
			if parsed.has(key):
				profile[key] = parsed[key]
		banked_rewards = int(profile["banked_credits_total"])
		# Older profiles tracked lifetime banked credits but had no spendable wallet.
		# Migrate that existing balance once so earned credits remain usable.
		if not parsed.has("credits_wallet"):
			profile["credits_wallet"] = banked_rewards
		if typeof(profile.get("perk_inventory", null)) != TYPE_DICTIONARY:
			profile["perk_inventory"] = _default_stats()["perk_inventory"].duplicate(true)
		for perk_id in PERK_COSTS:
			profile["perk_inventory"][perk_id] = int(profile["perk_inventory"].get(perk_id, 0))
		if typeof(profile.get("recent_question_ids", null)) != TYPE_ARRAY:
			profile["recent_question_ids"] = []
		_save_stats()

func _save_stats() -> void:
	var file := FileAccess.open(STATS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(profile, "\t"))
		file.close()

func get_stats() -> Dictionary:
	return profile.duplicate(true)

func get_recent_question_keys() -> Array:
	var recent: Variant = profile.get("recent_question_keys", [])
	return recent if typeof(recent) == TYPE_ARRAY else []

func is_sound_enabled() -> bool:
	return bool(profile.get("sound_enabled", true))

func set_sound_enabled(enabled: bool) -> void:
	profile["sound_enabled"] = enabled
	_save_stats()
	state_changed.emit()

func get_recent_question_ids() -> Array:
	var recent: Variant = profile.get("recent_question_ids", [])
	return recent if typeof(recent) == TYPE_ARRAY else []

func remember_question(question_id: String, content_key: String = "") -> void:
	if question_id.is_empty():
		return
	var recent := get_recent_question_ids()
	recent.erase(question_id)
	recent.append(question_id)
	while recent.size() > RECENT_QUESTION_HISTORY_LIMIT:
		recent.pop_front()
	profile["recent_question_ids"] = recent
	if not content_key.is_empty():
		var keys := get_recent_question_keys()
		keys.erase(content_key)
		keys.append(content_key)
		while keys.size() > RECENT_QUESTION_HISTORY_LIMIT:
			keys.pop_front()
		profile["recent_question_keys"] = keys
	_save_stats()

func get_credit_wallet() -> int:
	return int(profile.get("credits_wallet", 0))

func get_perk_inventory() -> Dictionary:
	var inventory: Dictionary = profile.get("perk_inventory", {})
	return inventory.duplicate(true)

func get_perk_count(perk_id: String) -> int:
	return int(profile.get("perk_inventory", {}).get(perk_id, 0))

func buy_perk(perk_id: String) -> bool:
	if not PERK_COSTS.has(perk_id):
		return false
	var cost := int(PERK_COSTS[perk_id])
	if get_credit_wallet() < cost:
		return false
	profile["credits_wallet"] = get_credit_wallet() - cost
	var inventory: Dictionary = profile["perk_inventory"]
	inventory[perk_id] = int(inventory.get(perk_id, 0)) + 1
	_save_stats()
	state_changed.emit()
	return true

func consume_perk(perk_id: String) -> bool:
	if game_state != "playing" or current_challenge_is_boss:
		return false
	if normal_questions_since_boss >= 7 and perk_id in ["ghost_protocol", "cache_spike"]:
		return false
	if get_perk_count(perk_id) <= 0:
		return false
	var inventory: Dictionary = profile["perk_inventory"]
	inventory[perk_id] = int(inventory[perk_id]) - 1
	_save_stats()
	state_changed.emit()
	return true

func arm_ghost_protocol() -> void:
	ghost_protocol_armed = true

func arm_cache_spike() -> void:
	cache_spike_armed = true

func record_answer(elapsed: float, correct: bool) -> void:
	profile["questions_answered"] = int(profile["questions_answered"]) + 1
	profile["correct_answers"] = int(profile["correct_answers"]) + (1 if correct else 0)
	profile["total_answer_seconds"] = float(profile["total_answer_seconds"]) + maxf(elapsed, 0.0)
	_save_stats()

func start_mission() -> void:
	game_state = "playing"
	score = 0
	risk = 0.0
	mission_depth = 1
	unbanked_rewards = 0
	run_credits_banked = 0
	run_credits_lost = 0
	run_result = ""
	last_resolution = {}
	run_summary = {}
	fast_answer_streak = 0
	poor_answer_streak = 0
	difficulty_adjustment = 0
	normal_questions_since_boss = 0
	boss_pending = false
	current_challenge_is_boss = false
	ghost_protocol_armed = false
	cache_spike_armed = false
	profile["games_played"] = int(profile["games_played"]) + 1
	_save_stats()
	state_changed.emit()

func advance_risk(delta: float) -> void:
	if game_state == "playing" and delta > 0.0:
		risk = clampf(risk + PASSIVE_RISK_PER_SECOND * delta, 0.0, 100.0)
		check_full_exposure()

func check_full_exposure() -> bool:
	if game_state != "playing" or risk < 100.0:
		return false
	last_resolution = {"resolved": true, "risk": 100.0, "detection_chance": 100.0, "detected": true, "exposure_limit": true, "blocked_by_ghost_protocol": false}
	_finish_detected()
	state_changed.emit()
	return true

func _finish_detected() -> void:
	run_result = "detected"
	run_credits_lost = unbanked_rewards
	profile["detected_runs"] = int(profile["detected_runs"]) + 1
	profile["lost_unbanked_credits_total"] = int(profile["lost_unbanked_credits_total"]) + run_credits_lost
	_finish_run()

func _finish_run() -> void:
	# Keep the after-action report while clearing the now-inactive live mission.
	run_summary = {"result": run_result, "score": score, "depth": mission_depth, "exposure": risk, "banked": run_credits_banked, "lost": run_credits_lost}
	_update_records()
	_save_stats()
	game_state = "results"
	risk = 0.0
	score = 0
	mission_depth = 0
	unbanked_rewards = 0
	current_challenge_is_boss = false
	boss_pending = false
	ghost_protocol_armed = false
	cache_spike_armed = false

func finish_exhausted_run() -> void:
	if game_state != "playing":
		return
	# A completed finite bank is a clean extraction, never a stuck live mission.
	game_state = "decision"
	extract()

func return_to_start() -> void:
	if game_state in ["playing", "decision", "boss_briefing"]:
		return
	game_state = "menu"
	state_changed.emit()

func get_difficulty_tier() -> int:
	var depth_tier := 1 + int((mission_depth - 1) / 3)
	return clampi(depth_tier + difficulty_adjustment, 1, 5)

func complete_challenge(points: int, risk_increase: float, credit_reward: int, correct: bool, fast_or_slow: int, is_boss: bool = false) -> Dictionary:
	if game_state != "playing":
		return {"resolved": false}
	if check_full_exposure():
		return last_resolution
	score += points
	var applied_risk_delta := risk_increase
	var boss_bonus := 0
	var cache_bonus := 0
	if is_boss:
		applied_risk_delta = -10.0 if correct else 15.0
		normal_questions_since_boss = 0
		current_challenge_is_boss = false
	else:
		normal_questions_since_boss += 1
	risk = clampf(risk + applied_risk_delta, 0.0, 100.0)
	if correct:
		unbanked_rewards += credit_reward
		if is_boss:
			boss_bonus = 150
			unbanked_rewards += boss_bonus
		if cache_spike_armed:
			cache_bonus = 50
			unbanked_rewards += cache_bonus
		if fast_or_slow > 0:
			fast_answer_streak += 1
			poor_answer_streak = 0
			if fast_answer_streak >= 3:
				difficulty_adjustment = mini(1, difficulty_adjustment + 1)
				fast_answer_streak = 0
		elif fast_or_slow < 0:
			fast_answer_streak = 0
			poor_answer_streak += 1
			if poor_answer_streak >= 2:
				difficulty_adjustment = maxi(-1, difficulty_adjustment - 1)
				poor_answer_streak = 0
		else:
			fast_answer_streak = 0
			poor_answer_streak = 0
	else:
		fast_answer_streak = 0
		poor_answer_streak += 1
		if poor_answer_streak >= 2:
			difficulty_adjustment = maxi(-1, difficulty_adjustment - 1)
			poor_answer_streak = 0
	cache_spike_armed = false
	var profile_now := get_detection_profile()
	var roll := randf() * 100.0
	var full_exposure := risk >= 100.0
	var detected: bool = full_exposure or roll < float(profile_now["chance"])
	var blocked_by_ghost := detected and ghost_protocol_armed and not full_exposure
	if blocked_by_ghost:
		detected = false
		ghost_protocol_armed = false
	last_resolution = {"resolved": true, "points": points, "risk_increase": applied_risk_delta, "risk": risk, "detection_chance": profile_now["chance"], "detected": detected, "roll": roll, "correct": correct, "difficulty_tier": get_difficulty_tier(), "is_boss": is_boss, "boss_bonus_credits": boss_bonus, "boss_risk_change": applied_risk_delta if is_boss else 0.0, "blocked_by_ghost_protocol": blocked_by_ghost, "cache_spike_bonus": cache_bonus}
	if detected:
		_finish_detected()
	else:
		game_state = "decision"
	state_changed.emit()
	return last_resolution

func continue_mission() -> void:
	if game_state != "decision":
		return
	mission_depth += 1
	if normal_questions_since_boss >= 8:
		normal_questions_since_boss = 0
		boss_pending = true
		game_state = "boss_briefing"
	else:
		game_state = "playing"
	state_changed.emit()

func begin_boss_challenge() -> void:
	if game_state != "boss_briefing" or not boss_pending:
		return
	boss_pending = false
	current_challenge_is_boss = true
	ghost_protocol_armed = false
	cache_spike_armed = false
	game_state = "playing"
	state_changed.emit()

func skip_boss() -> void:
	if game_state != "boss_briefing" or not boss_pending:
		return
	risk = clampf(risk + 5.0, 0.0, 100.0)
	boss_pending = false
	current_challenge_is_boss = false
	game_state = "playing"
	if check_full_exposure():
		return
	state_changed.emit()

func extract() -> void:
	if game_state != "decision":
		return
	run_credits_banked = unbanked_rewards
	banked_rewards += unbanked_rewards
	profile["credits_wallet"] = get_credit_wallet() + unbanked_rewards
	unbanked_rewards = 0
	run_result = "extracted"
	profile["banked_credits_total"] = int(profile["banked_credits_total"]) + run_credits_banked
	profile["extracted_runs"] = int(profile["extracted_runs"]) + 1
	_finish_run()
	state_changed.emit()

func _update_records() -> void:
	profile["best_score"] = maxi(int(profile["best_score"]), score)
	profile["best_depth"] = maxi(int(profile["best_depth"]), mission_depth)

func get_detection_profile() -> Dictionary:
	if risk >= 100.0:
		return {"band": "CRITICAL", "chance": 100.0}
	if risk < 50.0:
		return {"band": "GREEN", "chance": 0.0}
	if risk < 65.0:
		return {"band": "YELLOW", "chance": 1.0}
	if risk < 80.0:
		return {"band": "ORANGE", "chance": 5.0}
	if risk < 95.0:
		return {"band": "RED", "chance": 25.0}
	return {"band": "CRITICAL", "chance": 65.0}

