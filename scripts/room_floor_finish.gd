extends RefCounted
## Referenced cloth/board/clay photographs underlay original per-room layouts.
## All floors reuse the exact original solid inset; corridors are unaffected.
const Mat:=preload("res://scripts/material_library.gd")
const RoomShader:=preload("res://shaders/fitted_room_floors.gdshader")
const ROOMS:Dictionary={
 "0:-1:0":["Writing rug",0,0,"4d3638","8e6c52",Vector2(44,53),0.40],
 "0:1:0":["Crew wool",0,1,"4b4d3d","7d7861",Vector2(23,62),0.33],
 "0:-1:360":["Coastal runner",0,2,"4d565c","7d8984",Vector2(42,46),0.34],
 "0:1:360":["Engine room utility tile",3,0,"3f4848","62706c",Vector2(26,32),0.25],
 "1:-1:840":["Concierge mosaic",2,2,"4b5648","6d684e",Vector2(30,26),0.23],
 "1:1:840":["Cloak wool",0,3,"464b52","74695e",Vector2(26,39),0.36],
 "1:-1:990":["Meridian dining rug",0,2,"614344","8d7257",Vector2(65,68),0.42],
 "1:1:990":["Tea room square weave",0,0,"505c4a","7f825f",Vector2(25,35),0.28],
 "1:-1:1390":["Pantry ceramic",2,0,"746554","a29171",Vector2(24,18),0.29],
 "1:1:1390":["Steward slate",3,1,"49555e","66747b",Vector2(43,30),0.24],
 "2:-1:1680":["Orchid cabochon",2,2,"597062","8b9074",Vector2(35,35),0.26],
 "2:1:1680":["Potting terracotta",2,0,"705343","967358",Vector2(22,38),0.30],
 "2:-1:2045":["Heritage walnut boards",1,0,"584333","957b51",Vector2(21,81),0.41],
 "2:1:2045":["Reserve textured floor",3,1,"47615c","74877b",Vector2(33,31),0.27],
}
static var palette:Dictionary={}
static func get_floor(car:int,side:int,lo:float,hi:float)-> ShaderMaterial:
 var key:="%d:%d:%d"%[car,side,int(lo)]
 if not ROOMS.has(key): return null
 if palette.has(key): return palette[key]
 var fields:Array=ROOMS[key]
 var m:=ShaderMaterial.new()
 m.shader=RoomShader
 m.resource_name=fields[0]
 m.set_meta("crafted_finish",Mat.Finish.RUG if int(fields[1])==0 else (Mat.Finish.WALNUT if int(fields[1])==1 else Mat.Finish.CERAMIC))
 m.set_shader_parameter("reference_atlas",Mat.ATLAS)
 m.set_shader_parameter("field_color",Color(fields[3]))
 m.set_shader_parameter("accent_color",Color(fields[4]))
 m.set_shader_parameter("style_kind",fields[1])
 m.set_shader_parameter("motif_kind",fields[2])
 m.set_shader_parameter("repeat_cm",fields[5])
 m.set_shader_parameter("dye_variation",fields[6])
 m.set_shader_parameter("floor_center",Vector2(side*332,(hi+lo)*0.5))
 m.set_shader_parameter("floor_half",Vector2(150,(hi-lo-18)*0.5))
 palette[key]=m
 return m
