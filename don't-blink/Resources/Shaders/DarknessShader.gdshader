shader_type canvas_item;

uniform vec2 hole_center = vec2(1920.0, 1080.0); // screen pixels
uniform float hole_radius = 120.0;             // pixels
uniform float feather = 8.0;                   // soft edge in pixels
uniform float darkness = 1.0;                 // 0..1, opacity outside the hole

void fragment() {
    // Convert SCREEN_UV (0..1) to pixel coords
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 frag = SCREEN_UV * screen_size;

    float dist = distance(frag, hole_center);
    // 0 inside, 1 outside with a soft transition
    float t = smoothstep(hole_radius - feather, hole_radius + feather, dist);
    // Black overlay with a transparent circular cutout
    COLOR = vec4(0.0, 0.0, 0.0, darkness * t);
}
