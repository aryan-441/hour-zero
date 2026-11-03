extends Node

func _normalise_text(value: String) -> String:
	var words := value.strip_edges().to_lower().replace("\t", " ").replace("\n", " ").replace("\r", " ").split(" ", false)
	return " ".join(words).replace(" |", "|").replace("| ", "|")

func check_answer(player_answer: String, question: Dictionary) -> bool:
	var submitted := player_answer.strip_edges()
	if submitted.is_empty():
		return false
	var accepted: Array = question.get("accepted_answers", [question.get("answer", null)])
	for candidate in accepted:
		if typeof(candidate) == TYPE_INT or typeof(candidate) == TYPE_FLOAT:
			if submitted.is_valid_float() and float(submitted) == float(candidate):
				return true
		elif _normalise_text(submitted) == _normalise_text(str(candidate)):
			return true
	return false
