extends CharacterBody3D
const Kit=preload("res://scripts/kit.gd")
var raid
var health=100
var state="PATROL"
var home:Vector3
var goal:Vector3
var last_seen:Vector3
var awareness=0.0
var shoot_timer=1.2
var think_timer=0.0
var memory=0.0
var path:PackedVector3Array=[]
var model:Node3D
var legs:Array=[]
var anim=0.0
var ident=0
var muzzle:MeshInstance3D
var animation:AnimationPlayer
var rig:Skeleton3D
var current_animation=""
func _ready():
	collision_layer=4;collision_mask=1|2|4
	var c=CollisionShape3D.new();var shape=CapsuleShape3D.new();shape.radius=.32;shape.height=1.78;c.shape=shape;c.position.y=.89;add_child(c)
	model=Node3D.new();add_child(model)
	var visual=load("res://assets/vendor/city-soldier/scene.gltf").instantiate();model.add_child(visual)
	Kit.disable_imported_collisions(visual)
	Kit.matte_imported_surfaces(visual,.88)
	visual.scale=Vector3.ONE*.97;visual.rotation.y=PI
	animation=visual.find_children("*","AnimationPlayer",true,false)[0]
	rig=visual.find_children("*","Skeleton3D",true,false)[0]
	animation.play("stay pose");animation.advance(0);animation.pause()
	pose_city_arms()
	var gun=Kit.gun(model,false);gun.position=Vector3(.14,1.29,-.35)
	muzzle=Kit.box(gun,Vector3(0,0,-.54),Vector3(.07,.07,.18),Color("ffd898"));muzzle.material_override=Kit.mat(Color("ffd898"),0,2);muzzle.visible=false
	home=global_position;goal=home
func _physics_process(delta):
	if not raid.active:return
	shoot_timer-=delta;think_timer-=delta;memory=maxf(0,memory-delta)
	muzzle.visible=shoot_timer>1.03
	if think_timer<=0:
		think_timer=.22+ident*.007;think()
	var distance=global_position.distance_to(raid.player.global_position)
	var moving=not path.is_empty() and (state!="ENGAGE" or distance>14 or memory<4)
	var direction=Vector3.ZERO
	if moving:
		while not path.is_empty() and global_position.distance_to(path[0])<.65:path.remove_at(0)
		if not path.is_empty():direction=(path[0]-global_position);direction.y=0;direction=direction.normalized()
	var speed=2.65 if state!="PATROL" else 1.65
	velocity.x=direction.x*speed;velocity.z=direction.z*speed
	if not is_on_floor():velocity.y-=22*delta
	move_and_slide()
	var look=last_seen if state=="ENGAGE" else global_position+direction
	if look.distance_to(global_position)>.1 and (direction.length()>.1 or state=="ENGAGE"):
		var target_y=atan2(-(look.x-global_position.x),-(look.z-global_position.z))
		model.rotation.y=lerp_angle(model.rotation.y,target_y,delta*8)
	anim+=delta*speed*(1 if direction.length()>.1 else 0)
	animate_city(delta,direction.length(),speed)
func visible_player()->bool:
	var eye=global_position+Vector3(0,1.55,0)
	var target=raid.player.global_position+Vector3(0,1.2,0)
	var distance=eye.distance_to(target)
	if distance>31:return false
	var dir=(target-eye).normalized()
	var forward=-model.global_basis.z
	if state=="PATROL" and distance>6 and forward.dot(dir)<.2:return false
	var q=PhysicsRayQueryParameters3D.create(eye,target,1|2);q.exclude=[get_rid()]
	var hit=get_world_3d().direct_space_state.intersect_ray(q)
	return not hit.is_empty() and hit.collider==raid.player
