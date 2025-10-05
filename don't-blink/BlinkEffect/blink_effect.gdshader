shader_type canvas_item;

uniform float blink_progress : hint_range(0.0, 1.0) = 0.0;
uniform float open_margin : hint_range(1.0, 2.0) = 1.3; 
uniform float curvature : hint_range(0.0, 1.0) = 0.3;
uniform float blur_size : hint_range(0.0, 0.1) = 0.05;

void fragment() {
    // --- 1. Remap Coordinates ---
    // Y is -1.0 (top) to 1.0 (bottom).
    float centered_y = (UV.y - 0.5) * 2.0;

    // --- 2. Define the Curve Shape ---
    // This is the offset that makes the eyelids curve.
    float h_pos = (UV.x - 0.5) * 2.0;
    float curve_offset = pow(h_pos, 2.0) * curvature;

    // --- 3. Calculate the Eyelids' Base Vertical Position ---
    // This is the core translation. We move from off-screen to a point *past* the center.
    // The overlap is now built-in by moving to a point slightly beyond zero.
    float base_y = mix(open_margin, -blur_size, blink_progress);

    // --- 4. Define the Final Position of Each Eyelid's Edge ---
    // This is where each eyelid's solid part ends and the blur begins.
    float top_eyelid_edge = -base_y + curve_offset;
    float bottom_eyelid_edge = base_y - curve_offset;

    // --- 5. Calculate Alpha for Each Eyelid Separately ---
    // This is the robust method that avoids the flawed `clamp` logic.
    
    // For the top eyelid, the screen is black (alpha=1.0) if the pixel is above its edge.
    float alpha_top = 1.0 - smoothstep(top_eyelid_edge - blur_size, top_eyelid_edge, centered_y);

    // For the bottom eyelid, the screen is black if the pixel is below its edge.
    float alpha_bottom = smoothstep(bottom_eyelid_edge, bottom_eyelid_edge + blur_size, centered_y);
    
    // The final alpha is the maximum of the two. This correctly combines them without artifacts.
    float final_alpha = max(alpha_top, alpha_bottom);
    
    COLOR = vec4(0.0, 0.0, 0.0, final_alpha);
}