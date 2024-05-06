shader_type spatial;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
	ALBEDO = vec3(0.5) - texture(screen_texture, SCREEN_UV).rgb;
	
}
