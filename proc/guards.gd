extends Node3D

var ramp_enabled = false
var off_side = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	$OffRamp.use_collision = false
	if ramp_enabled:
		_enable_ramp()

func enable_ramp(a):
	ramp_enabled = true
	off_side = a

func _enable_ramp():
	var edge = get_node("../edge_F") if off_side > 0.0 else get_node("../edge_R")
	var ramp = $OffRamp
	var pos =  edge.global_position + edge.curve.sample_baked(0.7 * edge.curve.get_baked_length()).rotated( Vector3.UP, global_rotation.y)
	ramp.global_position = pos
	ramp.use_collision = true
	ramp.show()
	if off_side > 0.0:
		$GuardF.queue_free()
		ramp.global_position -= global_basis.x
	else:
		ramp.rotation.y *= -1.0
		ramp.global_position += global_basis.x
		$GuardR.queue_free()
