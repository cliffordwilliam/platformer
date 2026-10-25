class_name Sounds
extends Node
## The sound effects of a level, one player each. Runs while paused, so
## the hurt, death and win sounds play during the pause.

enum Effect { JUMP, STOMP, KICK, COIN, DIAMOND, HEAL, BREAK, BUMP, SPRING, HURT, DEATH, CHECKPOINT, WIN }

const VOLUME_DB: Dictionary[Effect, float] = {
	Effect.JUMP: 1.5,
	Effect.STOMP: 8.7,
	Effect.KICK: -2.6,
	Effect.COIN: -2.3,
	Effect.DIAMOND: -0.4,
	Effect.HEAL: 4.3,
	Effect.BREAK: -5.8,
	Effect.BUMP: 2.7,
	Effect.SPRING: -1.2,
	Effect.HURT: 2.4,
	Effect.DEATH: 4.0,
	Effect.CHECKPOINT: 9.6,
	Effect.WIN: 5.2,
}

var level: Level
var _players: Dictionary[Effect, AudioStreamPlayer] = {}


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	process_mode = PROCESS_MODE_ALWAYS
	for effect_name: String in Effect.keys():
		var effect: Effect = Effect[effect_name]
		var player := AudioStreamPlayer.new()
		player.name = effect_name.capitalize()
		player.stream = load("res://sounds/%s.wav" % effect_name.to_lower())
		player.volume_db = VOLUME_DB[effect]
		player.process_mode = PROCESS_MODE_ALWAYS
		add_child(player)
		_players[effect] = player


func play(effect: Effect) -> void:
	_players[effect].play()


func play_and_wait(effect: Effect) -> void:
	_players[effect].play()
	await _players[effect].finished


func wait(effect: Effect) -> void:
	if _players[effect].playing:
		await _players[effect].finished


func is_playing(effect: Effect) -> bool:
	return _players[effect].playing
