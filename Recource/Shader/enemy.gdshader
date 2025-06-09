/* 
合并的闪白+描边shader
基于 flash_white.gdshader 和 ghost_shine.gdshader
*/
shader_type canvas_item;

// 闪白效果参数
uniform bool flash = false;
uniform float flash_strength = 1.0;

// 描边效果参数
uniform bool enable_outline = false;  // 控制是否启用描边效果
uniform bool shain = false; //Activate the rainbow or select you color
uniform bool onecolor = false; //Activate the rainbow or select you color
uniform vec4 line_color = vec4(1.0, 1.0, 1.0, 1.0);//color line
uniform float line_scale : hint_range(0, 1.5) = 1.0;    // thickness of the line
uniform float shadow : hint_range(0, 1.6) = 1.6;    // shadow lenght
uniform float shadow_mult : hint_range(0, 1.6) = 1.6;    // shadow alpha
uniform float frequency : hint_range(0.0, 5.0) = 2;  // frequency of the shine
uniform float transparency: hint_range(0.0, 5.0) = 0;  // transparency of shadow/if you use a onecolor please up the transparency

void fragment() {
	// 获取原始颜色
	vec4 color = texture(TEXTURE, UV);
	vec4 final_color = color;
	
	// 应用闪白效果
	if (flash) {
		// 仅对 RGB 混合，不改 alpha
		vec3 mixed_rgb = mix(color.rgb, vec3(1.0), flash_strength);
		final_color = vec4(mixed_rgb, color.a);
	}
	
	// 应用描边效果
	if (enable_outline) {
		float alpha = 0.6;
		vec2 size = TEXTURE_PIXEL_SIZE * line_scale;
		
		// 计算描边
		float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
		outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
		outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
		outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
		outline = min(outline, shadow * shadow_mult);
		
		// 计算描边强度（只在透明区域显示描边）
		float outline_factor = outline * (1.0 - color.a);
		
		// 不同的描边颜色模式
		vec4 animated_line_color = vec4(0.5 + sin(2.0*3.14*frequency*TIME),
								   0.5 + sin(2.0*3.14*frequency*TIME + radians(120.0)) + transparency,
								   0.5 + sin(2.0*3.14*frequency*TIME + radians(240.0)),
								   alpha);
		
		vec4 one_color = vec4(line_color.r * sin(frequency*2.0*TIME) + line_color.r - 0.2,
								   line_color.g * sin(frequency*2.0*TIME) + line_color.g - 0.2,
								   line_color.b * sin(frequency*2.0*TIME) + line_color.b - 0.2,
								   alpha) + vec4(line_color.r, line_color.g, line_color.b, 0);
		
		vec4 static_color = vec4(line_color.r, line_color.g, line_color.b, alpha);
		
		// 根据设置选择描边颜色
		vec4 final_outline_color;
		if (onecolor) {
			final_outline_color = one_color * transparency;
		} else if (shain) {
			final_outline_color = animated_line_color;
		} else {
			final_outline_color = static_color;
		}
		
		// 混合描边到最终颜色
		final_color = final_color + final_outline_color * outline_factor;
	}
	
	COLOR = final_color;
}