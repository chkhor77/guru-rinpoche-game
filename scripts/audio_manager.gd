class_name MonasteryAudio
extends Node

## Procedural audio synthesizer and sound manager for Samye Monastery.
## Generates meditative Tibetan singing bowl background music and mantra chimes,
## accompanied by the sacred chant "Om Ma Ni Pema Hom".

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var mantra_bell_stream: AudioStreamWAV
var ambient_music_stream: AudioStreamWAV


func _ready() -> void:
	# 1. Setup AudioStreamPlayers
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = -12.0
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.volume_db = -4.0
	add_child(sfx_player)

	# 2. Synthesize audio streams
	mantra_bell_stream = _create_singing_bowl_chime()
	ambient_music_stream = _create_meditative_ambient_loop()

	# 3. Start ambient background music
	music_player.stream = ambient_music_stream
	music_player.play()


## Plays the singing bowl chime when casting the mantra
func play_mantra_chime() -> void:
	if sfx_player and mantra_bell_stream:
		sfx_player.stream = mantra_bell_stream
		sfx_player.play()


## Synthesizes a resonant Tibetan singing bowl chime (16-bit PCM WAV)
func _create_singing_bowl_chime() -> AudioStreamWAV:
	var sample_rate := 44100
	var duration := 2.2
	var total_samples := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(total_samples * 2) # 16-bit mono = 2 bytes per sample

	var base_freq := 432.0 # Meditative A4 harmonic
	for i in range(total_samples):
		var t := float(i) / float(sample_rate)
		# Exponential ring-down decay
		var decay := exp(-t * 2.2)

		# Rich singing bowl harmonics (fundamental + 2nd + 3rd + 5th partials)
		var s1 := sin(TAU * base_freq * t)
		var s2 := sin(TAU * base_freq * 1.5 * t) * 0.45
		var s3 := sin(TAU * base_freq * 2.76 * t) * 0.25
		var s4 := sin(TAU * base_freq * 4.12 * t) * 0.12

		var mixed := (s1 + s2 + s3 + s4) * 0.5 * decay
		var sample_val := int(clampf(mixed, -1.0, 1.0) * 32767.0)

		# 16-bit signed integer little-endian
		byte_data.encode_s16(i * 2, sample_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_data
	return wav


## Synthesizes an ambient temple drone & meditative singing bowl harmony
func _create_meditative_ambient_loop() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 6.0
	var total_samples := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(total_samples * 2)

	var f1 := 108.0 # Sacred root tone (C2/D2 range)
	var f2 := 162.0 # Fifth (G2)
	var f3 := 216.0 # Octave
	var f4 := 324.0 # Warm major third overtone

	for i in range(total_samples):
		var t := float(i) / float(sample_rate)
		# Smooth looping LFO swells
		var lfo1 := (1.0 + sin(TAU * t / duration)) * 0.5
		var lfo2 := (1.0 + cos(TAU * t / duration)) * 0.5

		var s1 := sin(TAU * f1 * t) * 0.4
		var s2 := sin(TAU * f2 * t) * 0.25 * lfo1
		var s3 := sin(TAU * f3 * t) * 0.2 * lfo2
		var s4 := sin(TAU * f4 * t) * 0.15

		var mixed := (s1 + s2 + s3 + s4) * 0.4
		var sample_val := int(clampf(mixed, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples
	wav.data = byte_data
	return wav
