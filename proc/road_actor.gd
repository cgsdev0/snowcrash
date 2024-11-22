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
@export var acceleration := 1 # in meters per sec squared
@export var target_speed := 13  # in meters per sec
@export var lane_adj := 0.8  # in meters per sec
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
func _ready() -> void:
	agent.visualize_lane = visualize_lane
	agent.auto_register = auto_register
	add_child(variations.pick_random().instantiate())
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
	var target_velz = lerp(velocity.z, target_dir.z * adjusted_speed, delta * acceleration)
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
	var next_pos:Vector3 = agent.move_along_lane(move_dist)
	# Get another point a little further in front for orientation seeking,
	# without actually moving the vehicle (ie don't update the assign lane
	# if this margin puts us into the next lane in front)
	if next_pos != global_transform.origin:
		look_at(next_pos)
		global_transform.origin = next_pos
	else:
		queue_free()
		# var lane = container.get_node(container.edge_rp_locals[0]).prior_seg.get_lanes()[get_lane_idx()]
		# agent.assign_lane(lane)
		# global_transform.origin = lane.to_global(Vector3.ZERO)
