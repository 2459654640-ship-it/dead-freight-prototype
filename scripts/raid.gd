extends Node3D
const Kit=preload("res://scripts/kit.gd")
const Bag=preload("res://scripts/bag.gd")
const Operator=preload("res://scripts/operator.gd")
const Guard=preload("res://scripts/guard.gd")
const Interface=preload("res://scripts/interface.gd")
const Sound=preload("res://scripts/sound.gd")
var player
var hud
var sound
var bag=Bag.new()
var rng=RandomNumberGenerator.new()
var active=false
var started=false
var kills=0
var time_left=720.0
var extract_time=0.0
var extract_pos=Vector3(26,0,-25)
var grid=AStarGrid2D.new()
var blockers:Array[Rect2]=[]
var enemies:Array=[]
var loot:Array=[]
var saved_credits=0
var saved_raids=0
var materials:Dictionary={}
var impact_nodes:Array=[]
func _ready():
	rng.randomize();setup_input();load_profile();setup_environment();build_map();setup_grid()
	sound=Sound.new();add_child(sound)
	player=Operator.new();player.raid=self;add_child(player);player.position=Vector3(-25,.1,23);player.rotation.y=-.72
	hud=Interface.new();hud.raid=self;add_child(hud)
	spawn_guards()
	bag.changed.connect(func():if is_instance_valid(hud):hud.refresh_inventory())
