@tool
extends Node3D

@onready var state_machine = $AnimationTree["parameters/playback"]

func _ready():
	state_machine.travel("idle")

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		ragdoll()
		
func ragdoll():
	$Armature/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
	for physical_bone in $Armature/Skeleton3D/PhysicalBoneSimulator3D.get_children():
		PhysicsServer3D.body_set_state(physical_bone.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, get_parent().get_parent().velocity)

func get_hand():
	return $RightHand
