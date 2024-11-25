extends Node

signal jail(visible)
signal restart
signal game_over
signal hide_intro
signal game_start

enum GamePhase {
	MAIN_MENU,
	CREDITS,
	INTRO,
	PLAYING
}

var progress = 0.0
var phase = GamePhase.MAIN_MENU

func _ready():
	self.restart.connect(on_restart)
	
func on_restart():
	progress = 0.0
	phase = GamePhase.INTRO
