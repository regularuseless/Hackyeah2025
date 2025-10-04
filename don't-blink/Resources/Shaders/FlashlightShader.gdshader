shader_type canvas_item;

uniform vec2 circle_center = vec2(0.5, 0.5);
uniform float radius = 0.3;

void fragment() {
    vec2 uv = FRAGCOORD.xy / vec2(SCREEN_PIXEL_SIZE) / vec2(1.0);
    float dist = distance(uv, circle_center);
    if (dist < radius) {
        COLOR.a = 0.0; // transparent inside the circle
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0); // opaque outside
    }
}
