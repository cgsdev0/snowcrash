extends Node


var RoadNode = preload("res://roads/road_node.gd")
# Called when the node enters the scene tree for the first time.
var connections = []

func _ready():
	var prev = null
	for i in range(10):
		var node = Node3D.new()
		node.set_script(RoadNode)
		add_child(node)
		node.position.z += i * 2.0
		if prev:
			connections.push_back([prev, node])
		prev = node
	prev = null
	for i in range(10):
		if i == 4:
			connections.push_back([prev, get_child(4)])
			prev = get_child(4)
			continue
		var node = Node3D.new()
		node.set_script(RoadNode)
		add_child(node)
		node.position.z += 8.0
		node.position.x += (i - 4) * 2.0
		if prev:
			connections.push_back([prev, node])
		prev = node


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for c in connections:
		var a = c[0]
		var b = c[1]
		DebugDraw3D.draw_line(a.global_position, b.global_position, Color.BLUE)
	pass
