shader_type canvas_item;

uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform vec4 outline_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    
    // 采样周围8个方向的像素
    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
    
    // 获取原始像素
    vec4 original = texture(TEXTURE, UV);
    
    // 如果原始像素透明但周围有不透明像素，则绘制描边
    if (original.a == 0.0 && outline > 0.0) {
        COLOR = outline_color;
    } else {
        COLOR = original;
    }
}