extends RefCounted
## Cabinet assets share the runtime, physically scaled reference materials.
const Finishes = preload("res://scripts/material_library.gd")
static func timber(tint: Color) -> ShaderMaterial:
 return Finishes.make(Finishes.Finish.MAHOGANY,tint)
static func stone() -> ShaderMaterial:
 return Finishes.make(Finishes.Finish.MARBLE,Color("a99e89"))
