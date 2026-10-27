"""Run with: blender --background --python tools/build_blender_assets.py
Reads the geometry exported from WorldArt; creates original .blend and FBX assets.
Preview is a Blender render, not a Roblox runtime screenshot.
"""
from pathlib import Path
import json, math
import bpy
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/blender'
data=json.loads((OUT/'scene.json').read_text())
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for c in list(bpy.data.collections):
 if c.name!='Collection' and c.users==0:bpy.data.collections.remove(c)
materials={}
def material(rgb,emission=False):
 key=tuple(round(v,4) for v in rgb)+(emission,)
 if key in materials:return materials[key]
 linear=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
 m=bpy.data.materials.new('Palette_'+str(len(materials)));m.diffuse_color=(*linear,1);m.use_nodes=True
 bsdf=m.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(*linear,1);bsdf.inputs['Roughness'].default_value=.78
 if emission:bsdf.inputs['Emission Color'].default_value=(*linear,1);bsdf.inputs['Emission Strength'].default_value=.5
 materials[key]=m;return m
# Roblox (X,Y-up,Z) -> Blender (X,-Z,Y-up), preserving handedness.
convert=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
objects={};groups={}
def transform(cf):return Matrix((cf[0:4],cf[4:8],cf[8:12],[0,0,0,1]))
for p in data['parts']:
 sx,sy,sz=p['size'];shape=p['shape'];cls=p['cls']
 if cls=='WedgePart':
  verts=[(-.5,-.5,-.5),(.5,-.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(-.5,.5,.5),(.5,.5,.5)]
  verts=[(x*sx,y*sy,z*sz) for x,y,z in verts]
  faces=[tuple(reversed(face)) for face in [(0,2,3,1),(2,4,5,3),(0,1,5,4),(0,4,2),(1,3,5)]]
  mesh=bpy.data.meshes.new(p['name']);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(p['name'],mesh);bpy.context.collection.objects.link(o)
 elif shape=='Cylinder':
  verts=[]
  for x in [-sx/2,sx/2]:
   for i in range(10):a=math.tau*i/10;verts.append((x,math.cos(a)*sy/2,math.sin(a)*sz/2))
  faces=[tuple(range(9,-1,-1)),tuple(range(10,20))]+[(i,(i+1)%10,(i+1)%10+10,i+10) for i in range(10)]
  mesh=bpy.data.meshes.new(p['name']);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(p['name'],mesh);bpy.context.collection.objects.link(o)
 else:
  bpy.ops.mesh.primitive_cube_add(size=1);o=bpy.context.object;o.name=p['name'];o.scale=(sx,sy,sz)
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.matrix_world=convert@transform(p['cf'])
 o.data.materials.append(material(p['color'],p['material']=='Neon'))
 # Flat bevels are an optional Blender finish; runtime Parts stay lightweight.
 if min(sx,sy,sz)>.15 and p['name'] not in ['MineBlock','Foundation']:
  mod=o.modifiers.new('Small flat edge bevel','BEVEL');mod.width=min(.055,min(sx,sy,sz)*.09);mod.segments=1
 o['RobloxPartId']=p['id'];o['RuntimeGroup']=p['group'];o['OriginalRuntimeGeometry']=True
 objects[p['id']]=o;groups.setdefault(p['group'],[]).append(o)
# Sign lettering from SurfaceGui content, for the art preview only.
lookup={p['id']:p for p in data['parts']}
text_count={}
for label in data['texts']:
 p=lookup.get(label['part'])
 if not p:continue
 ordinal=text_count.get(p['id'],0);text_count[p['id']]=ordinal+1
 size=p['size'];cf=transform(p['cf'])
 font=bpy.data.curves.new('OriginalSign','FONT');font.body=label['text'];font.align_x='CENTER';font.align_y='CENTER';font.size=min(size[1]*(.32 if ordinal==0 else .13),size[0]/max(1,len(label['text']))*1.35);font.extrude=.002
 o=bpy.data.objects.new('Lettering',font);bpy.context.collection.objects.link(o)
 offset=Matrix.Translation((0,size[1]*(.13 if ordinal==0 else -.3),-size[2]/2-.02))
 orient=Matrix(((-1,0,0,0),(0,1,0,0),(0,0,-1,0),(0,0,0,1)))
 o.matrix_world=convert@cf@offset@orient;o.data.materials.append(material([.97,.94,.84] if ordinal==0 else [.43,.76,.56]))
# Individual assets export around a sensible bottom-centred origin.
export_groups={'guard_tower':'GuardTower','warden_milo':'WardenMilo','ore_cart':'OreCart','workshop_stall':'THE WORKSHOPStall','sell_stall':'ORE EXCHANGEStall','supply_crate':'SupplyCrate','yard_pickaxe':'YardPickaxe','quarry_tree':'QuarryTree'}
manifest=[]
for filename,group in export_groups.items():
 selected=groups.get(group,[])
 if group in ['SupplyCrate','QuarryTree']:selected=[o for o in selected if o.location.x<0]
 assert selected,group
 bpy.ops.object.select_all(action='DESELECT')
 old={o:o.matrix_world.copy() for o in selected}
 points=[o.matrix_world@Vector(c) for o in selected for c in o.bound_box]
 centre=Vector(((min(v.x for v in points)+max(v.x for v in points))/2,(min(v.y for v in points)+max(v.y for v in points))/2,min(v.z for v in points)))
 for o in selected:o.location-=centre;o.select_set(True)
 bpy.context.view_layer.objects.active=selected[0]
 bpy.ops.export_scene.fbx(filepath=str(OUT/(filename+'.fbx')),use_selection=True,object_types={'MESH'},apply_unit_scale=True,axis_forward='-Z',axis_up='Y',use_mesh_modifiers=True,bake_anim=False,add_leaf_bones=False)
 triangles=sum(sum(len(poly.vertices)-2 for poly in o.data.polygons) for o in selected)
 manifest.append(dict(file=filename+'.fbx',runtime_group=group,source_triangles_before_bevel=triangles,objects=len(selected)))
 for o in selected:o.matrix_world=old[o]
(OUT/'model-manifest.json').write_text(json.dumps(manifest,indent=2))
# The detached tool library model is stored in the file but hidden from the environment render.
for o in groups.get('YardPickaxe',[]):o.hide_render=True
bpy.ops.mesh.primitive_plane_add(size=2000,location=(0,0,-15.05));ground=bpy.context.object;ground.name='PreviewBackdrop';ground.data.materials.append(material([.58,.65,.58]))
world=bpy.context.scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.73,.81,.86,1);world.node_tree.nodes['Background'].inputs[1].default_value=.65
bpy.ops.object.light_add(type='SUN',location=(0,-30,60));sun=bpy.context.object;sun.rotation_euler=(math.radians(26),math.radians(-18),math.radians(-24));sun.data.energy=2.2;sun.data.angle=.2
bpy.ops.object.light_add(type='AREA',location=(0,-20,60));light=bpy.context.object;light.data.energy=3000;light.data.shape='DISK';light.data.size=50
bpy.ops.object.camera_add(location=(87,-105,91));camera=bpy.context.object;target=Vector((-7,-2,0));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=112
scene=bpy.context.scene;scene.camera=camera;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=64;scene.cycles.use_denoising=False
scene.render.resolution_x=1400;scene.render.resolution_y=1050;scene.render.resolution_percentage=100
scene.render.threads_mode='FIXED';scene.render.threads=4
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'quarry-preview.png')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Yardwork-Art-Library.blend'))
bpy.ops.render.render(write_still=True)
print('ART_BUILD_COMPLETE',len(objects),'runtime parts',len(manifest),'FBX assets')
