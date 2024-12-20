extends Node3D


enum DriveState {
	PARK,
	AUTO
}

var lanes = 1
var my_lane = 0
var total_lanes = 0
var lane_dir = 1

var container: RoadContainer = null

@export var drive_state: DriveState = DriveState.AUTO

# Target speed in meters per second
@export var acceleration := 4.0 # in meters per sec squared
@export var target_speed := 13  # in meters per sec
@export var lane_adj := 1.2  # in meters per sec
@export var visualize_lane := false
@export var seek_ahead := 1.0 # How many meters in front of agent to seek position
@export var auto_register: bool = true

@onready var agent = $RoadLaneAgent

var velocity := Vector3.ZERO

func get_lane_idx():
	if lane_dir == 1:
		return (total_lanes - lanes) + my_lane
	return my_lane

var variations = [
	preload("res://models/car_prefabs/fast_car.tscn"),
	preload("res://models/car_prefabs/flat_car.tscn"),
	preload("res://models/car_prefabs/truck_beeg.tscn"),
	preload("res://models/car_prefabs/tiny_van.tscn")
]

var main_weights = [
	2,
	2,
	1,
	3
]

var f0_weights = [
	2,
	2,
	0,
	3
]

func weighted_pick(array, weights):
	weights
	var total_weight = weights.reduce(func(sum, n = 0): return sum + n)
	var random := randi_range(0, total_weight)
	var accumulated_weight = 0
	for i in weights.size():
		accumulated_weight += weights[i]
		if random < accumulated_weight: return array[i]
	return array[-1]

var audio
var honked = false
func _ready() -> void:
	if randi_range(0, 2) == 0: # polite driver rng
		honked = true
	agent.visualize_lane = visualize_lane
	agent.auto_register = auto_register
	var pick = null
	if my_lane == 0 && lane_dir == 1:
		pick = weighted_pick(variations, f0_weights)
	else:
		pick = weighted_pick(variations, main_weights)
	
	var n = pick.instantiate()
	add_child(n)
	audio = n.get_node("Honk")
	$RayCast3D.position = n.get_node("Marker3D").position
	$RayCast3D2.position = n.get_node("Marker3D").position
	$HonkCast.position = n.get_node("Marker3D").position
	# print("Agent state: %s par, %s lane, %s manager" % [
	# 	agent.actor, agent.current_lane, agent.road_manager
	# ])


## Generic function to calc speed
func get_velocity() -> float:
	return velocity.z


func _physics_process(delta: float) -> void:
	velocity.y = 0
	var target_dir = Vector3.FORWARD
	var adjusted_speed = target_speed + (lanes - my_lane) * lane_adj
	var target_velz = 0.0
	
	if $HonkCast.is_colliding() && !honked:
		honked = true
		audio.play()
		EventBus.add_to_stat("honks", 1)
		
	if $RayCast3D.is_colliding() || $RayCast3D2.is_colliding():
		target_velz = move_toward(velocity.z, 0.0, delta * acceleration)
	else:
		target_velz = move_toward(velocity.z, target_dir.z * adjusted_speed, delta * acceleration)
	velocity.z = target_velz

	if not is_instance_valid(agent.current_lane):
		var res = agent.assign_nearest_lane()
		if not res == OK:
			print("Failed to find new lane")
			return

	# Find the next position to jump to; note that the car's forward is the
	# negative Z direction (conventional with Vector3.FORWARD), and thus
	# we flip the direction along the Z axis so that positive move direction
	# matches a positive move_along_lane call, while negative would be
	# going in reverse in the lane's intended direction.
	var move_dist = -velocity.z * delta
	var next_pos:Vector3 = global_position
	if move_dist > 0.0:
		next_pos = agent.move_along_lane(move_dist)
	# Get another point a little further in front for orientation seeking,
	# without actually moving the vehicle (ie don't update the assign lane
	# if this margin puts us into the next lane in front)
	var test_next = agent.test_move_along_lane(1.0)
	if next_pos != global_position:
		look_at(next_pos)
		global_position = next_pos
	elif test_next != Vector3.ZERO && test_next != global_position:
		look_at(test_next)
		
	if next_pos == Vector3.ZERO:
		queue_free()
		# var lane = container.get_node(container.edge_rp_locals[0]).prior_seg.get_lanes()[get_lane_idx()]
		# agent.assign_lane(lane)
		# global_transform.origin = lane.to_global(Vector3.ZERO)
