extends RefCounted
## Four purpose-designed open vessels in the former pot footprints.
## All profiles share the original solid foot and planted soil/support level.
const Profile:=preload("res://scripts/ceramic_profiles.gd")

const FORM:Dictionary={
 # Stoneware display: narrow pedestal and generously cupped shoulder.
 "orchid":[[[0.62,0.0],[0.65,0.08],[0.64,0.15],[0.69,0.23],[0.82,0.50],[0.98,0.76],[1.025,0.91]],"c0b7a0","8f8c73",0.9],
 # Working terracotta: rolled shoulder & scored ridges, no polished brass.
 "potting":[[[0.71,0.0],[0.72,0.11],[0.75,0.29],[0.83,0.58],[0.95,0.80],[1.017,0.91]],"856247","6d4637",0.5],
 # Historical store: drawn cylindrical neck over an honest broad hand-thrown belly.
 "heritage":[[[0.66,0.0],[0.73,0.09],[0.88,0.23],[0.99,0.45],[0.98,0.64],[0.92,0.79],[0.96,0.91]],"65644f","7e7862",0.45],
 # Live reserve: clean enamel with a shallow stepped lower drainage collar.
 "reserve":[[[0.58,0.0],[0.62,0.07],[0.65,0.16],[0.77,0.18],[0.80,0.29],[0.87,0.53],[0.96,0.76],[1.022,0.91]],"4a706a","7b9483",0.65],
}

static func finish(role:String, tall:bool)->Color:
 var fields:Array=FORM[role]
 return Color(fields[1 if tall else 2])

static func profile_path(role:String, diameter:float, h:float)->Array[Vector2]:
 var spec:Array=FORM[role]
 var radius:=diameter*0.5
 var shape:Array[Vector2]=[Vector2(0.02,0.2)]
 for point in spec[0]:
  shape.append(Vector2(radius*float(point[0]),lerpf(0.2,h,float(point[1]))))
 # Different metal/earthenware lips, all hand finished and non-overlapping.
 var thickness:float=spec[3]
 shape.append_array([Vector2(radius*1.052,h-0.40),Vector2(radius*1.063,h+0.23),
  Vector2(radius*1.048,h+0.63),Vector2(radius*0.952,h+0.63),
  Vector2(radius*0.918,h+0.05),Vector2(radius*0.904,h-1.55)])
 for i in range(spec[0].size()-2,-1,-1):
  var point:Array=spec[0][i]
  var y:=lerpf(1.73,h-0.7,float(point[1]))
  if y<h-1.7:
   shape.append(Vector2(radius*float(point[0])-thickness,y))
 shape.append(Vector2(0.02,1.73))
 return shape

static func modeled(role:String, diameter:float, h:float)->ArrayMesh:
 return Profile.lathe(profile_path(role,diameter,h))
