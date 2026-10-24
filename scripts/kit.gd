extends RefCounted
# Original procedural meshes; no external assets or import dependencies.
static var mats:Dictionary={}
static func mat(color:Color, metal:float=0.0, emission:float=0.0)->StandardMaterial3D:
	var key=str(color)+str(metal)+str(emission)
	if mats.has(key):return mats[key]
	var m=StandardMaterial3D.new()
	m.albedo_color=color;m.roughness=.78;m.metallic=metal
	if emission>0:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=emission
	mats[key]=m
	return m
static func box(parent:Node, pos:Vector3, size:Vector3, color:Color, solid:bool=false, metal:float=0.0)->MeshInstance3D:
	var mesh=MeshInstance3D.new();var shape=BoxMesh.new();shape.size=size
	mesh.mesh=shape;mesh.material_override=mat(color,metal);parent.add_child(mesh);mesh.position=pos
	if solid:
		var body=StaticBody3D.new();parent.add_child(body);body.position=pos
		var collision=CollisionShape3D.new();var s=BoxShape3D.new();s.size=size;collision.shape=s;body.add_child(collision)
	return mesh
static func cylinder(parent:Node,pos:Vector3,radius:float,height:float,color:Color)->MeshInstance3D:
	var m=MeshInstance3D.new();var c=CylinderMesh.new();c.top_radius=radius;c.bottom_radius=radius;c.height=height;c.radial_segments=12;m.mesh=c;m.material_override=mat(color,.3);parent.add_child(m);m.position=pos;return m
static func label(parent:Node,pos:Vector3,text:String,size:int=48,color:Color=Color.WHITE)->Label3D:
	var l=Label3D.new();parent.add_child(l);l.position=pos;l.text=text;l.font_size=size;l.pixel_size=.012;l.modulate=color;l.outline_size=4;return l
static func limb(parent:Node,a:Vector3,b:Vector3,radius:float,color:Color):
	var m=cylinder(parent,(a+b)/2,radius,a.distance_to(b),color)
	m.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	return m
static func gun(parent:Node,first_person:bool=true)->Node3D:
	var g=Node3D.new();parent.add_child(g)
	if first_person:
		var view=load("res://assets/vendor/fps-community/viewmodel.glb").instantiate();g.add_child(view)
		for mesh in view.find_children("*","MeshInstance3D",true,false):
			mesh.visible=mesh.name in ["fps_arms_extended","assualt","assualt_ammo"]
			if mesh.name=="fps_arms_extended":mesh.material_override=mat(Color("9e8c74"))
			elif mesh.visible:mesh.material_override=mat(Color("26332f"),.6)
		var anim=view.find_children("*","AnimationPlayer",true,false)[0]
		g.set_meta("anim",anim);anim.play("assualt_fire");anim.advance(0);anim.pause()
		return g
	var asset=load("res://assets/vendor/flatguns/carbine.glb").instantiate()
	g.add_child(asset);asset.scale=Vector3.ONE*1.15;asset.position=Vector3(0,-.01,-.12)
	if first_person:
		var sleeve=Color("626a56");var glove=Color("3e4940")
		limb(g,Vector3(.18,-.30,.35),Vector3(.045,-.16,.12),.065,sleeve)
		limb(g,Vector3(-.22,-.26,.16),Vector3(-.07,-.08,-.35),.06,sleeve)
		limb(g,Vector3(.045,-.16,.12),Vector3(.035,-.06,.01),.052,glove)
		limb(g,Vector3(-.07,-.08,-.35),Vector3(-.025,-.03,-.43),.048,glove)
		for z in [-.40,-.43,-.46]:limb(g,Vector3(-.05,-.04,z),Vector3(.03,-.045,z),.012,glove)
	# Raised red-dot housing also makes the sight readable on the downloaded rifle.
	box(g,Vector3(0,.09,-.15),Vector3(.05,.012,.05),Color("172328"))
	for x in [-.022,.022]:box(g,Vector3(x,.116,-.15),Vector3(.007,.045,.025),Color("172328"))
	box(g,Vector3(0,.139,-.15),Vector3(.05,.007,.025),Color("172328"))
	return g
static var vendor_materials:Dictionary={}
static func pbr(name:String,triplanar:bool=false)->StandardMaterial3D:
	var key=name+str(triplanar)
	if vendor_materials.has(key):return vendor_materials[key]
	var folder="props" if name.begins_with("container") or name=="mid_cargo_box" else "structure"
	var base="res://assets/vendor/tps/level/textures/"+folder+"/"+name
	var m=StandardMaterial3D.new()
	if ResourceLoader.exists(base+"_albedo.png"):m.albedo_texture=load(base+"_albedo.png")
	else:m.albedo_color=Color("777f79")
	if ResourceLoader.exists(base+"_normal.png"):
		m.normal_enabled=true;m.normal_texture=load(base+"_normal.png");m.normal_scale=.7
	if ResourceLoader.exists(base+"_orm.png"):
		var texture=load(base+"_orm.png");m.roughness_texture=texture;m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN;m.metallic_texture=texture;m.metallic_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_BLUE;m.metallic=.55;m.ao_enabled=true;m.ao_texture=texture;m.ao_light_affect=.55
	m.roughness=.85;m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.uv1_triplanar=triplanar;m.uv1_world_triplanar=triplanar
	if triplanar:m.uv1_scale=Vector3(.28,.28,.28)
	vendor_materials[key]=m;return m
static func prop(parent:Node,pos:Vector3,kind:String,height:float=1.0)->Node3D:
	var packed=load("res://assets/vendor/tps/"+kind+".glb") as PackedScene
	var root=Node3D.new();parent.add_child(root);root.position=pos
	var scene=packed.instantiate();root.add_child(scene)
	for mesh in scene.find_children("*","MeshInstance3D",true,false):
		var bounds:AABB=mesh.get_aabb();var factor=height/maxf(bounds.size.y,.01)
		mesh.scale=Vector3.ONE*factor;mesh.position=Vector3(-bounds.get_center().x*factor,-bounds.position.y*factor,-bounds.get_center().z*factor)
		for surface in mesh.mesh.get_surface_count():
			var original=mesh.mesh.surface_get_material(surface)
			var material_name=original.resource_name if original else "mid_cargo_box"
			if material_name.begins_with("flat_emitter"):
				mesh.set_surface_override_material(surface,mat(Color("f5c28d"),0,1))
			else:mesh.set_surface_override_material(surface,pbr(material_name))
	return root
static func ground_pbr(name:String)->StandardMaterial3D:
	if vendor_materials.has(name):return vendor_materials[name]
	var path="res://assets/vendor/ambientcg/"+name
	var m=StandardMaterial3D.new();m.albedo_texture=load(path+"_Color.jpg");m.normal_enabled=true;m.normal_texture=load(path+"_NormalGL.jpg");m.normal_scale=.65;m.roughness_texture=load(path+"_Roughness.jpg");m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED;m.roughness=1
	m.uv1_triplanar=true;m.uv1_world_triplanar=true;m.uv1_scale=Vector3.ONE*.25;m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	vendor_materials[name]=m;return m
