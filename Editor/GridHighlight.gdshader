shader_type canvas_item;

uniform float grid_size = 32.0;
uniform float line_thickness = 1.0;
uniform vec4 line_color : source_color = vec4(vec3(0.8), 1.0);
uniform vec2 mouse_position;
uniform vec2 mouse_offset = vec2(0.0, 0.0);
uniform vec2 grid_offset = vec2(0.0, 0.0);
uniform float fade_radius = 50.0;

varying vec2 world_position;

// --- Helper Functions ---

float grid(vec2 position, float size, float thickness) {
    vec2 cell_coord = (position + grid_offset) / size;
    vec2 grid_uv = abs(fract(cell_coord) - 0.5) * 2.0;

    vec2 aa = fwidth(grid_uv);
    vec2 line_width = vec2(thickness) / size;

    vec2 grid_value = 1.0 - smoothstep(line_width - aa, line_width + aa, grid_uv);
    return mix(grid_value.x, 1.0, grid_value.y);
}

float box_dist(vec2 p) {
    return max(abs(p.x), abs(p.y));
}

// --- Main Shader Functions ---

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
    VERTEX = VERTEX;
}

void fragment() {
    float grid_mask = grid(world_position, grid_size, line_thickness);

    // Calculate the distance to the mouse cursor
    vec2 dist_vec = world_position - mouse_position + mouse_offset;
    float dist = box_dist(dist_vec) / fade_radius;

    // Invert the distance so 0 is at the center and 1 is at the edge
    float inverted_dist = clamp(1.0 - dist, 0.0, 1.0);

    // Apply the quadratic fade effect
    // pow(x, 2.0) creates a quadratic curve
    float fade_alpha = (clamp(-(0.8 * pow(inverted_dist - 1.0, 2.0)) + 1.0,0.0,0.9) + 0.03);

    // Apply the final alpha to the color, clamped and offset
    COLOR.rgb = line_color.rgb;
    COLOR.a = fade_alpha * grid_mask;
    COLOR.a = fade_alpha * grid_mask;
}