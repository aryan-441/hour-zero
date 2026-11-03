extends Node

# Short PCM cues are baked into the game assets; playback does not synthesize per frame.

const POOL_SIZE := 6
var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var enabled := true

func _ready() -> void:
	streams["menu"] = preload("res://assets/audio/menu.res")
	streams["navigate"] = preload("res://assets/audio/navigate.res")
	streams["submit"] = preload("res://assets/audio/submit.res")
	streams["radar"] = preload("res://assets/audio/radar.res")
	streams["click"] = preload("res://assets/audio/click.res")
	streams["deploy"] = preload("res://assets/audio/deploy.res")
	streams["correct"] = preload("res://assets/audio/correct.res")
	streams["incorrect"] = preload("res://assets/audio/incorrect.res")
	streams["warning"] = preload("res://assets/audio/warning.res")
	streams["extracted"] = preload("res://assets/audio/extracted.res")
	streams["detected"] = preload("res://assets/audio/detected.res")
	streams["perk"] = preload("res://assets/audio/perk.res")
	streams["purchase"] = preload("res://assets/audio/purchase.res")
	streams["boss"] = preload("res://assets/audio/boss.res")
	for index in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		for player in players:
			player.stop()

func play_cue(cue: String) -> void:
	if not enabled or not streams.has(cue) or players.is_empty():
		return
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stop()
	player.stream = streams[cue]
	player.volume_db = -30.0 if cue == "radar" else (-22.0 if cue in ["click","menu","navigate","submit"] else -16.0)
	player.play()

