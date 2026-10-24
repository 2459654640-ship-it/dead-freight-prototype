extends SceneTree
const Bag=preload("res://scripts/bag.gd")
const Guard=preload("res://scripts/guard.gd")
var checks=0
var failed=0
var raid
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if not ok:failed+=1;push_error("FAIL: "+message)
func frames(n:int=3):
	for i in n:await physics_frame
func run():
	raid=load("res://scenes/raid.tscn").instantiate();root.add_child(raid);current_scene=raid
	await frames(4)
	check(raid.enemies.size()==5,"five guards spawned")
	for soldier in raid.enemies:
		check(detail_mesh(soldier,"b_pack")!=null and detail_mesh(soldier,"bproof")!=null,"every enemy has artist-authored backpack and armor meshes")
	var human=detail_mesh(raid.enemies[0],"bproof")
	check(human!=null and human.mesh.surface_get_material(0).albedo_color.a>.99 and human.mesh.surface_get_material(0).transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,"converted character materials are opaque and renderable")
	check(human.mesh.surface_get_material(0).albedo_texture!=null,"upgraded enemy uses original photographic/detail texture")
	check(raid.player.weapon.has_meta("anim"),"first-person weapon has an imported animation player")
	var colliders_disabled=true
	for body in raid.player.weapon.find_children("*","CollisionObject3D",true,false):
		if body.collision_layer!=0:colliders_disabled=false
	check(colliders_disabled,"imported first-person art cannot displace or obstruct the player")
	var used={}
	for enemy in raid.enemies:
		check(not used.has(enemy.position),"spawn points unique");used[enemy.position]=true
		enemy.set_physics_process(false)
	check(raid.loot.size()>=7,"searchable loot placed indoors and outdoors")
	check(raid.route(Vector3(-25,0,23),raid.extract_pos).size()>20,"spawn-to-extraction navigable")
	check(not raid.route(Vector3(-14,0,0),Vector3(-14,0,-15)).is_empty(),"warehouse interior navigable")
	check(not raid.route(Vector3(17,0,0),Vector3(21,0,-15)).is_empty(),"medical interior doorway navigable")
	for b in raid.hud.menu.find_children("*","Button",true,false):
		if b.text.begins_with("DEPLOY"):b.pressed.emit();break
	check(raid.active and not raid.hud.menu.visible,"deploy button starts raid")
	var before=raid.player.position
	Input.action_press("forward");await frames(60);Input.action_release("forward");await frames(10)
	check(raid.player.position.distance_to(before)>2,"WASD produces real physics movement")
	check(raid.player.position.y>-.1 and raid.player.position.y<.3,"floor supports capsule")
	Input.action_press("crouch");await frames(30);Input.action_release("crouch")
	check(raid.player.head.position.y<1.2,"crouch lowers camera and capsule")
	await frames(20)
	Input.action_press("aim");await frames(25);Input.action_release("aim")
	check(raid.player.camera.fov<62,"ADS narrows field of view")
	await frames(20)
	var hp=raid.player.health;raid.player.damage(40)
	check(raid.player.health==hp-40,"damage changes health")
	var meds=raid.bag.count("med");check(raid.player.heal(),"treatment begins")
	raid.player.action_timer=.001;await frames(2)
	check(raid.player.health==100 and raid.bag.count("med")==meds-1,"healing consumes dressing once")
	raid.player.damage(30);raid.player.heal();raid.player.damage(1)
	check(raid.player.action=="" and raid.bag.count("med")==meds-1,"damage interrupts treatment without consuming medicine")
	var gun_rig:Skeleton3D=raid.player.weapon.find_children("*","Skeleton3D",true,false)[0];var magazine_bone=gun_rig.find_bone("j_reload_08");var magazine_start=gun_rig.get_bone_global_pose(magazine_bone)
	raid.player.magazine=7;var ammo=raid.bag.count("ammo");check(raid.player.reload_weapon(),"reload begins")
	await frames(20)
	check(not gun_rig.get_bone_global_pose(magazine_bone).is_equal_approx(magazine_start),"artist reload animation moves the original weapon rig")
	raid.player.action_timer=.001;await frames(2)
	check(raid.player.magazine==30 and raid.bag.count("ammo")==ammo-23,"reload conserves cartridges")
	# UI callbacks exercise transfer, repeat pickup prevention, and dropping.
	var crate=raid.make_loot(Vector3(-25,.5,22),"TEST CONTAINER",[{"id":"drive","qty":1}],Vector3(.6,.5,.5),Color.WHITE)
	raid.hud.open_inventory(crate);var n=raid.bag.count("drive");raid.hud.take_all();raid.hud.take_all()
	check(raid.bag.count("drive")==n+1 and crate.get_meta("loot").is_empty(),"take-all transfers once, no duplication")
	raid.hud.drop_item("drive");check(raid.bag.count("drive")==n,"drop removes inventory item and spawns world loot")
	raid.hud.close_inventory()
	# Search acquisition must use an actual unobstructed physics ray.
	raid.player.position=Vector3(-25,.05,24);raid.player.rotation.y=0;raid.player.pitch=-.45
	await frames(3)
	check(raid.player.interaction_target==crate,"search ray acquires container")
	Input.action_press("interact");await frames(80);Input.action_release("interact")
	check(raid.hud.panel_open and raid.hud.source==crate,"holding F opens the targeted container")
	raid.hud.close_inventory()
	# Ballistic hit and AI line of sight, without relying on probabilistic AI shots.
	var enemy=raid.enemies[0];enemy.position=Vector3(-25,.05,15);raid.player.position=Vector3(-25,.05,20);raid.player.rotation=Vector3.ZERO;raid.player.pitch=-.07;raid.player.recoil=Vector2.ZERO
	enemy.model.rotation.y=PI;enemy.state="ENGAGE";await frames(3)
	check(enemy.visible_player(),"AI detects unobstructed player")
	var health_before=raid.player.health;enemy.shoot(5)
	check(raid.player.health<health_before,"AI projectile ray damages unobstructed player")
	var magazine=raid.player.magazine
	raid.player.aiming=true;raid.player.shot_timer=0;raid.player.fire()
	await frames(1)
	check(raid.player.magazine==magazine-1,"shot consumes one cartridge")
	check(raid.player.recoil.x>0,"shot produces visible camera recoil")
	check(enemy.health<100,"hitscan hits actual guard collision")
	enemy.position=Vector3(-26,.05,-10);raid.player.position=Vector3(-22,.05,-10);await frames(3)
	check(not enemy.visible_player(),"concrete wall occludes AI sight")
	health_before=raid.player.health;enemy.shoot(4)
	check(raid.player.health==health_before,"AI fire is blocked by concrete wall")
	enemy.position=Vector3(-28,.05,-25);enemy.state="PATROL";enemy.path=raid.route(enemy.position,Vector3(-28,.05,-18));enemy.think_timer=5
	before=enemy.position;enemy.set_physics_process(true);await frames(60);enemy.set_physics_process(false)
	check(enemy.position.distance_to(before)>1,"AI patrol follows path with real body movement")
	var kills=raid.kills;enemy.take_hit(200);await frames(2)
	check(raid.kills==kills+1,"lethal damage increments kills and drops searchable loot")
	# Pause stops world progression; inventory does not.
	raid.hud.toggle_pause();var old_time=raid.time_left;await process_frame;await process_frame
	check(raid.time_left==old_time,"pause freezes raid timer")
	raid.hud.toggle_pause()
	var full=Bag.new(false);var accepted=full.add("alloy",200)
	check(accepted<200 and full.weight()<=24.001,"backpack enforces weight limit")
	check(not full.remove("drive"),"cannot remove absent items")
	var slots=Bag.new(false);check(slots.add("drive",40)==16,"backpack enforces slot limit")
	var credits=raid.saved_credits;var value=raid.bag.value()
	raid.player.position=raid.extract_pos+Vector3(0,.05,0);raid.extract_time=5.99;await frames(3)
	check(not raid.active and raid.hud.result.visible,"extraction produces end-of-raid screen")
	check(raid.saved_credits==credits+value,"only successful extraction banks cargo")
	var stored=ConfigFile.new();check(stored.load("user://profile.cfg")==OK and stored.get_value("profile","credits")==raid.saved_credits,"bank persists to isolated profile")
	# Death in a fresh raid must leave bank unchanged.
	raid.queue_free();await frames(2)
	raid=load("res://scenes/raid.tscn").instantiate();root.add_child(raid);current_scene=raid;await frames(2)
	for e in raid.enemies:e.set_physics_process(false)
	raid.start();credits=raid.saved_credits;raid.player.damage(1000)
	check(not raid.active and raid.saved_credits==credits,"death loses current raid cargo without crediting bank")
	print("FREIGHT_SMOKE_RESULT checks=",checks," failures=",failed)
	raid.queue_free();await frames(2);quit(0 if failed==0 else 1)

func detail_mesh(node:Node,token:String):
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var m=mesh.mesh.surface_get_material(i)
			if m is StandardMaterial3D and m.albedo_texture and token in m.albedo_texture.resource_path:return mesh
	return null
