extends Node3D

var ramp_enabled = false
var off_side = 0.0
var passed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$OffRamp.use_collision = false
	$Police/Area3D.monitorable = false
	$Police/Area3D.monitoring = false
	$Police.hide()
	$OffRamp.hide()
	if ramp_enabled:
		_enable_ramp()
	else:
		$OffRamp.queue_free()

func enable_ramp(a):
	ramp_enabled = true
	off_side = a

func _enable_ramp():
	$Police/Area3D.monitorable = true
	$Police/Area3D.monitoring = true
	$Police.show()
	var edge = get_node("../edge_F") if off_side > 0.0 else get_node("../edge_R")
	var center = get_node("../edge_C")
	var ramp = $OffRamp
	var pos =  edge.global_position + edge.curve.sample_baked(0.7 * edge.curve.get_baked_length()).rotated( Vector3.UP, global_rotation.y)
	var cpos =  center.global_position + center.curve.sample_baked(0.0).rotated( Vector3.UP, global_rotation.y)
	ramp.global_position = pos
	$Police.global_position = cpos
	ramp.use_collision = true
	ramp.show()
	if off_side > 0.0:
		$GuardF.queue_free()
		ramp.global_position -= global_basis.x
	else:
		ramp.rotation.y *= -1.0
		ramp.global_position += global_basis.x
		$GuardR.queue_free()


func _on_area_3d_body_entered(body):
	body.arrest()
