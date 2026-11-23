extends SceneTree
const ListeningMix = preload("res://scripts/listening_mix.gd")

func _initialize() -> void:
 var mix := ListeningMix.new()
 const TRAIN := 0.71
 const WINGS := 0.24
 const CONTEXT := 0.25
 var normal := mix.gains(TRAIN,WINGS,CONTEXT)
 assert(normal.is_equal_approx(Vector2(TRAIN,WINGS*CONTEXT)))
 mix.step(true,0.10)
 assert(is_equal_approx(mix.blend,0.5))
 var midpoint := mix.gains(TRAIN,WINGS,CONTEXT)
 assert(midpoint.x<normal.x and midpoint.y<normal.y)
 mix.step(true,0.10)
 assert(is_equal_approx(mix.blend,1.0))
 var quiet := mix.gains(TRAIN,WINGS,CONTEXT)
 assert(quiet.x<midpoint.x and quiet.y<midpoint.y)
 assert(mix.gains(0,0,CONTEXT).is_zero_approx(),"Never raise muted channels")
 mix.step(false,0.10)
 assert(mix.gains(TRAIN,WINGS,CONTEXT).is_equal_approx(midpoint))
 mix.step(false,0.10)
 assert(mix.gains(TRAIN,WINGS,CONTEXT).is_equal_approx(normal),"Restore exact existing volume settings")
 mix.step(true,10.0)
 assert(is_equal_approx(mix.blend,1.0),"A slow frame remains bounded")
 mix.step(false,10.0)
 assert(is_zero_approx(mix.blend))
 print("PASS: 200ms ambience fades, wing context stays intact, muted channels stay silent and user volumes restore exactly")
 quit()
