extends Node

const GRACE_SECONDS := 6.0
var challenge_manager = preload("res://scripts/system/ChallengeManager.gd").new()
var answer_validator = preload("res://scripts/system/AnswerValidator.gd").new()
var scoring_manager = preload("res://scripts/system/ScoringManager.gd").new()
var current_question: Dictionary = {}
var question_start_time := 0
var target_time := 8.0
var previous_category := ""
var time_bonus_this_challenge := 0.0
var active_base_limit := 12.0
var active_is_boss := false
var used_question_ids_this_run: Dictionary = {}
var used_question_keys_this_run: Dictionary = {}
var recent_categories: Array[String] = []
var family_uses: Dictionary = {}
var last_family_by_category: Dictionary = {}

func _init() -> void:
	# Own the helper Nodes so freeing the flow also releases its question bank.
	add_child(challenge_manager)
	add_child(answer_validator)
	add_child(scoring_manager)

func _ready() -> void:
	challenge_manager.load_bank()

func reset_run() -> void:
	challenge_manager.load_bank()
	challenge_manager.reset_run()
	current_question.clear()
	previous_category = ""
	time_bonus_this_challenge = 0.0
	used_question_ids_this_run.clear()
	used_question_keys_this_run.clear()
	recent_categories.clear()
	family_uses.clear()
	last_family_by_category.clear()

func start_challenge(is_boss: bool = false) -> Dictionary:
	if GameManager.game_state != "playing" or challenge_manager.draw_pile.is_empty():
		return {}
	time_bonus_this_challenge = 0.0
	active_is_boss = is_boss
	var target_tier := 5 if is_boss else GameManager.get_difficulty_tier()
	var eligible_indices: Array[int] = []
	var fresh_indices: Array[int] = []
	var recent_ids := GameManager.get_recent_question_ids()
	var recent_keys := GameManager.get_recent_question_keys()
	for index in range(challenge_manager.draw_pile.size()):
		var candidate: Dictionary = challenge_manager.draw_pile[index]
		var question_id := str(candidate.get("id", ""))
		var question_key: String = challenge_manager.content_key(candidate)
		# These are hard exclusions, including when cross-run history is exhausted.
		if used_question_ids_this_run.has(question_id) or used_question_keys_this_run.has(question_key):
			continue
		if is_boss and not bool(candidate.get("boss_eligible", false)):
			continue
		if not is_boss and bool(candidate.get("boss_eligible", false)):
			continue
		eligible_indices.append(index)
		if not recent_ids.has(question_id) and not recent_keys.has(question_key):
			fresh_indices.append(index)
	if eligible_indices.is_empty():
		return {}
	var matching_indices: Array[int] = []
	for index in fresh_indices:
		var candidate: Dictionary = challenge_manager.draw_pile[index]
		if (is_boss and int(candidate.get("difficulty", 1)) == 5) or (not is_boss and int(candidate.get("difficulty", 1)) == target_tier):
			matching_indices.append(index)
	# Keep every normal question fresh even when the exact tier has been seen recently.
	# Bosses stay in the hard pool and choose the highest fresh tier available.
	if matching_indices.is_empty() and not fresh_indices.is_empty():
		var preferred_tier := 0 if is_boss else target_tier
		if is_boss:
			for index in fresh_indices:
				preferred_tier = maxi(preferred_tier, int(challenge_manager.draw_pile[index].get("difficulty", 1)))
		else:
			var smallest_tier_gap := 99
			for index in fresh_indices:
				var candidate_tier := int(challenge_manager.draw_pile[index].get("difficulty", 1))
				smallest_tier_gap = mini(smallest_tier_gap, absi(candidate_tier - target_tier))
			for index in fresh_indices:
				var fallback_tier := int(challenge_manager.draw_pile[index].get("difficulty", 1))
				if absi(fallback_tier - target_tier) == smallest_tier_gap:
					matching_indices.append(index)
		if is_boss:
			for index in fresh_indices:
				if int(challenge_manager.draw_pile[index].get("difficulty", 1)) == preferred_tier:
					matching_indices.append(index)
	# Cross-run history is a preference; this-run exclusions are never relaxed.
	if matching_indices.is_empty():
		matching_indices = eligible_indices
	var varied_indices: Array[int] = []
	for index in matching_indices:
		var candidate: Dictionary = challenge_manager.draw_pile[index]
		if str(candidate.get("category", "")) != previous_category:
			varied_indices.append(index)
	if not varied_indices.is_empty():
		matching_indices = varied_indices
	# Weight categories to bring more arithmetic into regular runs while retaining broad coverage.
	# The previous-category filter above still prevents back-to-back categories when alternatives exist.
	var category_weights := {"arithmetic": 35.0, "patterns": 22.0, "logic": 19.0, "memory": 13.0, "attention": 11.0}
	var available_categories: Array[String] = []
	var total_weight := 0.0
	for index in matching_indices:
		var category := str(challenge_manager.draw_pile[index].get("category", ""))
		if not available_categories.has(category):
			available_categories.append(category)
			total_weight += float(category_weights.get(category, 1.0))
	var category_roll: float = challenge_manager.rng.randf() * total_weight
	var selected_category: String = available_categories.back()
	for category in available_categories:
		category_roll -= float(category_weights.get(category, 1.0))
		if category_roll < 0.0:
			selected_category = category
			break
	var category_indices: Array[int] = []
	for index in matching_indices:
		if str(challenge_manager.draw_pile[index].get("category", "")) == selected_category:
			category_indices.append(index)
	matching_indices = category_indices
	var least_used := 2147483647
	var family_indices: Array[int] = []
	for index in matching_indices:
		var candidate: Dictionary = challenge_manager.draw_pile[index]
		var category := str(candidate.get("category", ""))
		var family := category + ":" + str(candidate.get("subcategory", ""))
		var usage := int(family_uses.get(family, 0))
		if last_family_by_category.get(category, "") == family:
			usage += 1000
		if usage < least_used:
			least_used = usage
			family_indices.clear()
		if usage == least_used:
			family_indices.append(index)
	matching_indices = family_indices
	var selected_index := matching_indices[challenge_manager.rng.randi_range(0, matching_indices.size() - 1)]
	current_question = challenge_manager.draw_pile.pop_at(selected_index)
	var selected_id := str(current_question.get("id", ""))
	used_question_ids_this_run[selected_id] = true
	var selected_key: String = challenge_manager.content_key(current_question)
	used_question_keys_this_run[selected_key] = true
	GameManager.remember_question(selected_id, selected_key)
	previous_category = str(current_question.get("category", ""))
	recent_categories.append(previous_category)
	if recent_categories.size() > 5:
		recent_categories.pop_front()
	var selected_family := previous_category + ":" + str(current_question.get("subcategory", ""))
	family_uses[selected_family] = int(family_uses.get(selected_family, 0)) + 1
	last_family_by_category[previous_category] = selected_family
	sync_time_to_exposure()
	question_start_time = Time.get_ticks_msec()
	return current_question

