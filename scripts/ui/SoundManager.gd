extends Node

# Short PCM cues are generated once; playback does not synthesize per frame.
const SAMPLE_RATE := 22050
const POOL_SIZE := 6
var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var enabled := true

func _ready() -> void:
	streams["radar"] = _tone_sequence([920.0, 690.0], 0.035, 0.0)
	streams["click"] = _tone_sequence([900.0], 0.035, 0.0)
	streams["deploy"] = _tone_sequence([220.0, 330.0, 440.0, 660.0], 0.085, 0.015)
	streams["correct"] = _tone_sequence([523.25, 659.25, 783.99], 0.09, 0.01)
	streams["incorrect"] = _tone_sequence([260.0, 185.0], 0.14, 0.025)
	streams["warning"] = _tone_sequence([740.0, 550.0, 740.0], 0.1, 0.05)
	streams["extracted"] = _tone_sequence([392.0, 523.25, 659.25, 783.99], 0.14, 0.02)
	streams["detected"] = _tone_sequence([440.0, 349.23, 261.63, 130.81], 0.18, 0.025)
	streams["perk"] = _tone_sequence([330.0, 660.0, 990.0], 0.065, 0.01)
	streams["purchase"] = _tone_sequence([659.25, 880.0], 0.1, 0.015)
	streams["boss"] = _tone_sequence([164.81, 155.56, 164.81], 0.2, 0.04)
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
	player.volume_db = -28.0 if cue == "radar" else (-20.0 if cue == "click" else -13.0)
	player.play()

func _tone_sequence(notes: Array, duration: float, gap: float) -> AudioStreamWAV:
	var note_samples := int(duration * SAMPLE_RATE)
	var gap_samples := int(gap * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(notes.size() * (note_samples + gap_samples) * 2)
	var offset := 0
	for frequency in notes:
		for index in range(note_samples):
			var t := float(index) / SAMPLE_RATE
			var attack := minf(t / 0.008, 1.0)
			var release := minf(float(note_samples - 1 - index) / (SAMPLE_RATE * 0.025), 1.0)
			var envelope := attack * release * (1.0 - 0.25 * float(index) / note_samples)
			var value := (sin(TAU * float(frequency) * t) + 0.18 * sin(TAU * float(frequency) * 2.0 * t)) * envelope * 0.55
			data.encode_s16(offset + index * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
		offset += (note_samples + gap_samples) * 2
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
