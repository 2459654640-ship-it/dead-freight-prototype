import bpy,pathlib
root=pathlib.Path(__file__).resolve().parents[1]/'assets/vendor/unvanquished'
bpy.ops.wm.open_mainfile(filepath=str(root/'source/human.blend'),load_ui=False)
for o in list(bpy.data.objects):
 if o.type not in ['MESH','ARMATURE'] or o.name in ['Plane','rifle','shotugnbody01','models/weapons/psaw/saw_thirdperson']:bpy.data.objects.remove(o,do_unlink=True)
# Rebuild the clothing and equipment as contemporary field gear.
import math
from mathutils import Vector
for o in list(bpy.data.objects):
 if o.name.startswith('armor_') or o.name=='helmet':bpy.data.objects.remove(o,do_unlink=True)
def fabric(name,color,camo=False):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;p=n.get('Principled BSDF');p.inputs['Roughness'].default_value=.93
 if camo:
  tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=7;tex.inputs['Detail'].default_value=1.5
  ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.interpolation='CONSTANT';ramp.color_ramp.elements.remove(ramp.color_ramp.elements[1]);colors=[(.28,(.08,.10,.055,1)),(.43,(.20,.22,.12,1)),(.57,(.34,.31,.19,1)),(.68,(.13,.16,.08,1))]
  for i,(v,c) in enumerate(colors):
   e=ramp.color_ramp.elements[0] if i==0 else ramp.color_ramp.elements.new(v);e.position=v;e.color=c
  m.node_tree.links.new(tex.outputs['Fac'],ramp.inputs['Fac']);m.node_tree.links.new(ramp.outputs['Color'],p.inputs['Base Color'])
 else:p.inputs['Base Color'].default_value=(*color,1)
 return m
cloth=fabric('Modern woodland field uniform',(.2,.25,.13),True);gear=fabric('Ranger green Cordura',(.14,.17,.095));dark=fabric('Rubber and gloves',(.025,.031,.025))
for mat in list(bpy.data.materials):
 if 'head' in mat.name:
  mat.use_nodes=True;n=mat.node_tree.nodes;n.clear();out=n.new('ShaderNodeOutputMaterial');p=n.new('ShaderNodeBsdfPrincipled');p.inputs['Roughness'].default_value=.8;tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(root/'source/head.jpg'));mat.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color']);mat.node_tree.links.new(p.outputs[0],out.inputs[0])
body=bpy.data.objects['body'];body.data.materials.clear();body.data.materials.append(cloth);body.data.materials.append(dark)
for face in body.data.polygons:
 z=sum((body.matrix_world@body.data.vertices[i].co).z for i in face.vertices)/len(face.vertices)
 if z<1.25:face.material_index=1
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
def attach(o,bone):
 o.data.transform(o.matrix_world)
 o.parent=arm;o.matrix_parent_inverse.identity();o.matrix_basis.identity()
 group=o.vertex_groups.new(name=bone);group.add(list(range(len(o.data.vertices))),1.0,'REPLACE')
 mod=o.modifiers.new('Rigid bone binding','ARMATURE');mod.object=arm
 return o
def block(name,pos,size,bone='ribs',material=gear):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material)
 mod=o.modifiers.new('Rounded fabric edges','BEVEL');mod.width=.10;mod.segments=3
 o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');return attach(o,bone)
block('Plate_carrier',(0,-.30,9.4),(3.25,1.75,3.15))
for x in [-1.25,1.25]:block('Shoulder_webbing',(x,-.2,11.0),(.52,1.55,1.45))
for x in [-1.02,0,1.02]:
 block('Magazine_pouch',(x,-1.38,8.8),(.87,.65,1.52))
 for z in [8.4,8.8,9.2]:block('MOLLE_stitch',(x,-1.73,z),(.77,.08,.12),material=dark)
block('Radio',(-1.25,-1.23,10.2),(.6,.45,1.15),material=dark)
block('Antenna',(-1.25,-1.23,11.2),(.06,.06,1.3),material=dark)
block('Patrol_pack',(0,1.1,9.35),(2.6,1.1,2.9))
block('Utility_belt',(0,-.1,6.8),(3.1,1.95,.38),bone='hips',material=dark)
# Open-faced modern ballistic helmet shell, with no full-face visor or sci-fi plates.
verts=[];faces=[];segments=32;rings=10
for j in range(rings+1):
 theta=(math.pi/2+.12)*j/rings
 for i in range(segments):
  phi=2*math.pi*i/segments;verts.append((.96*math.sin(theta)*math.cos(phi),-.45+1.05*math.sin(theta)*math.sin(phi),13.1+.88*math.cos(theta)))
for j in range(rings):
 for i in range(segments):a=j*segments+i;b=j*segments+(i+1)%segments;faces.append((a,b,b+segments,a+segments))
mesh=bpy.data.meshes.new('Helmet_shell');mesh.from_pydata(verts,[],faces);o=bpy.data.objects.new('Modern_ballistic_helmet',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(gear);sol=o.modifiers.new('Shell thickness','SOLIDIFY');sol.thickness=.055
for face in mesh.polygons:face.use_smooth=True
attach(o,'head')
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
# Bake the procedural woodland cloth into a portable UV texture for glTF.
bpy.context.scene.render.engine='CYCLES';bpy.context.scene.cycles.samples=1
image=bpy.data.images.new('Woodland_uniform',width=1024,height=1024)
for material in [cloth,dark]:
 node=material.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;material.node_tree.nodes.active=node
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);bpy.context.view_layer.objects.active=body
bpy.ops.object.bake(type='DIFFUSE',pass_filter={'COLOR'},margin=8)
node=cloth.node_tree.nodes.active;p=cloth.node_tree.nodes.get('Principled BSDF')
for link in list(p.inputs['Base Color'].links):cloth.node_tree.links.remove(link)
cloth.node_tree.links.new(node.outputs['Color'],p.inputs['Base Color'])
image.pack()
arm.animation_data.action=None
for tr in list(arm.animation_data.nla_tracks):arm.animation_data.nla_tracks.remove(tr)
for source,target in [('stand','Man_Idle'),('walk','Man_Walk'),('run','Man_Run'),('attack','Fire')]:
 a=bpy.data.actions.get(source)
 if a:
  tr=arm.animation_data.nla_tracks.new();tr.name=target;st=tr.strips.new(target,1,a);st.name=target
bpy.context.scene.frame_set(1)
bpy.ops.export_scene.gltf(filepath=str(root/'modern_guard.glb'),export_format='GLB',export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_animations=True)