func think():
	var distance=global_position.distance_to(raid.player.global_position)
	if visible_player():
		awareness=minf(1,awareness+(.27 if raid.player.crouching else .44))
		last_seen=raid.player.global_position;memory=5.5
		if awareness>=1:
			state="ENGAGE"
			if shoot_timer<=0:shoot(distance)
		else:state="ALERT"
	elif raid.player.noise>0 and distance<(34 if raid.player.noise>1 else 10):
		last_seen=raid.player.global_position;memory=maxf(memory,2.0)
		if state!="ENGAGE":state="ALERT"
	elif memory<=0:
		state="PATROL";awareness=maxf(0,awareness-.15)
	if state in ["ENGAGE","ALERT"]:
		goal=last_seen
	elif path.is_empty():
		goal=home+Vector3(raid.rng.randf_range(-7,7),0,raid.rng.randf_range(-7,7))
	path=raid.route(global_position,goal)
func shoot(distance:float):
	shoot_timer=raid.rng.randf_range(.95,1.5)
	raid.sound.play("enemy",global_position,-5)
	var origin=global_position+Vector3(0,1.45,0)
	var target=raid.player.global_position+Vector3(0,1.15,0)
	var spread=clampf(distance*.014,.13,.7)
	target+=Vector3(raid.rng.randf_range(-spread,spread),raid.rng.randf_range(-spread*.6,spread*.6),0)
	var q=PhysicsRayQueryParameters3D.create(origin,origin+(target-origin).normalized()*50,1|2);q.exclude=[get_rid()]
	var hit=get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		if hit.collider==raid.player:raid.player.damage(raid.rng.randf_range(10,17))
		else:raid.impact(hit.position,hit.normal)
func take_hit(amount:int):
	if health<=0:return
	health-=amount;state="ENGAGE";awareness=1;memory=6;last_seen=raid.player.global_position
	if health<=0:
		raid.kills+=1
		raid.make_loot(global_position+Vector3(0,.12,0),"FALLEN SCAV",[{"id":"ammo","qty":30},{"id":"med","qty":1}],Vector3(.65,.23,1.1),Color("414e41"))
		queue_free()

func pose_arm(bone:String,child:String,origin:Vector3,end:Vector3):
	var idx=rig.find_bone(bone);var child_idx=rig.find_bone(child)
	var rest=rig.get_bone_global_rest(idx)
	var previous=(rig.get_bone_global_rest(child_idx).origin-rest.origin).normalized()
	rest.basis=Basis(Quaternion(previous,(end-origin).normalized()))*rest.basis
	rest.origin=origin;rig.set_bone_global_pose_override(idx,rest,1,true)

func city_bone(number:int)->int:
	for i in rig.get_bone_count():
		if rig.get_bone_name(i).begins_with("Bone.%03d_"%number):return i
	return -1
func aim_city(number:int,child_number:int,target:Vector3):
	var i=city_bone(number);var child=city_bone(child_number)
	if i<0 or child<0:return
	var pose=rig.get_bone_global_pose(i);var old=(rig.get_bone_global_pose(child).origin-pose.origin).normalized()
	var point=rig.to_local(model.to_global(target));var desired=(point-pose.origin).normalized()
	pose.basis=Basis(Quaternion(old,desired))*pose.basis
	rig.set_bone_global_pose_override(i,pose,1,true);rig.force_update_all_bone_transforms()
func pose_city_arms():
	# Adapt the existing rig pose without changing any artist-authored geometry.
	rig.clear_bones_global_pose_override();rig.force_update_all_bone_transforms()
	aim_city(36,37,Vector3(.30,1.05,-.05));aim_city(37,38,Vector3(.14,1.25,-.30))
	aim_city(13,14,Vector3(-.28,1.05,-.12));aim_city(14,15,Vector3(-.03,1.27,-.65))
func animate_city(_delta:float,moving:float,_speed:float):
	for pair in [[7,1.0],[10,-1.0]]:
		var i=city_bone(pair[0])
		if i>=0:rig.set_bone_pose_rotation(i,Quaternion(Vector3.RIGHT,sin(anim*6)*.28*pair[1] if moving>.1 else 0.0))
