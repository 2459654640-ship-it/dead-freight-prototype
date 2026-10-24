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
	var view=load("res://assets/vendor/finished-m4/scene.gltf").instantiate();g.add_child(view);view.scale=Vector3.ONE*.03;view.rotation.y=PI
	disable_imported_collisions(view)
	for mesh in view.find_children("*","MeshInstance3D",true,false):
		if mesh.name in ["Object_17","Object_18"]:mesh.visible=false # Optional magnifier; use the authored 1x holographic sight.
		for surface in mesh.mesh.get_surface_count():
			var original=mesh.mesh.surface_get_material(surface)
			if original is StandardMaterial3D and "lens" in original.resource_name.to_lower():
				var glass=original.duplicate();glass.albedo_texture=null;glass.albedo_color=Color(.1,.16,.14,.06);glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.metallic=0;glass.roughness=.06
				mesh.set_surface_override_material(surface,glass)
	var anim:AnimationPlayer=view.find_children("*","AnimationPlayer",true,false)[0]
	g.set_meta("anim",anim);g.set_meta("idle_clip","h2_skeleton|idle")
	anim.play("h2_skeleton|idle");anim.advance(0);anim.pause()
	if not first_person:
		for mesh in view.find_children("*","MeshInstance3D",true,false):
			if mesh.name in ["Object_10","Object_11","Object_12","Object_13"]:mesh.visible=false
		var rig:Skeleton3D=view.find_children("*","Skeleton3D",true,false)[0]
		var bone=rig.find_bone("j_gun_05")
		if bone>=0:view.position-=g.to_local(rig.to_global(rig.get_bone_global_pose(bone).origin))
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
	if kind=="barrel":return imported_prop(parent,pos,"res://assets/vendor/oil-barrel/scene.gltf",height)
	if kind in ["crate","cargo"]:return imported_prop(parent,pos,"res://assets/vendor/plastic-crate/scene.gltf",minf(height,.65))
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
			else:
				var material=pbr(material_name).duplicate();material.albedo_color=Color("a0a28a");material.roughness=.9
				mesh.set_surface_override_material(surface,material)
	return root
static func ground_pbr(name:String)->StandardMaterial3D:
	if vendor_materials.has(name):return vendor_materials[name]
	var path="res://assets/vendor/ambientcg/"+name
	var m=StandardMaterial3D.new();m.albedo_texture=load(path+"_Color.jpg");m.normal_enabled=true;m.normal_texture=load(path+"_NormalGL.jpg");m.normal_scale=.65;m.roughness_texture=load(path+"_Roughness.jpg");m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED;m.roughness=1
	var ao_path=path+"_AmbientOcclusion.jpg"
	if ResourceLoader.exists(ao_path):m.ao_enabled=true;m.ao_texture=load(ao_path);m.ao_light_affect=.65
	m.uv1_triplanar=true;m.uv1_world_triplanar=true;m.uv1_scale=Vector3.ONE*.25;m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	vendor_materials[name]=m;return m

static func imported_prop(parent:Node,pos:Vector3,path:String,height:float)->Node3D:
	var root=Node3D.new();parent.add_child(root)
	var asset=load(path).instantiate();root.add_child(asset);disable_imported_collisions(asset)
	if "plastic-crate" in path or "wooden-crate" in path:matte_imported_surfaces(asset,.82)
	var bounds=AABB();var first=true
	for mesh in asset.find_children("*","MeshInstance3D",true,false):
		var box:AABB=mesh.get_aabb()
		for i in 8:
			var point=root.to_local(mesh.to_global(box.get_endpoint(i)))
			if first:bounds=AABB(point,Vector3.ZERO);first=false
			else:bounds=bounds.expand(point)
	var factor=height/maxf(bounds.size.y,.001)
	asset.scale*=factor;asset.position-=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	root.position=pos;return root

static func disable_imported_collisions(asset:Node):
	# Sketchfab mesh names containing _col may trigger Godot collision generation.
	# Imported art is visual; gameplay collision is supplied by our actor/map bodies.
	for body in asset.find_children("*","CollisionObject3D",true,false):
		body.collision_layer=0;body.collision_mask=0

static func matte_imported_surfaces(asset:Node,roughness:float):
	for mesh in asset.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var original=mesh.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var material=original.duplicate();material.metallic=0;material.metallic_texture=null;material.roughness_texture=null;material.roughness=roughness
				mesh.set_surface_override_material(surface,material)
