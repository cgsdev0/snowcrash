extends Camera3D


@onready var to = $"../CameraPos2"
@onready var from = $"../CameraPos2/CameraPos"

# Called when the node enters the scene tree for the first time.
func _ready():
	look_at_from_position(from.global_position, to.global_position)
	EventBus.restart.connect(on_restart)
	pass # Replace with function body.

var adjust = Vector3.ZERO

func on_restart():
	look_at_from_position(from.global_position, to.global_position)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if get_parent().ragdolling:
		var target = get_parent().get_ragdoll_center().global_position
		look_at(target)
		return
	var world3d : World3D = get_world_3d()
	var space_state = world3d.direct_space_state
	
	if space_state == null:
		return
	
	var query = PhysicsRayQueryParameters3D.create(from.global_position, to.global_position, 1 << 9)
	query.hit_from_inside = true
	query.hit_back_faces = true
	var result = space_state.intersect_ray(query)
	if result:
		adjust = adjust.move_toward(Vector3.UP, delta * 2.0)
	else:
		adjust = adjust.move_toward(Vector3.ZERO, delta * 2.0)
	global_position = global_position.lerp(from.global_position + adjust, delta * 10.0)
	look_at(to.global_position)
