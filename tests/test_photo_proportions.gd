extends SceneTree
const Game = preload("res://scripts/game.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, context: String) -> void:
 if not value: failures.append(context)

func run() -> void:
 var game := Game.new()
 for viewport in [Vector2i(1280,800),Vector2i(1440,900),Vector2i(1920,1080)]:
  var image := Image.create_empty(viewport.x,viewport.y,false,Image.FORMAT_RGBA8)
  image.fill(Color.BLACK)
  var center := Vector2i(viewport.x/3,viewport.y/2)
  var radius := 69
  for x in range(center.x-radius,center.x+radius+1):
   for y in range(center.y-radius,center.y+radius+1):
    if Vector2i(x,y).distance_squared_to(center)<=radius*radius: image.set_pixel(x,y,Color.WHITE)
  var photo: Image = game.format_field_photograph(image)
  var low := Vector2i(photo.get_width(),photo.get_height())
  var high := Vector2i.ZERO
  for x in range(photo.get_width()):
   for y in range(photo.get_height()):
    if photo.get_pixel(x,y).r>0.65:
     low = low.min(Vector2i(x,y))
     high = high.max(Vector2i(x,y))
  var disc := high-low+Vector2i.ONE
  var aspect := float(disc.x)/maxi(1,disc.y)
  check(disc.x>10 and disc.y>10 and absf(aspect-1.0)<0.045,"A round object stays round at "+str(viewport)+": "+str(disc))
  check(photo.get_width()<=560 and photo.get_height()<=420,"Normal image size budget remains in place")
  print("FIELD_PHOTO_FRAME ",viewport," output=",photo.get_size()," visible_disc=",disc)
 var small := Image.create_empty(40,50,false,Image.FORMAT_RGBA8)
 check(game.format_field_photograph(small).get_height()==50,"Small images are not forced to grow")
 game.free()
 if failures.is_empty(): print("PASS: native photo crop keeps natural shapes at all three target resolutions")
 else: printerr(failures)
 quit(0 if failures.is_empty() else 1)
