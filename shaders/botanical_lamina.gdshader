shader_type spatial;
render_mode cull_disabled;
// Lamina meshes use U across a tapered leaf and V along its midrib. Tone is
// intentionally low-contrast: a leaf surface, not a decal with pinstripes.
uniform vec4 tint : source_color = vec4(0.27,0.41,0.23,1.0);
uniform float phase = 0.0;

float close_line(float dst, float thin, float wid) {
 return 1.0-smoothstep(thin,thin+wid,abs(dst));
}

void fragment() {
 vec2 uv = UV;
 float t = uv.y;
 float across = uv.x-0.5;
 float off = abs(across);
 float bend = sin(t*10.3+phase)*0.006*sin(t*3.14159);
 float footprint = max(fwidth(uv.x),fwidth(uv.y));
 float lod_mix = 1.0-smoothstep(0.015,0.075,footprint);
 float tapered = 1.0-smoothstep(0.65,1.0,t);
 float midrib = close_line(across-bend,0.006+0.014*tapered,0.010+footprint);
 float lateral = mix(0.19,0.11,t);
 float flow = t/lateral-off*(1.37+0.51*off)+sin(t*9.0+off*17.0+phase)*0.08+sign(across)*0.06;
 float grid = abs(fract(flow+0.50)-0.50);
 float side_vein = (1.0-smoothstep(0.035,0.10+footprint*5.0,grid))*smoothstep(0.035,0.13,off)*(1.0-smoothstep(0.28,0.50,off));
 float margin = smoothstep(0.32,0.5,off);
 float lamina = sin(off*19.0+sin(t*14.0+phase)*2.2)*0.5 + sin(t*32.0+across*18.0+phase)*0.5;
 vec3 color = tint.rgb*(1.0 - margin*0.125 + 0.050*lamina*lod_mix);
 color += tint.rgb*vec3(0.21,0.21,0.095)*side_vein*lod_mix*tapered;
 color += tint.rgb*vec3(0.61,0.46,0.21)*midrib*lod_mix;
 // Softer, slightly paler backsides. Keep real geometric faces and shadows.
 ALBEDO = FRONT_FACING ? color : mix(color*0.82, vec3(dot(color,vec3(0.23,0.69,0.08))),0.13);
 ROUGHNESS = FRONT_FACING ? (0.67+0.08*margin) : 0.87;
 BACKLIGHT = tint.rgb*0.22;
}
