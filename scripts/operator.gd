extends CharacterBody3D
const Kit=preload("res://scripts/kit.gd")
var raid
var camera:Camera3D
var head:Node3D
var weapon:Node3D
var flash:MeshInstance3D
var health=100.0
var stamina=100.0
var magazine=30
var pitch=0.0
var recoil=Vector2.ZERO
var recoil_offset=0.0
var shot_timer=0.0
var action=""
var action_timer=0.0
var action_total=0.0
var aiming=false
var sprinting=false
var crouching=false
var grounded_before=true
var bob=0.0
var step_distance=0.0
var sensitivity=.0022
var mouse_sway=Vector2.ZERO
var interact_progress=0.0
var interaction_target:Node3D
var noise=0.0
var exhausted=false
var hurt_time=0.0
var capsule:CapsuleShape3D
func _ready():
	collision_layer=2;collision_mask=1|4
	capsule=CapsuleShape3D.new();capsule.radius=.30;capsule.height=1.8
	var c=CollisionShape3D.new();c.shape=capsule;c.position.y=.9;add_child(c)
	head=Node3D.new();add_child(head);head.position.y=1.64
	camera=Camera3D.new();head.add_child(camera);camera.current=true;camera.fov=78;camera.near=.04;camera.far=150
	weapon=Kit.gun(camera);weapon.position=Vector3(.18,-.13,-.15)
	flash=Kit.box(weapon,Vector3(0,-.12,-1.16),Vector3(.065,.065,.18),Color("ffd793"))
	flash.material_override=Kit.mat(Color("ffda83"),0,3);flash.visible=false
	floor_snap_length=.2;floor_max_angle=deg_to_rad(46)
func _unhandled_input(event):
	if not raid.active or raid.hud.panel_open or raid.hud.paused:return
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x*sensitivity)
		pitch=clampf(pitch-event.relative.y*sensitivity,deg_to_rad(-85),deg_to_rad(85))
		mouse_sway+=event.relative*.0004
	if event.is_action_pressed("reload"):reload_weapon()
	if event.is_action_pressed("heal"):heal()
func _physics_process(delta):
	if not raid.active:return
	hurt_time=maxf(0,hurt_time-delta);shot_timer=maxf(0,shot_timer-delta);noise=maxf(0,noise-delta)
	var blocked=raid.hud.panel_open or raid.hud.paused
	if not blocked and Input.is_action_pressed("fire") and not sprinting and action=="":fire()
	if action!="":
		action_timer-=delta
		if action_timer<=0:complete_action()
	aiming=not blocked and Input.is_action_pressed("aim") and action=="" and not Input.is_action_pressed("sprint")
	crouching=not blocked and Input.is_action_pressed("crouch")
	if not crouching and capsule.height<1.7:
		var standing=CapsuleShape3D.new();standing.radius=.3;standing.height=1.8
		var clearance=PhysicsShapeQueryParameters3D.new();clearance.shape=standing;clearance.transform=Transform3D(Basis.IDENTITY,global_position+Vector3(0,.91,0));clearance.collision_mask=1;clearance.exclude=[get_rid()]
		crouching=not get_world_3d().direct_space_state.intersect_shape(clearance).is_empty()
	var input=Vector2.ZERO if blocked else Input.get_vector("left","right","forward","back")
	sprinting=not blocked and Input.is_action_pressed("sprint") and input.y<-.3 and stamina>1 and not exhausted and action=="" and not crouching
	if sprinting:stamina=maxf(0,stamina-22*delta)
	else:stamina=minf(100,stamina+15*delta)
	if stamina<1:exhausted=true
	elif stamina>22:exhausted=false
	var speed=6.3 if sprinting else (2.0 if crouching else (2.55 if aiming else 4.1))
	speed*=lerpf(1,.78,raid.bag.weight()/24.0)
	var direction=global_basis*Vector3(input.x,0,input.y)
	var acceleration=20.0 if is_on_floor() else 5.0
	velocity.x=move_toward(velocity.x,direction.x*speed,acceleration*delta)
	velocity.z=move_toward(velocity.z,direction.z*speed,acceleration*delta)
	if not is_on_floor():velocity.y-=22*delta
	elif not blocked and Input.is_action_just_pressed("jump") and not crouching and stamina>=12:
		velocity.y=5.5;stamina-=12
	move_and_slide()
	if is_on_floor() and not grounded_before:recoil_offset+=.025
	grounded_before=is_on_floor()
	var movement=Vector2(velocity.x,velocity.z).length()
	if is_on_floor() and movement>.5:
		bob+=delta*movement*2.8;step_distance+=delta*movement
		if step_distance>(2.3 if sprinting else 1.8):
			step_distance=0;raid.sound.play("step",Vector3.ZERO,-14 if crouching else -7)
			if not crouching:noise=maxf(noise,.18)
	head.position.y=lerpf(head.position.y,1.1 if crouching else 1.64,1-exp(-14*delta))
	capsule.height=1.25 if crouching else 1.8
	get_child(0).position.y=capsule.height/2
	recoil=recoil.lerp(Vector2.ZERO,1-exp(-13*delta))
	head.rotation.x=pitch+recoil.x
	rotation.y+=recoil.y*delta*2
	camera.fov=lerpf(camera.fov,56.0 if aiming else (83.0 if sprinting else 78.0),1-exp(-12*delta))
	camera.rotation.z=lerpf(camera.rotation.z,-input.x*.012,1-exp(-10*delta))
	recoil_offset=move_toward(recoil_offset,0,delta*.24)
	mouse_sway=mouse_sway.lerp(Vector2.ZERO,1-exp(-10*delta))
	var offset=Vector3(0,-.06,-.10) if aiming else Vector3(.18,-.13,-.15)
	if action=="RELOADING":offset+=Vector3(.09,-.20,.12)
	elif action=="TREATING":offset.y-=.4
	elif sprinting:offset+=Vector3(.02,-.08,.07)
	var sway_scale=.15 if aiming else 1.0
	offset+=Vector3(sin(bob)*.008*movement/4,absf(cos(bob))*.008*movement/4, recoil_offset)*sway_scale
	offset+=Vector3(-mouse_sway.x,mouse_sway.y,0).limit_length(.04)
	weapon.position=weapon.position.lerp(offset,1-exp(-16*delta))
	weapon.rotation.z=lerpf(weapon.rotation.z,-.25 if action=="RELOADING" else 0.0,1-exp(-12*delta))
	if weapon.has_meta("carbine_rig") and weapon.has_meta("mag_rest"):
		var gun_rig:Skeleton3D=weapon.get_meta("carbine_rig");var magazine_bone=gun_rig.find_bone("Magazine")
		var magazine_motion=sin(PI*clampf(1-action_timer/action_total,0,1)) if action=="RELOADING" else 0.0
		gun_rig.set_bone_pose_position(magazine_bone,weapon.get_meta("mag_rest")+Vector3(0,0,-.20*magazine_motion))
	flash.visible=shot_timer>.065
	update_interaction(delta,blocked)