func begin_response_phase() -> void:
	sync_time_to_exposure()
	question_start_time = Time.get_ticks_msec()

func sync_time_to_exposure() -> float:
	if current_question.is_empty():
		return active_base_limit + time_bonus_this_challenge
	var timer_key := "boss_time_limits_by_exposure" if active_is_boss else "time_limits_by_exposure"
	var timer_table: Dictionary = current_question.get(timer_key, {})
	var band := str(GameManager.get_detection_profile().get("band", "GREEN"))
	active_base_limit = float(timer_table.get(band, current_question.get("time_limit_seconds", 12.0)))
	current_question["time_limit_seconds"] = active_base_limit
	return active_base_limit + time_bonus_this_challenge

func add_time_buffer(seconds: float) -> void:
	time_bonus_this_challenge += maxf(seconds, 0.0)

func get_current_hint() -> String:
	if current_question.is_empty():
		return "Break the challenge into smaller steps and look for a pattern."
	var stored_hint := str(current_question.get("intel_hint", current_question.get("hint", "")))
	if not stored_hint.is_empty():
		return stored_hint
	match str(current_question.get("category", "")):
		"arithmetic": return "Look for a friendly number or a shortcut before calculating."
		"patterns": return "Compare how each term changes from the one before it."
		"logic": return "Apply each clue carefully and eliminate impossible answers."
		"memory": return "The stimulus has ended; focus on the requested position or relationship. Use Intel Ping for a remembered landmark."
		"attention": return "Compare one position at a time, counting from the left."
	return "Break the challenge into smaller steps and look for a pattern."

func submit_answer(player_answer: String, timed_out: bool = false) -> Dictionary:
	if current_question.is_empty() or GameManager.game_state != "playing":
		return {"resolved": false}
	var elapsed := float(Time.get_ticks_msec() - question_start_time) / 1000.0
	var correct := answer_validator.check_answer(player_answer, current_question)
	var limit := active_base_limit + time_bonus_this_challenge
	var tier := int(current_question.get("difficulty", 1))
	var base_points := int(current_question.get("base_points", 100))
	var points := scoring_manager.calculate_points(elapsed, limit, correct, tier, base_points)
	target_time = minf(8.0, limit * 0.65)
	var risk_delta := scoring_manager.calculate_risk_increase(elapsed, target_time, correct, timed_out, limit)
	var credits := int(current_question.get("credit_reward", 0)) if correct else 0
	var performance := 1 if correct and elapsed <= target_time else (-1 if timed_out or not correct or elapsed >= limit * 0.9 else 0)
	GameManager.record_answer(elapsed, correct)
	var result := GameManager.complete_challenge(points, risk_delta, credits, correct, performance, active_is_boss)
	result["correct"] = correct
	result["elapsed_seconds"] = elapsed
	result["overtime_seconds"] = clampf(elapsed - limit, 0.0, GRACE_SECONDS)
	result["base_time_seconds"] = limit
	result["timed_out"] = timed_out
	result["explanation"] = current_question.get("explanation", "")
	result["question_id"] = current_question.get("id", "")
	result["category"] = current_question.get("category", "")
	result["is_boss"] = active_is_boss
	current_question.clear()
	active_is_boss = false
	return result


