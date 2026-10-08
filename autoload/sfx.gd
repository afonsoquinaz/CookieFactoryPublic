extends Node
## Sound effects and music. Sounds are synthesized by tools/gen_audio.py.
##   Sfx.play("pop")           picks pop_1..3 at random, slight pitch jitter
##   Sfx.play("coin", -4, 1.2) volume offset (dB) and pitch

const DIR := "res://assets/audio/"
## Base loudness per sound (dB): all files are normalised to the same peak.
const VOLUME := {
	"pop": -9.0, "drop": -8.0, "coin": -10.0, "cash": -4.0, "whoosh": -14.0, "plop": -10.0,
	"dispense": -12.0, "oven_ding": -9.0, "horn": -6.0, "engine": -12.0, "build": -3.0,
	"upgrade": -5.0, "levelup": -2.0, "hire": -5.0, "click": -8.0, "open": -10.0, "close": -12.0,
	"deny": -8.0, "pay_tick": -16.0, "cluck": -14.0, "moo": -12.0, "step": -22.0,
}
const MIN_GAP := 0.045

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}
var _music: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	var d := DirAccess.open(DIR)
	if d:
		for f in d.get_files():
			var base := f.trim_suffix(".import")
			if not (base.ends_with(".wav") or base.ends_with(".ogg")):
				continue
			var key := base.get_basename()
			if _streams.has(key):
				continue
			var s = load(DIR + base)
			if s:
				_streams[key] = s
	_music = AudioStreamPlayer.new()
	_music.volume_db = -9.0
	add_child(_music)
	_amb = AudioStreamPlayer.new()
	_amb.volume_db = -6.0
	add_child(_amb)


func _process(dt: float) -> void:
	_t += dt


func start_music() -> void:
	if _streams.has("music") and Game.settings.get("music", true):
		var m: AudioStream = _streams["music"]
		if m is AudioStreamOggVorbis:
			m.loop = true
		_music.stream = m
		_music.play()
	if _streams.has("ambience") and Game.settings.get("sfx", true):
		var a: AudioStream = _streams["ambience"]
		if a is AudioStreamOggVorbis:
			a.loop = true
		_amb.stream = a
		_amb.play()


func set_music(on: bool) -> void:
	Game.settings["music"] = on
	if on:
		if not _music.playing:
			start_music()
	else:
		_music.stop()


func set_sfx(on: bool) -> void:
	Game.settings["sfx"] = on
	if not on:
		_amb.stop()
	elif not _amb.playing:
		start_music()


func _pick(name: String) -> AudioStream:
	if _streams.has(name):
		return _streams[name]
	var variants := []
	for i in range(1, 5):
		var k := "%s_%d" % [name, i]
		if _streams.has(k):
			variants.append(_streams[k])
	return variants.pick_random() if variants.size() > 0 else null


func play(name: String, vol := 0.0, pitch := 1.0, jitter := 0.06) -> void:
	if not Game.settings.get("sfx", true):
		return
	if _t - float(_last.get(name, -1.0)) < MIN_GAP:
		return
	_last[name] = _t
	var s := _pick(name)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.volume_db = float(VOLUME.get(name, -8.0)) + vol
	p.pitch_scale = pitch * (1.0 + randf_range(-jitter, jitter))
	p.play()
