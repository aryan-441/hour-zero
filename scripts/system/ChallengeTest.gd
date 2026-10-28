extends Node

var challenge_flow = preload("res://scripts/system/ChallengeFlow.gd").new()



func _ready() -> void:
	GameManager.start_mission()

	var challenge_flow = preload(
		"res://scripts/system/ChallengeFlow.gd"
	).new()

	challenge_flow.start_challenge()

	var answer: String = str(
		challenge_flow.current_question["answer"]
	)

	challenge_flow.submit_answer(answer)

	print("Test finished.")
