extends Node3D

@onready var state_machine = $AnimationTree["parameters/playback"]

func _ready():
	state_machine.travel("idle")

func get_hand():
	return $RightHand
