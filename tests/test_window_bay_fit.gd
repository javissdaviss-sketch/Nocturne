extends SceneTree
const Head:=preload("res://scripts/window_head_finish.gd")
func _initialize()->void: call_deferred("run")
func run()->void:
 var problems:=[]
 var counts:=[]
 var triangles:=0
 var orphans:=0
 for car in range(3):
  var limits:Array=Head.COACH_WALLS[car]
  var count:=0
  for z in range(car*840+40,car*840+790,170):
   var pieces:=Head.plan(car,float(z))
   if pieces.is_empty(): orphans+=1
   for piece in pieces:
    count+=1
    if not (piece.begin>=maxf(float(z)-4.0,float(limits[piece.room])+5.7) and
     piece.end<=minf(float(z)+150.0,float(limits[piece.room+1])-5.7) and piece.half*2>=23.0):
     problems.append("window fit violates exact partition boundary")
    for form:Mesh in Head.geometry(car,piece.half):
     var allowed:=AABB(Vector3(-0.55,248,-piece.half-0.005),Vector3(6.96,27,2.0*piece.half+0.01))
     if not allowed.encloses(form.get_aabb()):
      problems.append("actual mesh floats into adjacent bay "+str(form.get_aabb())+" expected "+str(allowed))
     triangles+=form.get_faces().size()/3
  counts.append(count)
 if counts!=[5,6,5] or orphans!=0 or triangles*2>34000:
  problems.append("scope broke existing coverage or geometry budget "+str([counts,orphans,triangles*2]))
 if problems.is_empty(): print("PASS: two room sides of every coach glass bay fit within structural partitions; 32 physically distinct fitted heads; ",triangles*2," total triangles.")
 else:
  for item in problems: push_error(item)
 quit(0 if problems.is_empty() else 1)
