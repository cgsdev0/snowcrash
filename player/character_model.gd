extends Node3D

@onready var state_machine = $AnimationTree["parameters/playback"]

func _ready():
	state_machine.travel("idle")

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		ragdoll(Vector3.ZERO)
		
func ragdoll(impulse):
	$Armature/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
	var v = Vector3.ZERO
	if get_parent() && get_parent().get_parent():
		v = get_parent().get_parent().velocity
		print(v)
	for physical_bone: PhysicalBone3D in $Armature/Skeleton3D/PhysicalBoneSimulator3D.get_children():
	#$"Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone mixamorig_Hips".apply_central_impulse(impulse)
		PhysicsServer3D.body_set_state(physical_bone.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, v)

func get_hand():
	return $RightHand