func setup_input():
	var keys={"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"jump":KEY_SPACE,"sprint":KEY_SHIFT,"crouch":KEY_CTRL,"reload":KEY_R,"heal":KEY_4,"interact":KEY_F,"inventory":KEY_TAB,"pause":KEY_ESCAPE}
	for action in keys:
		if not InputMap.has_action(action):InputMap.add_action(action)
		var e=InputEventKey.new();e.physical_keycode=keys[action];InputMap.action_add_event(action,e)
	for action in ["fire","aim"]:
		if not InputMap.has_action(action):InputMap.add_action(action)
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT if action=="fire" else MOUSE_BUTTON_RIGHT;InputMap.action_add_event(action,e)
func setup_environment():
	var env=WorldEnvironment.new();var e=Environment.new();env.environment=e;add_child(env)
	e.background_mode=Environment.BG_SKY
	var sky=Sky.new();var sm=ProceduralSkyMaterial.new()
	sm.sky_top_color=Color("355765");sm.sky_horizon_color=Color("bdc5c0");sm.ground_horizon_color=Color("bdc5c0");sm.ground_bottom_color=Color("393f3d");sm.sun_angle_max=6;sm.sun_curve=.06
	var panorama=PanoramaSkyMaterial.new();panorama.panorama=load("res://assets/vendor/ambientcg/sky.hdr");sky.sky_material=panorama;e.sky=sky;e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("acc3ca");e.ambient_light_energy=.43
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC;e.tonemap_exposure=.95
	e.fog_enabled=true;e.fog_light_color=Color("9aadae");e.fog_light_energy=.7;e.fog_density=.002
	var sun=DirectionalLight3D.new();add_child(sun);sun.rotation_degrees=Vector3(-31,-38,0);sun.light_color=Color("ffdcaa");sun.light_energy=1.15;sun.shadow_enabled=true;sun.directional_shadow_max_distance=100;sun.shadow_bias=.07
func surface(kind:String,color:Color)->StandardMaterial3D:
	if materials.has(kind):return materials[kind]
	var real_surfaces={"asphalt":"Asphalt021","concrete":"Concrete012","brick":"Bricks066"}
	if real_surfaces.has(kind):
		var material=Kit.ground_pbr(real_surfaces[kind]);materials[kind]=material;return material
	var imported={"steel":"tile_painted_gun_metal"}
	if imported.has(kind):
		var ready_material=Kit.pbr(imported[kind],true);materials[kind]=ready_material;return ready_material
	var noise=FastNoiseLite.new();noise.seed=kind.hash();noise.frequency=.07
	var image=Image.create(256,256,false,Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var n=noise.get_noise_2d(x,y)*.5+.5
			var factor=.72+n*.48
			if kind=="steel":factor*=.72 if x%24<3 else 1.0
			if kind=="concrete" and (y%100<2 or x%128<2):factor*=.7
			if kind=="asphalt":factor=.85+n*.25+randf_range(-.08,.08)
			image.set_pixel(x,y,Color(color.r*factor,color.g*factor,color.b*factor))
	image.generate_mipmaps()
	var m=StandardMaterial3D.new();m.albedo_texture=ImageTexture.create_from_image(image);m.uv1_triplanar=true;m.uv1_world_triplanar=true;m.uv1_scale=Vector3(.35,.35,.35);m.roughness=.91
	if kind=="steel":m.metallic=.45;m.roughness=.68
	materials[kind]=m;return m
func structure(pos:Vector3,size:Vector3,material:Material,obstacle:bool=true)->MeshInstance3D:
	var mesh=Kit.box(self,pos,size,Color.WHITE,true);mesh.material_override=material
	if obstacle and pos.y-size.y/2<1.8 and pos.y+size.y/2>.25:blockers.append(Rect2(Vector2(pos.x-size.x/2,pos.z-size.z/2),Vector2(size.x,size.z)))
	return mesh
func build_map():
	var concrete=surface("concrete",Color("8f9186"));var steel=surface("steel",Color("536c6b"));var asphalt=surface("asphalt",Color("41494a"));var brick=surface("brick",Color("806955"))
	structure(Vector3(0,-.3,0),Vector3(70,.6,66),asphalt,false)
	for x in [-35,35]:structure(Vector3(x,2.4,0),Vector3(.5,4.8,66),concrete)
	for z in [-33,33]:structure(Vector3(0,2.4,z),Vector3(70,4.8,.5),concrete)
	for x in [-33,33]:
		for z in range(-30,32,5):
			Kit.box(self,Vector3(x,4.85,z),Vector3(.08,.8,.08),Color("3b4140"))
			Kit.box(self,Vector3(x,5.15,z),Vector3(.05,.05,5),Color("545957"))
	# Broken-up asphalt and painted circulation lanes.
	for z in range(-28,30,6):
		Kit.box(self,Vector3(0,.012,z),Vector3(.13,.015,2.6),Color("b8ad82"))
	for x in range(-28,30,5):Kit.box(self,Vector3(x,.014,18),Vector3(3.8,.018,.12),Color("a4a18b"))
	for i in 45:
		var p=Vector3(rng.randf_range(-32,32),.018,rng.randf_range(-30,30))
		Kit.box(self,p,Vector3(rng.randf_range(.2,1.6),.015,rng.randf_range(.1,.5)),Color("373f40")).rotation.y=rng.randf()*TAU
	# Warehouse footprint x=-24..-4, z=-19..3, southern and eastern entrances.
	structure(Vector3(-14,.05,-8),Vector3(20,.1,22),concrete,false)
	structure(Vector3(-24,2.5,-8),Vector3(.4,5,22),concrete)
	structure(Vector3(-14,2.5,-19),Vector3(20,5,.4),concrete)
	structure(Vector3(-20,2.5,3),Vector3(8,5,.4),concrete)
	structure(Vector3(-7.5,2.5,3),Vector3(7,5,.4),concrete)
	structure(Vector3(-4,2.5,-15),Vector3(.4,5,8),concrete)
	structure(Vector3(-4,2.5,-2),Vector3(.4,5,10),concrete)
	structure(Vector3(-4,4.4,-9),Vector3(.4,1.2,4),steel,false)
	structure(Vector3(-14,4.55,3),Vector3(4,1,.4),steel,false)
	# Pitched industrial roof with bright skylight gaps.
	for x in [-21.5,-16.5,-11.5,-6.5]:
		structure(Vector3(x,5.05,-8),Vector3(4.2,.18,22),steel,false)
	for z in [-18,-12,-6,0,3]:
		Kit.box(self,Vector3(-14,4.7,z),Vector3(20,.19,.18),Color("3f4847"))
		for x in [-23.65,-4.35]:Kit.box(self,Vector3(x,2.4,z),Vector3(.22,4.8,.25),Color("404a48"))
	for z in [-14,-6]:
		lamp(Vector3(-14,4.55,z),Color("ffcc91"),2.0,9)
		Kit.box(self,Vector3(-14,4.5,z),Vector3(1.7,.1,.32),Color("fff0c4")).material_override=Kit.mat(Color("ffdea1"),0,2)
	var sign=Kit.label(self,Vector3(-14,3.55,3.24),"02 / FREIGHT DEPOT",48,Color("dfd5ab"));sign.no_depth_test=false
	# Facade details break up the building silhouette and establish scale.
	for x in [-23,-19,-9,-5]:
		Kit.box(self,Vector3(x,2.2,3.23),Vector3(.13,4.3,.14),Color("495a59"))
	Kit.box(self,Vector3(-14,5.14,3.15),Vector3(20.4,.18,.35),Color("465957"))
	Kit.label(self,Vector3(-20,1.8,3.24),"AUTHORIZED
PERSONNEL ONLY",19,Color("dbac64"))
	for x in [-21.5,-7]:
		Kit.box(self,Vector3(x,3.4,3.23),Vector3(2.4,.65,.06),Color("243b42"))
		for dx in [-1.2,0,1.2]:Kit.box(self,Vector3(x+dx,3.4,3.28),Vector3(.05,.68,.05),Color("7b8a83"))
	for z in [-16,-9]:
		Kit.box(self,Vector3(25.2,1.2,z),Vector3(.45,1.3,1.2),Color("677773"))
		for h in range(5):Kit.box(self,Vector3(25.44,.8+h*.14,z),Vector3(.02,.035,1.0),Color("283f43"))
	# Shelves with distinct passageways.
	for x in [-21,-8]:
		for z in [-13,-6]:
			for level in [.4,1.5,2.6]:
				structure(Vector3(x,level,z),Vector3(2,.13,3.8),steel)
				for dz in [-1.1,.4]:Kit.box(self,Vector3(x,level+.4,z+dz),Vector3(1.3,.7,.95),Color("8d8061"))
			for dx in [-.94,.94]:
				for dz in [-1.8,1.8]:Kit.box(self,Vector3(x+dx,1.5,z+dz),Vector3(.10,3,.10),Color("4d605e"))
	# Medical office, two doors, glazed windows in the west wall.
	structure(Vector3(17,.07,-10),Vector3(16,.14,16),concrete,false)
	structure(Vector3(17,1.8,-18),Vector3(16,3.6,.3),brick)
	structure(Vector3(25,1.8,-10),Vector3(.3,3.6,16),brick)
	for x in [11,21]:structure(Vector3(x,1.8,-2),Vector3(4,3.6,.3),concrete)
	structure(Vector3(16,3.1,-2),Vector3(6,1,.3),concrete,false)
	for z in [-16,-4]:structure(Vector3(9,1.8,z),Vector3(.3,3.6,4),concrete)
	structure(Vector3(9,.55,-10),Vector3(.3,1.1,8),concrete)
	structure(Vector3(9,3.1,-10),Vector3(.3,1,8),concrete,false)
	for z in [-12,-8]:structure(Vector3(9,1.8,z),Vector3(.3,1.5,.10),steel)
	structure(Vector3(17,3.68,-10),Vector3(16,.18,16),steel,false)
	# Inner partition with an open doorway.
	structure(Vector3(14,1.8,-11),Vector3(10,3.6,.16),concrete)
	structure(Vector3(24,1.8,-11),Vector3(2,3.6,.16),concrete)
	Kit.label(self,Vector3(17,2.7,-1.8),"MEDICAL / ADMIN",35,Color("e8dfc1"))
	for p in [Vector3(13,.45,-15),Vector3(20,.45,-15)]:
		structure(p,Vector3(2,.9,1),steel);Kit.box(self,p+Vector3(0,.52,0),Vector3(2.05,.15,1.05),Color("b9b8a0"))
	for x in [12,15,22]:
		structure(Vector3(x,.75,-5),Vector3(1.4,1.5,.7),steel)
		Kit.box(self,Vector3(x,1.55,-5),Vector3(1.5,.1,.8),Color("b1ab91"))
	lamp(Vector3(17,3.3,-7),Color("a7d8d9"),2.2,11)
	lamp(Vector3(16,3.2,-15),Color("ffd2a2"),1.6,9)
	# Shipping containers: ribbed panels, locking rods and serial markings.
	for spec in [[Vector3(-18,0,13),false],[Vector3(12,0,11),true],[Vector3(24,0,19),false],[Vector3(-10,0,-26),true]]:
		container(spec[0],spec[1],steel)
	# Concrete barriers and loading cover.
	for p in [Vector3(-2,.65,8),Vector3(7,.65,1),Vector3(-1,.65,-17),Vector3(23,.65,-24),Vector3(-28,.65,5)]:
		structure(p,Vector3(4,1.3,.75),concrete)
		for x in range(-3,4):Kit.box(self,p+Vector3(x*.45,.22,.39),Vector3(.23,.22,.015),Color("d7aa46")).rotation.z=-.6
	for p in [Vector3(-28,.55,15),Vector3(3,.55,-8),Vector3(6,.55,22),Vector3(-18,.55,-23)]:
		structure(p,Vector3(1.6,1.1,1.5),surface("wood",Color("8e7c5a"))).visible=false
		Kit.prop(self,p-Vector3(0,.55,0),"crate",1.1)
		for x in [-.62,.62]:Kit.box(self,p+Vector3(x,0,.77),Vector3(.08,1.12,.06),Color("3d4945"))
	for p in [Vector3(-2,0,24),Vector3(28,0,6),Vector3(3,0,-25)]:
		for n in 3:
			var b=p+Vector3(n*.8,0,0);structure(b+Vector3(0,.55,0),Vector3(.65,1.1,.65),steel).visible=false
			Kit.prop(self,b,"barrel",1.15)
	# Imported industrial props with local matching static collision.
	for p in [Vector3(-16,0,-10),Vector3(-17,0,-14),Vector3(4,0,6),Vector3(29,0,13)]:
		structure(p+Vector3(0,.5,0),Vector3(1.65,1,2),steel).visible=false
		Kit.prop(self,p,"cargo",1)
	for p in [Vector3(-22,0,6),Vector3(26,0,-7),Vector3(-5,0,22)]:Kit.prop(self,p,"pallet",.16)
	for p in [Vector3(-26,0,-17),Vector3(26,0,-16)]:
		Kit.prop(self,p,"gas_tank",1.7)
	for p in [Vector3(-23,0,1),Vector3(23,0,-2)]:Kit.prop(self,p,"floodlight",2.1)
	# Exterior lamps, cables, curbs and perimeter silhouettes.
	for p in [Vector3(-28,0,-24),Vector3(29,0,27),Vector3(-29,0,26),Vector3(28,0,-27)]:
		Kit.cylinder(self,p+Vector3(0,3.5,0),.08,7,Color("373f40"))
		Kit.box(self,p+Vector3(0,6.9,0),Vector3(.9,.14,.4),Color("e2c187"))
		lamp(p+Vector3(0,6.6,0),Color("ffbc70"),2.4,12)
	for i in 22:
		var x=-48+i*4.5;var h=rng.randf_range(6,14)
		Kit.box(self,Vector3(x,h/2,-43),Vector3(3.8,h,6),Color("535e60"))
	# Searchable supply points. Each has a deliberate placement and loot pool.
	make_loot(Vector3(-21,1.05,-11),"DEPOT TOOL CASE",roll_loot(),Vector3(.8,.42,.55),Color("8b8056"))
	make_loot(Vector3(-10,.35,-15),"SEALED FREIGHT",[{"id":"drive","qty":1},{"id":"alloy","qty":2}],Vector3(1.2,.7,.8),Color("748b83"))
	make_loot(Vector3(20,1.08,-15),"MEDICAL SUPPLIES",[{"id":"med","qty":2},{"id":"water","qty":1}],Vector3(.75,.45,.5),Color("abb7a2"))
	make_loot(Vector3(15,1.7,-5),"ADMIN LOCKBOX",[{"id":"drive","qty":1},{"id":"circuit","qty":2}],Vector3(.6,.28,.5),Color("738689"))
	make_loot(Vector3(6,1.3,22),"FIELD AMMUNITION",[{"id":"ammo","qty":60},{"id":"med","qty":1}],Vector3(.8,.4,.5),Color("7d8867"))
	make_loot(Vector3(-27,.3,22),"ABANDONED PACK",[{"id":"water","qty":1},{"id":"circuit","qty":1}],Vector3(.65,.6,.65),Color("797c64"))
	make_loot(Vector3(3,.35,-24),"UTILITY CACHE",roll_loot(),Vector3(.9,.7,.6),Color("8b8056"))
	# Extraction threshold, striped gate and visible green beacon.
	for x in [23,30]:Kit.box(self,Vector3(x,2.4,-29),Vector3(.22,4.8,.22),Color("d0b67a"))
	Kit.box(self,Vector3(26.5,4.7,-29),Vector3(7.2,.2,.2),Color("d0b67a"))
	Kit.label(self,Vector3(26.5,3.8,-28.8),"NORTH GATE\nEXTRACTION",42,Color("88d2b4"))
	for x in [23,29]:
		var beacon=Kit.cylinder(self,Vector3(x,.22,-25),.13,.44,Color("72e7af"));beacon.material_override=Kit.mat(Color("6df3b1"),0,2)
		lamp(Vector3(x,.8,-25),Color("62e0a0"),1.8,5)
	for z in [-28,-22]:Kit.box(self,Vector3(26,.025,z),Vector3(6,.03,.10),Color("7fbda3"))
	for x in [23,29]:Kit.box(self,Vector3(x,.025,-25),Vector3(.10,.03,6),Color("7fbda3"))
func container(p:Vector3,sideways:bool,material:Material):
	var s=Vector3(9,2.8,3) if sideways else Vector3(3,2.8,9)
	structure(p+Vector3(0,1.4,0),s,material)
	var length=int(s.z/.35)
	for i in length:
		for dx in [-1,1]:Kit.box(self,p+Vector3(dx*(s.x/2+.025),1.4,-s.z/2+i*.35),Vector3(.06,2.65,.06),Color("697c77"))
	for x in [-.8,.8]:Kit.box(self,p+Vector3(x,1.4,s.z/2+.04),Vector3(.04,2.5,.04),Color("b5b7a3"))
	Kit.label(self,p+Vector3(0,1.7,s.z/2+.07),"DF / 042\nFREIGHT",28,Color("c8d0bd"))
func lamp(pos:Vector3,color:Color,energy:float,radius:float):
	var l=OmniLight3D.new();add_child(l);l.position=pos;l.light_color=color;l.light_energy=energy;l.omni_range=radius;l.omni_attenuation=1.4
func roll_loot()->Array:
	return [{"id":"alloy","qty":rng.randi_range(1,2)},{"id":"ammo","qty":rng.randi_range(12,32)},{"id":"circuit","qty":1}]
func make_loot(pos:Vector3,title:String,contents:Array,size:Vector3,color:Color)->StaticBody3D:
	var body=StaticBody3D.new();add_child(body);body.position=pos;body.collision_layer=8
	body.set_meta("loot",contents.duplicate(true));body.set_meta("title",title)
	var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)
	Kit.box(body,Vector3.ZERO,size,color)
	for dx in [-.28,.28]:Kit.box(body,Vector3(dx*size.x,0,size.z/2+.006),Vector3(.045,size.y*.9,.018),Color("343f3b"))
	Kit.box(body,Vector3(0,size.y/2+.01,0),Vector3(size.x*.3,.02,.06),Color("c6c9a7"))
	loot.append(body);return body
func setup_grid():
	grid.region=Rect2i(-34,-32,69,65);grid.cell_size=Vector2.ONE;grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
	for x in range(-34,35):
		for z in range(-32,33):
			for r in blockers:
				if r.grow(.45).has_point(Vector2(x,z)):grid.set_point_solid(Vector2i(x,z));break
func nearest_cell(pos:Vector3)->Vector2i:
	var cell=Vector2i(clampi(roundi(pos.x),-34,34),clampi(roundi(pos.z),-32,32))
	if not grid.is_point_solid(cell):return cell
	for r in range(1,6):
		for x in range(-r,r+1):
			for z in range(-r,r+1):
				var c=cell+Vector2i(x,z)
				if grid.is_in_boundsv(c) and not grid.is_point_solid(c):return c
	return cell
func route(from:Vector3,to:Vector3)->PackedVector3Array:
	var a=nearest_cell(from);var b=nearest_cell(to);var result=PackedVector3Array()
	if grid.is_point_solid(a) or grid.is_point_solid(b):return result
	var points=grid.get_id_path(a,b)
	for i in range(1,points.size()):result.append(Vector3(points[i].x,.05,points[i].y))
	return result
func spawn_guards():
	var spawns=[Vector3(-14,.1,-12),Vector3(-14,.1,-4),Vector3(17,.1,-7),Vector3(21,.1,-15),Vector3(5,.1,-21),Vector3(23,.1,4),Vector3(7,.1,16),Vector3(-27,.1,-22),Vector3(26,.1,25),Vector3(-3,.1,-27)]
	for i in range(spawns.size()-1,0,-1):
		var j=rng.randi_range(0,i);var tmp=spawns[i];spawns[i]=spawns[j];spawns[j]=tmp
	for i in 5:
		var guard=Guard.new();guard.raid=self;guard.ident=i;add_child(guard);guard.position=spawns[i];guard.home=spawns[i];enemies.append(guard)
func start():
	started=true;active=true;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;hud.show_game()
func _physics_process(delta):
	if not active:return
	time_left-=delta
	if time_left<=0:finish(false);return
	if player.global_position.distance_to(extract_pos)<3 and player.health>0:
		extract_time+=delta
		if extract_time>=6:finish(true)
	else:extract_time=0
func finish(success:bool):
	if not active:return
	active=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if success:
		saved_credits+=bag.value();saved_raids+=1;save_profile()
	hud.show_result(success)
func impact(pos:Vector3,normal:Vector3):
	var marker=Kit.box(self,pos+normal*.009,Vector3(.035,.035,.006),Color("172022"))
	if absf(normal.dot(Vector3.UP))<.99:marker.look_at(pos+normal,Vector3.UP)
	else:marker.rotation.x=PI/2
	impact_nodes.append(marker)
	if impact_nodes.size()>35:impact_nodes.pop_front().queue_free()
func load_profile():
	var config=ConfigFile.new()
	if config.load("user://profile.cfg")==OK:
		saved_credits=int(config.get_value("profile","credits",0));saved_raids=int(config.get_value("profile","raids",0))
func save_profile():
	var config=ConfigFile.new();config.set_value("profile","credits",saved_credits);config.set_value("profile","raids",saved_raids);config.save("user://profile.cfg")
