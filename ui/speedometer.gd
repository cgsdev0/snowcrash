extends Control

@onready var clip: AtlasTexture = $TextureProgressBar2/ColorRect.texture
@export var start = 0.0
@export var end = 0.0
@onready var bar = $RealBar
@onready var label = $RealBar/Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if EventBus.phase != EventBus.GamePhase.PLAYING:
		hide()
		return
	show()
	bar.set_value(EventBus.speed)
	var ratio = float(bar.value - bar.min_value) / float(bar.max_value - bar.min_value)
	label.text = str(floor(EventBus.speed))
	clip.region.position.x = (1.0 - ratio) * (start - end) + end
