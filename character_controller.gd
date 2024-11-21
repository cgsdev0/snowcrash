extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var cam = $Camera3D
const ray_length = 30.0

const minimum_grapple = 5.0
const boost_amt = 12.0
const minimum_speed = 12.0
const maximum_speed = 40.0
const drag = 4.0
const drag_range = 0.15
const spring_constant = 200.0
const input_ratio = 4.0
const boost_turn_mod = 1.4
const boost_speed_mod = 2.0

var speed_mod = 1.0
var boosting = false
var extension = 0.0
var grapple_len = 12.0
var casting = false

func extend(f: float):
	$Grapple/Rope.height = f
	$Grapple/Rope.position.z = -f / 2.0
	$Grapple/Hook.position.z = -f

func aim(target: Vector3):
	$Grapple.look_at(target)
	$Grapple/Hook.monitoring = true
	casting = true

func start_boost():
	if boosting:
		return
	$BoostTimer.start()
	boosting = true
	
func break_grapple():
	if hooked && is_instance_valid(hooked):
		hooked.queue_free()
		hooked = null

var whee = 0.0
func _process(delta):
	whee += delta
	$Visual.position.y = sin(whee * 3.0) * 0.03 - 0.3
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
		grapple_len = (result.position - global_position).length() - 2.0
		grapple_len = max(minimum_grapple, grapple_len)
		print("hooked!", result.collider)
		return result.position
	return ray_end
	
func _unhandled_input(event):
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == 1:
			if hooked:
				break_grapple()
				var t = forces.get("tension", Vector3.ZERO)
				if t.length() > 0.0:
					var dot = t.normalized().dot(velocity.normalized())
					print(dot)
					if dot > 0.5:
						start_boost()
				var new_speed = velocity.length()
				var dir = (-global_basis.z.normalized() + velocity.normalized()).normalized()
				velocity = new_speed * velocity.normalized()
				return
			if boosting:
				return
			extension = 0.0
			var a = raycast_from_mouse(get_window().get_mouse_position(), 4)
			var dist = global_position.distance_to(a)
			aim(a)

func _ready():
	velocity = minimum_speed * global_basis.z



var input_faded = 0.0

var forces = {}

var target_tilt = 0.0
	
func _physics_process(delta):
	if boosting:
		speed_mod = move_toward(speed_mod, boost_speed_mod, delta * 5.0)
	else:
		speed_mod = move_toward(speed_mod, 1.0, delta * 0.5)

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y += JUMP_VELOCITY

	var turn_dir = Input.get_axis("move_left", "move_right")
	if turn_dir:
		input_faded = move_toward(input_faded, turn_dir, delta * 3.0)
	else:
		input_faded = move_toward(input_faded, 0.0, delta * 5.0)
	
	var acceleration = Vector3.ZERO
	
	forces["input"] = Vector3.ZERO
	forces["tension"] = Vector3.ZERO
	forces["friction"] = Vector3.ZERO
		
	var drag_mult = 0.2
	var pulled = false
	if hooked:
		var rope = (hooked.global_position - global_position)
		var dist = rope.length()
		if dist > grapple_len:
			forces["input"] = global_basis.x * input_faded * input_ratio * 0.8 * grapple_len / 20.0
			var moving = Vector2(rope.x, -rope.z).angle()
			pulled = true
			global_rotation.y = rotate_toward(global_rotation.y, moving - PI / 2.0, delta)
			var delta_x = dist - grapple_len
			forces["tension"] = rope.normalized() * delta_x * spring_constant / 50.0 * grapple_len / 5.0
			if forces["tension"].length() > 50.0:
				print("BREAKING! ", forces["tension"].length())
				break_grapple()
			drag_mult = abs(rope.dot(global_basis.z)) * drag_range + 0.2
		else:
			grapple_len = max(minimum_grapple, dist)
	if !pulled:
		forces["input"] = global_basis.x * input_faded * input_ratio
		if boosting:
			forces["input"] *= boost_turn_mod * speed_mod
		var moving = Vector2(velocity.x, -velocity.z).angle()
		global_rotation.y = rotate_toward(global_rotation.y, moving - PI / 2.0, delta)
	var velocity_xz = Vector2(velocity.x, velocity.z)
	forces["friction"] = -velocity_xz.normalized() * drag * drag_mult
	if forces["friction"].length() > velocity_xz.length():
		forces["friction"] = forces["friction"].normalized() * velocity_xz.length()
	forces["friction"] = Vector3(forces["friction"].x, 0.0, forces["friction"].y)
	for force in forces:
		DebugDraw3D.draw_arrow(global_position, global_position + forces[force], Color.RED, 0.1)
		acceleration += forces[force]
	acceleration.y = 0.0
	velocity += acceleration * delta
	
	# gravity and ground force
	if $Gravity.is_colliding():
		var how_deep = ($Gravity.global_position - $Gravity.get_collision_point()).y
		how_deep /= scale.x
		how_deep /= $Gravity.target_position.length()
		velocity.y += (exp(1 - how_deep + 1) - 3.0) * delta * 100.0
		velocity.y -= 10.0 * velocity.y * delta
		if $Gravity.get_collider().is_in_group("ramp"):
			start_boost()
		var n = $Gravity.get_collision_normal()
		var g = n
		g.y = 0.0
		var angle = n.angle_to(g)
		target_tilt = -angle / 2.0
		$Visual.rotation.z = lerp_angle($Visual.rotation.z, target_tilt, delta * 3.0)
	else:
		target_tilt = move_toward(target_tilt, 0.0, delta * 2.0)
		$Visual.rotation.z = lerp_angle($Visual.rotation.z, target_tilt, delta)
		velocity.y -= 9.8 * delta
	
	if velocity.length() < minimum_speed:
		velocity = velocity.normalized() * minimum_speed
	velocity = velocity.limit_length(maximum_speed)
	var modded = Vector3(velocity.x * speed_mod, velocity.y, velocity.z * speed_mod)
	var collision = move_and_collide(modded * delta)
	if collision:
		input_faded *= -1.0
		var col_ang = collision.get_angle()
		var col_vel = collision.get_collider_velocity()
		var diff = rad_to_deg(angle_difference(velocity_xz.angle(), col_ang))
		var col_normal = collision.get_normal()
		var dot = velocity.normalized().dot(col_normal)
		print({"ang": col_ang, "vel": col_vel, "diff": diff, "dot": dot})
		if abs(diff) >= 90.0 || abs(dot) > 0.7:
			set_collision_layer_value(1, false)
			set_collision_mask_value(1, false)
			var new_v = velocity.slide(collision.get_normal())
			velocity.x = new_v.x
			velocity.z = new_v.z
			print("ded")
		else:
			var new_v = velocity.bounce(collision.get_normal())
			velocity.x = new_v.x
			velocity.z = new_v.z
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


func _on_boost_timer_timeout():
	boosting = false
