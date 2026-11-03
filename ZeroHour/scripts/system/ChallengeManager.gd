extends Node

const BANK_PATH := "res://data/question_bank.json"
var questions: Array = []
var draw_pile: Array = []
var load_error := ""
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func content_key(question: Dictionary) -> String:
	# Content, rather than just an ID, prevents aliases of a question reappearing.
	var text := str(question.get("prompt", "")) + "|" + str(question.get("stimulus", ""))
	var words := text.to_lower().replace("\t", " ").replace("\n", " ").replace("\r", " ").split(" ", false)
	return " ".join(words)

func load_bank() -> bool:
	if not questions.is_empty():
		return true
	if not FileAccess.file_exists(BANK_PATH):
		load_error = "Question bank file is missing."
		push_error(load_error)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BANK_PATH))
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("questions"):
		load_error = "Question bank JSON is invalid."
		push_error(load_error)
		return false
	if typeof(parsed["questions"]) != TYPE_ARRAY:
		load_error = "Question bank must contain a questions array."
		return false
	var incoming: Array = parsed["questions"]
	var seen_ids: Dictionary = {}
	var seen_question_signatures: Dictionary = {}
	for item in incoming:
		if typeof(item) != TYPE_DICTIONARY or not item.get("validated", false):
			continue
		var question: Dictionary = item
		var question_id := str(question.get("id", ""))
		var signature := content_key(question)
		if question_id.is_empty() or seen_ids.has(question_id) or seen_question_signatures.has(signature):
			continue
		seen_ids[question_id] = true
		seen_question_signatures[signature] = true
		questions.append(question)
	if questions.is_empty():
		load_error = "Question bank contains no valid questions."
		push_error(load_error)
		return false
	return true

func reset_run() -> void:
	draw_pile = questions.duplicate(true)
	for index in range(draw_pile.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary: Dictionary = draw_pile[index]
		draw_pile[index] = draw_pile[swap_index]
		draw_pile[swap_index] = temporary

func remaining_count() -> int:
	return draw_pile.size()
