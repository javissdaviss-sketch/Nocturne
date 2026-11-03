shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, fog_disabled;

// UVs are centimetres across/down the glass, keeping droplets fly-sized.
uniform vec4 glass_tint : source_color = vec4(0.025, 0.07, 0.085, 0.035);
uniform vec3 rain_tint : source_color = vec3(0.35, 0.58, 0.65);

float hash21(vec2 p) {
 return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Returns the bead body, its narrow wet trail, and the bright meniscus.
vec3 rain_layer(vec2 glass_uv, float scale, float layer_seed, float rate) {
 vec2 p = glass_uv * scale + vec2(layer_seed * 17.3, layer_seed * 5.1);
 float column = floor(p.x);
 float speed = rate * mix(0.45, 1.2, hash21(vec2(column, layer_seed)));
 p.y -= TIME * speed;
 vec2 cell = floor(p);
 vec2 local = fract(p);
 float seed = hash21(cell + layer_seed);
 float alive = step(0.48, seed);
 float center_x = 0.28 + 0.44 * hash21(cell + 7.0);
 // Slight wandering channels, rather than a uniform scrolling rain texture.
 float wander = sin(local.y * 6.0 + seed * 18.0) * 0.014;
 vec2 delta = local - vec2(center_x + wander, 0.64);
 float radius = length(delta / vec2(0.038, 0.085));
 float bead = (1.0 - smoothstep(0.78, 1.0, radius)) * alive;
 float rim = smoothstep(0.50, 0.80, radius) * (1.0 - smoothstep(0.85, 1.1, radius));
 rim *= (0.40 + 0.60 * smoothstep(-0.03, 0.03, delta.x)) * alive;
 float tail = (1.0 - smoothstep(0.004, 0.014, abs(delta.x)));
 tail *= smoothstep(0.10, 0.50, local.y) * (1.0 - smoothstep(0.58, 0.66, local.y));
 tail *= alive * step(0.65, seed);
 return vec3(bead, tail, rim);
}

void fragment() {
 vec3 runoff = rain_layer(UV, 0.16, 1.0, 0.28);
 vec3 fine = rain_layer(UV, 0.31, 4.0, 0.075);
 float bead = max(runoff.x, fine.x * 0.65);
 float trail = max(runoff.y, fine.y * 0.3);
 float highlight = max(runoff.z, fine.z * 0.55);
 // Muted cyan and rose reflections suggest passing neon without hiding the city.
 float reflection = 0.5 + 0.5 * sin(UV.x * 0.017 + TIME * 0.10);
 vec3 reflected_light = mix(rain_tint, vec3(0.52, 0.24, 0.38), reflection * 0.50);
 ALBEDO = mix(glass_tint.rgb, reflected_light, clamp(highlight + trail * 0.25, 0.0, 1.0));
 ALBEDO += reflected_light * highlight * 0.35;
 ALPHA = clamp(glass_tint.a + bead * 0.18 + trail * 0.12 + highlight * 0.55, 0.0, 0.7);
}
