shader_type canvas_item;

uniform sampler2D tex : repeat_enable, filter_nearest;
uniform float scale = 1.0;
uniform float speed = 0.7;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 adjusted = UV;
	ivec2 size = textureSize(tex, 0);
	float v = SCREEN_PIXEL_SIZE.y * float(size.y) * scale;
	adjusted.y /= v;
	adjusted.x /= SCREEN_PIXEL_SIZE.x * float(size.x) * scale;
	adjusted.x -= TIME * speed;
	if (UV.y > v ) discard;
	COLOR = texture(tex, adjusted);
	COLOR.a *= (sin(TIME * 5.0) + 1.0) / 4.0 + 0.5;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
