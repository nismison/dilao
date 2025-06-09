shader_type canvas_item;

uniform bool flash = false;
uniform float flash_strength = 1.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	if (flash) {
		// 仅对 RGB 混合，不改 alpha
		vec3 mixed_rgb = mix(tex_color.rgb, vec3(1.0), flash_strength);
		COLOR = vec4(mixed_rgb, tex_color.a);
	} else {
		COLOR = tex_color;
	}
}
