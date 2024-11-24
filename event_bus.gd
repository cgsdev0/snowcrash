extends Node

signal jail(visible)
signal restart

var progress = 0.0

func _ready():
	self.restart.connect(on_restart)
	
func on_restart():
	progress = 0.0
