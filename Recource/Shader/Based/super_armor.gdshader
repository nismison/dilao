shader_type canvas_item;

// 霸体效果参数
uniform float outline_width : hint_range(0.0, 10.0) = 3.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.8, 0.0, 1.0); // 金黄色描边
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.3, 0.8); // 发光颜色

// 动画控制参数
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0; // 脉冲速度
uniform float pulse_intensity : hint_range(0.0, 2.0) = 0.5; // 脉冲强度
uniform float glow_strength : hint_range(0.0, 3.0) = 1.5; // 发光强度

// 边缘发光参数
uniform float edge_glow_width : hint_range(0.0, 20.0) = 8.0; // 边缘发光宽度
uniform float edge_softness : hint_range(0.1, 5.0) = 2.0; // 边缘柔和度

// 能量波动效果
uniform float wave_frequency : hint_range(0.5, 10.0) = 3.0; // 波动频率
uniform float wave_amplitude : hint_range(0.0, 1.0) = 0.3; // 波动幅度

varying vec2 world_position;

void vertex() {
    world_position = VERTEX;
}

// 获取纹理在指定偏移处的透明度
float get_alpha_at_offset(vec2 uv, vec2 offset, vec2 texture_pixel_size) {
    vec2 sample_uv = uv + offset * texture_pixel_size;
    if (sample_uv.x < 0.0 || sample_uv.x > 1.0 || sample_uv.y < 0.0 || sample_uv.y > 1.0) {
        return 0.0;
    }
    return texture(TEXTURE, sample_uv).a;
}

// 计算描边
float calculate_outline(vec2 uv, vec2 texture_pixel_size, float dynamic_width) {
    vec4 current_color = texture(TEXTURE, uv);
    
    if (current_color.a > 0.5) {
        return 0.0; // 内部像素不需要描边
    }
    
    // 检查周围像素是否有不透明部分
    float outline_alpha = 0.0;
    int samples = 8;
    
    for (int i = 0; i < samples; i++) {
        float angle = float(i) * 6.28318 / float(samples);
        vec2 offset = vec2(cos(angle), sin(angle)) * dynamic_width;
        outline_alpha = max(outline_alpha, get_alpha_at_offset(uv, offset, texture_pixel_size));
    }
    
    return outline_alpha;
}

// 计算边缘发光
float calculate_edge_glow(vec2 uv, vec2 texture_pixel_size) {
    vec4 current_color = texture(TEXTURE, uv);
    
    if (current_color.a > 0.1) {
        return 0.0; // 只在透明区域产生发光
    }
    
    float min_distance = edge_glow_width;
    int samples = 12; // 减少采样数量以提高性能
    
    // 寻找最近的不透明像素
    for (int i = 0; i < samples; i++) {
        float angle = float(i) * 6.28318 / float(samples);
        
        for (float dist = 1.0; dist <= edge_glow_width; dist += 1.0) {
            vec2 offset = vec2(cos(angle), sin(angle)) * dist;
            float alpha = get_alpha_at_offset(uv, offset, texture_pixel_size);
            
            if (alpha > 0.5) {
                min_distance = min(min_distance, dist);
                break;
            }
        }
    }
    
    if (min_distance >= edge_glow_width) {
        return 0.0;
    }
    
    // 计算发光强度，距离越近越亮
    float glow_intensity = 1.0 - (min_distance / edge_glow_width);
    return smoothstep(0.0, 1.0, pow(glow_intensity, edge_softness));
}

void fragment() {
    // 计算纹理像素大小
    vec2 texture_pixel_size = SCREEN_PIXEL_SIZE;
    
    vec4 original_color = texture(TEXTURE, UV);
    
    // 时间变量用于动画
    float time = TIME;
    
    // 计算脉冲效果
    float pulse = sin(time * pulse_speed) * 0.5 + 0.5;
    float enhanced_pulse = pulse * pulse_intensity + (1.0 - pulse_intensity);
    
    // 计算波动效果
    float wave_offset = sin(time * wave_frequency + UV.x * 10.0 + UV.y * 8.0) * wave_amplitude;
    float dynamic_outline_width = outline_width * (enhanced_pulse + wave_offset);
    
    // 计算描边
    float outline_alpha = calculate_outline(UV, texture_pixel_size, dynamic_outline_width);
    
    // 计算边缘发光
    float edge_glow = calculate_edge_glow(UV, texture_pixel_size);
    
    // 动态调整发光颜色
    vec4 dynamic_glow_color = glow_color;
    dynamic_glow_color.rgb *= (enhanced_pulse * glow_strength + 0.5);
    
    vec4 dynamic_outline_color = outline_color;
    dynamic_outline_color.rgb *= enhanced_pulse;
    
    // 混合最终颜色
    vec4 final_color = original_color;
    
    // 添加描边
    if (outline_alpha > 0.0 && original_color.a <= 0.5) {
        final_color = mix(final_color, dynamic_outline_color, outline_alpha * dynamic_outline_color.a);
        final_color.a = max(final_color.a, outline_alpha * dynamic_outline_color.a);
    }
    
    // 添加边缘发光
    if (edge_glow > 0.0) {
        vec4 glow_contribution = dynamic_glow_color * edge_glow;
        final_color.rgb += glow_contribution.rgb * glow_contribution.a;
        final_color.a = max(final_color.a, glow_contribution.a);
    }
    
    // 为原始像素添加轻微的能量波动效果
    if (original_color.a > 0.5) {
        float energy_boost = pulse * 0.2 + 0.8;
        final_color.rgb *= energy_boost;
    }
    
    COLOR = final_color;
}