extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	$OffRamp.use_collision = false

func enable_ramp():
	$OffRamp.use_collision = true
	$OffRamp.show()
	$GuardF.hide()
