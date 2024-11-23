// Linear Depth Shader written by absentSpaghetti
//
// This shader is a part of my tutorial/learning Github repository: https://github.com/absentSpaghetti/Shader-Basics-With-Spaghetti
// Feel free to use, edit and share this shader according to your needs
//
// MIT License 
//
// prerequisites: 

shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform vec4 fog_color : source_color = vec4(0.75);
uniform float depth_fade_distance : hint_range(0.0, 10.0) = 1.0;
uniform float offset : hint_range(0.0, 10.0) = 0.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
	// Depth texture magic
	float depth = texture(depth_texture, SCREEN_UV, 0.0).r;
  	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	float vertical_depth = vertex_y - depth_texture_y - offset;
	
	// Changes the color of geometry behind it as the water gets deeper
	float depth_fade_blend = exp(-vertical_depth / depth_fade_distance);
	depth_fade_blend = clamp(depth_fade_blend, 0.0, 1.0);
	ALBEDO = mix(vec3(0.0), screen_color, depth_fade_blend);
}

// Sources: https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html