extends SceneTree
const Policy := preload("res://scripts/room_shadow_policy.gd")
const Luxe := preload("res://scripts/cyber_luxe.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var rooms := Luxe.new()
 root.add_child(rooms)
 rooms.room_key(Vector3(-396,237,192),Color("ffcf95"),17,295,true)
 rooms.room_key(Vector3(396,237,192),Color("ffcf95"),17,295,false)
 var selected := rooms.get_child(0) as SpotLight3D
 var other := rooms.get_child(1) as SpotLight3D
 var sun := DirectionalLight3D.new()
 var valid := selected.light_energy==other.light_energy and selected.light_color==other.light_color
 valid = valid and not Policy.allows(selected,true,"gl_compatibility") and Policy.allows(selected,true,"forward_plus")
 valid = valid and Policy.allows(selected,true,"mobile") and Policy.allows(other,true,"gl_compatibility") and Policy.allows(sun,true,"gl_compatibility")
 for receiver in [selected,other,sun]:
  valid = valid and not Policy.allows(receiver,false,"gl_compatibility") and not Policy.allows(receiver,false,"forward_plus")
 var expected := [
  {"car":0,"side":-1,"lo":0},{"car":0,"side":1,"lo":0},
  {"car":0,"side":-1,"lo":360},{"car":0,"side":1,"lo":360},
  {"car":1,"side":-1,"lo":990},{"car":1,"side":1,"lo":990},
 ]
 for room: Dictionary in expected: valid = valid and Policy.proved_role(room)
 for rejected: Dictionary in [{"car":0,"side":-1,"lo":300},{"car":1,"side":1,"lo":990.2},{"car":1,"side":1,"lo":1390},{"car":2,"side":-1,"lo":1680}]:
  valid = valid and not Policy.proved_role(rejected)
 valid = valid and Policy.PROVEN_GL_FILLS.size()==6
 if valid: print("PASS: only marked GL fill abstains from shadows, emits unchanged; Forward+, unmarked lights, sun and manual player switch remain intact.")
 else: push_error("Shadow policy escaped its exact role or changed emission")
 sun.free()
 rooms.queue_free()
 quit(0 if valid else 1)
