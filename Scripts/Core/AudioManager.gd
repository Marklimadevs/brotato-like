extends Node

# AudioManager — autoload singleton.
# Sistema completo de áudio que FUNCIONA mesmo sem nenhum arquivo de áudio:
# - se o arquivo existe em Assets/Audio/SFX/<name>.ogg → toca normal
# - se não existe → silencioso (sem erro, sem warning)
#
# Hooks no jogo chamam AudioManager.play_sfx("nome") ou .play_music("track").
# Quando você adicionar os arquivos depois, eles tocam automaticamente.

const SFX_DIR := "res://Assets/Audio/SFX/"
const MUSIC_DIR := "res://Assets/Audio/Music/"
const SFX_POOL_SIZE := 16
const SFX_EXTENSIONS := [".ogg", ".wav", ".mp3"]
const MUSIC_EXTENSIONS := [".ogg", ".mp3"]
const MUSIC_FADE_DURATION := 0.6

var _master_bus_idx: int = 0
var _music_bus_idx: int = 1
var _sfx_bus_idx: int = 2

var _sfx_cache: Dictionary = {}    # name -> AudioStream | null (null = não existe, evita retentativas)
var _music_cache: Dictionary = {}
var _sfx_pool: Array = []          # AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _current_music: String = ""
var _music_tween: Tween = null

# Persistido via SaveData
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.9


func _ready() -> void:
	_ensure_buses()
	_setup_pool()
	_setup_music_player()
	_load_settings()
	_apply_volumes()


func _ensure_buses() -> void:
	# Master é sempre o bus 0 (criado pelo engine)
	_master_bus_idx = 0

	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	_music_bus_idx = AudioServer.get_bus_index("Music")

	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	_sfx_bus_idx = AudioServer.get_bus_index("SFX")


func _setup_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)


func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)


# ============== API PÚBLICA ==============

# Toca um SFX. Se o arquivo não existe, silencioso (sem erro).
# pitch_variation: 0.0 = sem variação. 0.1 = ±10% (útil pra tiros não soarem repetitivos).
func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	if sfx_name.is_empty():
		return
	var stream = _load_sfx(sfx_name)
	if stream == null:
		return  # arquivo não existe ainda — silencioso
	var player: AudioStreamPlayer = _get_free_sfx_player()
	if player == null:
		return  # pool cheio, dropa
	player.stream = stream
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	else:
		player.pitch_scale = 1.0
	player.play()


# Toca uma música. Se já está tocando a mesma, no-op.
# Se o arquivo não existe, para a música atual.
# fade: true = crossfade suave; false = corte imediato.
func play_music(music_name: String, fade: bool = true) -> void:
	if music_name == _current_music and _music_player.playing:
		return
	var stream = _load_music(music_name)
	if stream == null:
		stop_music(fade)
		_current_music = ""
		return
	if fade and _music_player.playing:
		_fade_to_music(stream, music_name)
	else:
		_current_music = music_name
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()


func stop_music(fade: bool = true) -> void:
	if not _music_player.playing:
		_current_music = ""
		return
	if fade:
		if _music_tween != null and _music_tween.is_valid():
			_music_tween.kill()
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -80.0, MUSIC_FADE_DURATION)
		_music_tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()
	_current_music = ""


func _fade_to_music(new_stream: AudioStream, new_name: String) -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80.0, MUSIC_FADE_DURATION / 2.0)
	_music_tween.tween_callback(func():
		_music_player.stream = new_stream
		_music_player.volume_db = -80.0
		_music_player.play()
		_current_music = new_name
	)
	_music_tween.tween_property(_music_player, "volume_db", 0.0, MUSIC_FADE_DURATION / 2.0)


# ============== VOLUME ==============

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(_master_bus_idx, _linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(_music_bus_idx, _linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(_sfx_bus_idx, _linear_to_db(sfx_volume))


func _linear_to_db(v: float) -> float:
	if v <= 0.001:
		return -80.0
	return 20.0 * log(v) / log(10.0)


# ============== INTERNAL: LOAD ==============

func _load_sfx(sfx_name: String) -> AudioStream:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]
	for ext in SFX_EXTENSIONS:
		var path: String = SFX_DIR + sfx_name + ext
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			_sfx_cache[sfx_name] = stream
			return stream
	# Arquivo não encontrado — cacheia null pra não tentar de novo
	_sfx_cache[sfx_name] = null
	return null


func _load_music(music_name: String) -> AudioStream:
	if _music_cache.has(music_name):
		return _music_cache[music_name]
	for ext in MUSIC_EXTENSIONS:
		var path: String = MUSIC_DIR + music_name + ext
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			# Auto-loop nas músicas
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			elif stream is AudioStreamMP3:
				(stream as AudioStreamMP3).loop = true
			_music_cache[music_name] = stream
			return stream
	_music_cache[music_name] = null
	return null


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return null


# ============== SETTINGS PERSISTENCE ==============

func _load_settings() -> void:
	master_volume = SaveData.MasterVolume
	music_volume = SaveData.MusicVolume
	sfx_volume = SaveData.SfxVolume


func _save_settings() -> void:
	SaveData.MasterVolume = master_volume
	SaveData.MusicVolume = music_volume
	SaveData.SfxVolume = sfx_volume
	SaveData.save_data()