func fire()->bool:
	if shot_timer>0 or action!="" or not raid.active:return false
	if magazine<=0:
		shot_timer=.2;raid.hud.toast("EMPTY MAGAZINE · R to reload");return false
	play_view_animation("assualt_fire")
	magazine-=1;shot_timer=.092;recoil.x+=.013 if aiming else .022;recoil.y=randf_range(-.05,.05);recoil_offset=.07
	raid.sound.play("shot",Vector3.ZERO,-5);noise=1.6
	var origin=camera.global_position
	var spread=.0018 if aiming else (.008 if velocity.length()<1 else .019)
	var direction=(-camera.global_basis.z+camera.global_basis.x*randf_range(-spread,spread)+camera.global_basis.y*randf_range(-spread,spread)).normalized()
	var q=PhysicsRayQueryParameters3D.create(origin,origin+direction*110,1|4);q.exclude=[get_rid()]
	var hit=get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var target=hit.collider
		if target.has_method("take_hit"):
			var headshot=hit.position.y-target.global_position.y>1.42
			target.take_hit(110 if headshot else 34);raid.hud.hitmark=.18;raid.sound.play("hit",Vector3.ZERO,-5)
		else:raid.impact(hit.position,hit.normal)
	return true
func reload_weapon()->bool:
	if action!="" or magazine>=30 or raid.bag.count("ammo")==0:return false
	play_view_animation("assualt_reload",2.05)
	action="RELOADING";action_total=2.05;action_timer=action_total;interact_progress=0
	raid.sound.play("reload");return true
func heal()->bool:
	if action!="" or health>=100 or raid.bag.count("med")==0:return false
	play_view_animation("heal",2.8)
	action="TREATING";action_total=2.8;action_timer=action_total;interact_progress=0;return true
func complete_action():
	if action=="RELOADING":
		var amount=mini(30-magazine,raid.bag.count("ammo"))
		if amount>0 and raid.bag.remove("ammo",amount):magazine+=amount
	elif action=="TREATING" and raid.bag.remove("med"):health=minf(100,health+55)
	action="";action_timer=0
	reset_view_pose()
func damage(amount:float):
	if not raid.active:return
	health=maxf(0,health-amount);hurt_time=.65
	if action=="TREATING":action="";reset_view_pose();raid.hud.toast("Treatment interrupted")
	if health<=0:raid.finish(false)
func update_interaction(delta:float,blocked:bool):
	var previous_target=interaction_target
	interaction_target=null
	if blocked or action!="":interact_progress=0;return
	var q=PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*3.2,1|8)
	q.exclude=[get_rid()]
	var hit=get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and hit.collider.has_meta("loot"):interaction_target=hit.collider
	if previous_target!=interaction_target:interact_progress=0
	if interaction_target!=null and Input.is_action_pressed("interact"):
		interact_progress+=delta
		if interact_progress>=1.2:
			raid.hud.open_inventory(interaction_target);interact_progress=0
	else:interact_progress=0

func play_view_animation(clip:String,duration:float=0):
	if not weapon.has_meta("anim"):return
	var anim:AnimationPlayer=weapon.get_meta("anim")
	anim.speed_scale=anim.get_animation(clip).length/duration if duration>0 else 1.0
	anim.stop();anim.play(clip)
func reset_view_pose():
	if weapon.has_meta("anim"):
		var anim:AnimationPlayer=weapon.get_meta("anim")
		anim.speed_scale=1;anim.play("assualt_fire");anim.advance(0);anim.pause()
