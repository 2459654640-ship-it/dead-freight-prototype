extends SceneTree
func _initialize():call_deferred("run")
func wait_frames(n:int=5):
	for i in n:await process_frame
	await RenderingServer.frame_post_draw
func capture(name:String):
	await wait_frames(4)
	var image=root.get_texture().get_image();image.save_png("res://docs/"+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://docs")
	var raid=load("res://scenes/raid.tscn").instantiate();root.add_child(raid);current_scene=raid
	await capture("menu")
	raid.start()
	for i in raid.enemies.size():
		var e=raid.enemies[i];e.set_physics_process(false);e.position=Vector3(29+i,.05,29)
	raid.player.position=Vector3(-1,.05,15);raid.player.rotation.y=.32;raid.player.pitch=-.03
	await capture("yard")
	raid.player.position=Vector3(-14,.05,1);raid.player.rotation.y=0;raid.player.pitch=-.04
	await capture("warehouse")
	var guard=raid.enemies[0];guard.position=Vector3(-14,.05,-7);guard.model.rotation.y=PI
	raid.player.position=Vector3(-14,.05,-3.5);raid.player.rotation=Vector3.ZERO;raid.player.pitch=-.03
	await capture("contact")
	print("CONTACT camera=",raid.player.camera.global_position," enemy=",guard.global_position)
	raid.hud.open_inventory(raid.loot[1]);await capture("inventory")
	print("FREIGHT_GRAPHICS_RESULT captures=5")
	quit()
