extends Node2D
## The title screen: press space to play. Never pauses.

const MUSIC_VOLUME_DB := -13.6
const START_VOLUME_DB := 1.6

var _music: AudioStreamPlayer
var _start_sound: AudioStreamPlayer
var _started := false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.size = Vector2(Screen.width, Screen.height)
	add_child(black)
	var label := Label.new()
	label.text = "Press space to play"
	label.size = Vector2(Screen.width, Screen.height)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	var track: AudioStreamOggVorbis = load("res://music/adventure_begin.ogg")
	track.loop = true
	_music.stream = track
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)
	_music.play()
	_start_sound = AudioStreamPlayer.new()
	_start_sound.stream = load("res://sounds/start.wav")
	_start_sound.volume_db = START_VOLUME_DB
	add_child(_start_sound)


func _physics_process(_delta: float) -> void:
	if _started or not Input.is_action_just_pressed("jump"):
		return
	_started = true
	_music.stop()
	_start_sound.play()
	await _start_sound.finished
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _exit_tree() -> void:
	_music.stop()
	_music.stream = null
