shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, fog_disabled;

// Glass refracts the already-lit scene. Beads do not emit their own pale points.
// Both UV sets are centimetres: UV varies the pattern, UV2 locates real seals.
uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec3 water_absorption = vec3(0.975, 0.986, 0.992);
uniform float refraction_pixels : hint_range(0.0, 8.0) = 3.2;

float hash21(vec2 p) {
 return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Gravity-shaped bead height, trailing water film, and body coverage.
vec3 moving_water(vec2 cm, float layer_seed) {
 vec2 p = cm * vec2(0.085, 0.043) + vec2(layer_seed * 17.3, layer_seed * 5.1);
 float column = floor(p.x);
 float speed = mix(0.018, 0.058, hash21(vec2(column, layer_seed)));
 p.y -= TIME * speed;
 vec2 cell = floor(p);
 vec2 q = fract(p);
 float seed = hash21(cell + layer_seed);
 float alive = step(0.82, seed);
 vec2 center = vec2(0.22 + 0.56 * hash21(cell + 7.0), 0.61);
 vec2 delta = q-center;
 float rx = mix(0.019, 0.034, hash21(cell + 3.0));
 float ry = mix(0.031, 0.063, hash21(cell + 11.0));
 // The leading bottom of a sliding drop is fuller than its tapering top.
 rx *= mix(0.58, 1.0, smoothstep(-ry, ry * 0.7, delta.y));
 float radius = length(delta / vec2(rx, ry));
 float aa = max(fwidth(radius), 0.055);
 float coverage = (1.0-smoothstep(1.0-aa, 1.0+aa, radius))*alive;
 float height = sqrt(max(0.0, 1.0-radius*radius))*coverage;
 float wander = sin(q.y*9.0+seed*21.0)*0.003;
 float trail_width = abs(delta.x+wander);
 float trail_aa = max(fwidth(trail_width),0.0007);
 float trail = 1.0-smoothstep(0.0025-trail_aa,0.0055+trail_aa,trail_width);
 trail *= smoothstep(0.06,0.29,q.y)*(1.0-smoothstep(0.52,0.60,q.y));
 trail *= alive*step(0.92,seed);
 return vec3(height,trail,coverage);
}

// Very small stationary moisture collects at seals, with little presence in the
// clear central pane. Its lighting comes entirely from the refracted background.
vec2 collected_water(vec2 cm, float edge) {
 vec2 p = cm*vec2(0.19,0.15)+vec2(13.2,4.7);
 vec2 cell = floor(p);
 vec2 q = fract(p);
 float seed = hash21(cell);
 float alive = step(mix(0.985,0.80,edge),seed);
 vec2 center = vec2(0.18)+vec2(hash21(cell+2.0),hash21(cell+9.0))*0.64;
 vec2 delta = (q-center)/vec2(0.020,0.029);
 float radius = length(delta);
 float aa = max(fwidth(radius),0.07);
 float coverage = (1.0-smoothstep(1.0-aa,1.0+aa,radius))*alive;
 float height = sqrt(max(0.0,1.0-radius*radius))*coverage;
 return vec2(height,coverage);
}

void fragment() {
 // Window mullions are 170 cm apart, starting 40 cm into each carriage.
 float in_bay = mod(UV2.x-40.0,170.0);
 float to_mullion = min(in_bay,170.0-in_bay);
 float to_seal = min(UV2.y,151.0-UV2.y);
 float edge = max(1.0-smoothstep(3.0,14.0,to_mullion),1.0-smoothstep(2.0,16.0,to_seal));
 vec3 runoff = moving_water(UV,1.0);
 vec2 beads = collected_water(UV,edge);
 float body = max(runoff.z,beads.y*0.60);
 float height = max(runoff.x,beads.x*0.45)+runoff.y*0.10;
 float wet = clamp(body*0.52+runoff.y*0.10,0.0,0.65);
 // A bounded screen-space normal bends actual city/frame colours through water.
 // Anti-aliased coverage lets distant drops disappear instead of sparkling.
 vec2 footprint = vec2(length(dFdx(UV)),length(dFdy(UV)));
 vec2 slope = vec2(dFdx(height),dFdy(height))/max(footprint,vec2(0.035));
 slope = clamp(slope,vec2(-1.0),vec2(1.0));
 vec2 pixel = 1.0/vec2(textureSize(scene_color,0));
 vec2 bend = slope*pixel*refraction_pixels;
 vec3 clear_scene = textureLod(scene_color,SCREEN_UV,0.0).rgb;
 vec3 bent_scene = textureLod(scene_color,clamp(SCREEN_UV+bend,vec2(0.001),vec2(0.999)),0.0).rgb;
 ALBEDO = mix(clear_scene,bent_scene,clamp(body+runoff.y,0.0,1.0))*water_absorption;
 ALPHA = 0.012+wet;
}
