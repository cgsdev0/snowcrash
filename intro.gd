extends Node3D


var passed = true # lmao
# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.hide_intro.connect(on_hide)
	EventBus.restart.connect(on_show)
	on_show()

func on_show():
	for sign in $Sign2.get_children():
		sign.shuffle()
	show()
	
func on_hide():
	hide()
