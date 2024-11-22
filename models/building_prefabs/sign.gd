extends Sprite3D


@export var x = 3
@export var y = 3

func shuffle():
	var a: AtlasTexture = texture
	a.region.position.x = a.region.size.x * randi_range(0, x - 1)
	a.region.position.y = a.region.size.y * randi_range(0, y - 1)
