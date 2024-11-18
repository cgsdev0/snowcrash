extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var cam = $Camera3D
const ray_length = 6.0

var extension = 0.0
var casting = false

func extend(f: float):
	$Grapple/Rope.height = f
	$Grapple/Rope.position.z = -f / 2.0
	$Grapple/Hook.position.z = -f

func aim(target: Vector3):
	$Grapple.look_at(target)
	$Grapple/Hook.monitoring = true
	casting = true

func _process(delta):
	return
	if casting:
		extension += delta * 20.0
		extension = clampf(extension, 0.0, 6.0)
		extend(extension)
	
func raycast_from_mouse(m_pos, collision_mask):
	var ray_start = cam.project_ray_origin(m_pos)
	var ray_end = ray_start + cam.project_ray_normal(m_pos) * ray_length
	var world3d : World3D = get_world_3d()
	var space_state = world3d.direct_space_state
	
	if space_state == null:
		return
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	if result && result.position:
		var attach = Attach.instantiate()
		hooked = attach
		result.collider.add_child(attach)
		attach.global_position = result.position
		print("hooked!", result.collider)
		return result.position
	return ray_end
	
func _unhandled_input(event):
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == 1:
			if hooked:
				hooked.queue_free()
				hooked = null
				return
			extension = 0.0
			var a = raycast_from_mouse(get_window().get_mouse_position(), 4)
			var dist = global_position.distance_to(a)
			aim(a)

func cap_correction(c: Vector3, delta):
	if c.length() > 0.3 * delta:
		return c.normalized() * 0.3 * delta
	return c
		
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y += JUMP_VELOCITY

	var turn_dir = Input.get_vector("ui_left", "ui_right", "ui_left", "ui_right")
	rotate_y(-turn_dir.x * delta * 4.0)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var skater_pos = global_position
	
	if hooked:
		var car_pos = hooked.global_position
		var d = car_pos - skater_pos
		if d.length() > 6.0:
			d = d.normalized() * (d.length() - 6.0)
			velocity += d * delta * 5.0
			var dot = velocity.dot(d.normalized())
			if dot < 0.0:
				velocity -= d.normalized() * dot * delta * 5.0
			
	
	var forward = velocity
	forward.y = 0.0
	forward = forward.normalized()
	look_at(global_position + forward)
	velocity += direction * delta * SPEED
	# friction
	velocity = velocity.move_toward(Vector3.ZERO, delta * 0.4)
	if velocity.length() > 7.0:
		velocity = velocity.normalized() * 7.0
	move_and_slide()
			
var Attach = preload("res://hook_attach.tscn")
var hooked = null
func _on_hook_body_entered(body):
	return
	if !hooked && casting:
		hooked = body
		casting = false
		var attach = Attach.instantiate()
		body.add_child(attach)
		attach.global_position = $Grapple/Hook.global_position
		print("hooked!", body)
	pass # Replace with function body.
