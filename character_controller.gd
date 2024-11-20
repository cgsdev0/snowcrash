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

var drag = 8.0
var drag_range = 0.2
var spring_constant = 200.0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		# velocity += get_gravity() * delta
		pass
	else:
		velocity.y = 0.0
		pass

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y += JUMP_VELOCITY

	var turn_dir = Input.get_vector("ui_left", "ui_right", "ui_left", "ui_right")
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var acceleration = Vector3.ZERO
	
	
	
	var tension = Vector3.ZERO
	var drag_mult = 0.2
	var pulled = false
	if hooked:
		var rope = (hooked.global_position - global_position)
		var dist = rope.length()
		if dist > 6.0:
			var moving = Vector2(rope.x, -rope.z).angle()
			pulled = true
			global_rotation.y = rotate_toward(global_rotation.y, moving - PI / 2.0, delta)
			var delta_x = dist - 6.0
			tension = rope.normalized() * delta_x * spring_constant / 50.0
			DebugDraw3D.draw_arrow(global_position, global_position + tension, Color.GREEN, 0.1)
			drag_mult = abs(rope.dot(global_basis.z)) * drag_range + 0.2
	if !pulled:
		var moving = Vector2(velocity.x, -velocity.z).angle()
		global_rotation.y = rotate_toward(global_rotation.y, moving - PI / 2.0, delta)
	var velocity_xz = Vector2(velocity.x, velocity.z)
	var friction = -velocity_xz.normalized() * drag * drag_mult
	if friction.length() > velocity_xz.length():
		friction = friction.normalized() * velocity_xz.length()
	friction = Vector3(friction.x, 0.0, friction.y)
	DebugDraw3D.draw_arrow(global_position, global_position + friction, Color.RED, 0.1)
	acceleration += tension
	acceleration += friction
	velocity += acceleration * delta
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		velocity.y = 0.0
	# move_and_slide()
			
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
