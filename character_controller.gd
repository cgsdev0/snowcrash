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
const boost_turn_mod = 1.1
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
		hook_target = null
		hooked = null

var whee = 0.0
func _process(delta):
	whee += delta
	$Visual.position.y = sin(whee * 3.0) * 0.03 - 0.3
	if hook_target || hooked:
		extension += delta * 4.0
		if extension > 1.0 && hook_target != null:
			hooked = hook_target
			hook_target = null
	else:
		extension -= delta * 12.0
		if extension < 0.0 && hook_was:
			hook_target = null
			hook_was = null
		
	extension = clampf(extension, 0.0, 1.0)
	
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
		hook_target = attach
		hook_was = attach
		result.collider.add_child(attach)
		attach.global_position = result.position
		grapple_len = (result.position - global_position).length() - 1.0
		grapple_len = max(minimum_grapple, grapple_len)
		print("hooked!", result.collider)
		return result.position
	return ray_end

func can_hook():
	return !hooked && !hook_target && !boosting
	
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
	velocity = minimum_speed * global_basis.z.normalized()



var input_faded = 0.0

var forces = {}

var target_tilt = 0.0

func p(A, v, t, amp):
	var n = v.normalized().cross(global_basis.x.normalized())
	return A + t * v + A * n * sin(PI * t) * amp
	
func draw_arc(p1, p2, len, ext):
	var rope = p2 - p1
	if len <= rope.length():
		DebugDraw3D.draw_line(p1, p2, Color.RED)
		return
	
	var d = rope.length()
	var amp = clampf(len - d, 0.0, 0.5)
	for i in range(10):
		var start = p(p1, rope, i / 10.0, amp)
		var end = p(p1, rope, (i + 1) / 10.0, amp)
		DebugDraw3D.draw_line(start, end, Color.RED)

func draw_extended(a, b, l, e):
	var d = b - a
	DebugDraw3D.draw_line(a, a + d * e, Color.ORANGE_RED)
	
func _physics_process(delta):
	# find closest ramp
	var ramps = get_tree().get_nodes_in_group("ramp")
	var min_ramp = null
	var min_dist = 10000.0
	for ramp in ramps:
		var r = ramp.get_parent()
		if r.passed:
			continue
		var dist = global_position.distance_to(r.global_position)
		if dist < 50.0:
			r.passed = true
			continue
		if dist < min_dist:
			min_dist = dist
			min_ramp = r
	%WarnRight.hide()
	%WarnLeft.hide()
	if min_dist < 150.0:
		if min_ramp.off_side > 0.0:
			%WarnRight.show()
		else:
			%WarnLeft.show()
	if extension > 0.0 && hook_was:
		var hand = $Visual/Visual.get_hand()
		draw_extended(hand.global_position, hook_was.global_position, grapple_len, extension)
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
	
	# input limiters
	var left_limit = -1.0
	if $Left.is_colliding():
		var how_deep = ($Left.global_position - $Left.get_collision_point()).length()
		how_deep /= scale.x
		how_deep /= $Left.target_position.length()
		how_deep = -clampf(how_deep - 0.1, 0.0, 1.0)
		left_limit = how_deep
	var right_limit = 1.0
	if $Right.is_colliding():
		var how_deep = ($Right.global_position - $Right.get_collision_point()).length()
		how_deep /= scale.x
		how_deep /= $Right.target_position.length()
		how_deep = clampf(how_deep - 0.1, 0.0, 1.0)
		right_limit = how_deep
	
	var clamped_input = input_faded
	if input_faded < 0.0:
		clamped_input = max(left_limit, input_faded)
	elif input_faded > 0.0:
		clamped_input = min(right_limit, input_faded)
		
	var drag_mult = 0.2
	var pulled = false
	if hooked:
		var rope = (hooked.global_position - global_position)
		var dist = rope.length()
		if dist > grapple_len:
			forces["input"] = global_basis.x * clamped_input * input_ratio * 0.8 * grapple_len / 20.0
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
		forces["input"] = global_basis.x * clamped_input * input_ratio
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
		#DebugDraw3D.draw_arrow(global_position, global_position + forces[force], Color.RED, 0.1)
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
		var col_ang = collision.get_angle()
		var col_vel = collision.get_collider_velocity()
		var diff = rad_to_deg(angle_difference(velocity_xz.angle(), col_ang))
		var col_normal = collision.get_normal()
		var dot = velocity.normalized().dot(col_normal)
		print({"ang": col_ang, "vel": col_vel, "diff": diff, "dot": dot})
		var normal_xz = Vector3(col_normal.x, 0.0, col_normal.z).normalized()
		if abs(dot) > 0.5:
			# if collision.get_collider().is_in_group("guard"):
			var new_v = velocity.slide(col_normal)
			new_v.y = 0.0
			velocity = new_v.normalized() * velocity.length()
			move_and_collide(collision.get_remainder().length() * velocity * delta)
			print("ded")
		else:
			var new_v = velocity.slide(col_normal)
			new_v.y = 0.0
			velocity = new_v.normalized() * velocity.length()
			move_and_collide(collision.get_remainder().length() * velocity * delta)
	# move_and_slide()
			
var Attach = preload("res://hook_attach.tscn")
var hooked = null
var hook_target = null
var hook_was = null

func _on_boost_timer_timeout():
	boosting = false


func _on_death_box_body_entered(body):
	print("damage")
	pass # Replace with function body.
