shader_type canvas_item;

uniform vec2 circle_pos = vec2(0.5, 0.5); // normalized (0-1)
uniform float circle_radius = 0.2;

void fragment() {
    vec2 uv = UV;
    vec4 rect_color = vec4(0.0, 0.0, 0.0, 1.0);
    
    // Distance from center
    float dist = distance(uv, circle_pos);
    
    if (dist < circle_radius) {
        rect_color.a = 0.0; // transparent in circle
    }
    
    COLOR = rect_color;
}
