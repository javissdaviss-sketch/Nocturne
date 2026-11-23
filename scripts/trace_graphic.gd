extends Control
## Small, neutral notebook drawing, not a lab finding or a field photograph.
const TRACE_OUTLINE := [Vector2(-0.5,-0.48),Vector2(0.28,-0.5),Vector2(0.55,-0.2),Vector2(0.33,0.5),Vector2(-0.28,0.45),Vector2(-0.55,0.12)]

func _draw() -> void:
 for shard in [Vector4(30,28,24,-0.3),Vector4(49,15,15,0.37),Vector4(58,37,11,0.57)]:
  var centre := Vector2(shard.x,shard.y)
  var points := PackedVector2Array()
  for vertex in TRACE_OUTLINE: points.append(centre+(vertex*shard.z).rotated(shard.w))
  draw_colored_polygon(points,Color("947ea3"))
  points.append(points[0])
  draw_polyline(points,Color("ded2df"),1.2,true)
  draw_line(points[0],centre,Color("564663"),1.2,true)
  draw_line(centre,points[2],Color("564663"),1.2,true)
