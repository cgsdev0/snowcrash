extends Node

signal jail(visible)
signal restart
signal game_over
signal hide_intro
signal game_start
signal shoot

enum GamePhase {
	MAIN_MENU,
	CREDITS,
	INTRO,
	PLAYING
}

var easter_egg = false
var sad = false
var progress = 0.0
var phase = GamePhase.MAIN_MENU
var stats

func _ready():
	self.restart.connect(on_restart)
	reset_stats()

func add_to_stat(key, val):
	if typeof(val) == TYPE_VECTOR3:
		val = val.length()
	stats[key] += val

func top_stat(key, val):
	stats[key] = max(val, stats[key])

func reset_stats():
	progress = 0.0
	stats = {
		"distance": 0.0,
		"top_speed": 0.0,
		"honks": 0,
		"grapples": 0,
		"ramps": 0,
	}
	
func on_restart():
	phase = GamePhase.INTRO
	reset_stats()
