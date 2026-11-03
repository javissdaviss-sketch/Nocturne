shader_type spatial;
uniform vec4 wool_color : source_color = vec4(0.06,0.16,0.14,1.0);
uniform vec4 thread_color : source_color = vec4(0.48,0.37,0.19,1.0);
varying vec3 world_position;
void vertex() {world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float stroke(float distance_to_line, float width) {
 float aa = max(fwidth(distance_to_line),0.045);
 return 1.0-smoothstep(width,width+aa,distance_to_line);
}
void fragment() {
 vec2 p = world_position.xz;
 float side = abs(p.x);
 float border = max(stroke(abs(side-48.0),0.34),stroke(abs(side-51.0),0.13));
 float repeat_y = mod(p.y,44.0)-22.0;
 float diamond = stroke(abs(abs(p.x)*0.64+abs(repeat_y)-15.0),0.25);
 diamond *= 1.0-smoothstep(23.0,24.0,side);
 float center = stroke(side,0.10)*(1.0-smoothstep(16.0,17.0,abs(repeat_y)));
 float corners = stroke(abs(abs(repeat_y)-12.0),0.16)*step(42.0,side)*step(side,47.0);
 float pattern = max(max(border,diamond),max(center,corners));
 float weave = 0.96+0.035*sin(p.x*37.0)*sin(p.y*41.0);
 float tread = mix(0.84,1.0,smoothstep(8.0,40.0,side));
 ALBEDO = mix(wool_color.rgb*weave*tread,thread_color.rgb,pattern*0.8);
 ROUGHNESS = 0.95;
}
