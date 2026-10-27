"""Run in Blender: validate all FBX exports can be re-imported with outward faces."""
from pathlib import Path
import json
import bpy,bmesh
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'assets/blender'
manifest=json.loads((folder/'model-manifest.json').read_text())
results=[]
for item in manifest:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.fbx(filepath=str(folder/item['file']))
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 assert len(objects)==item['objects'],item['file']
 triangles=0
 for o in objects:
  assert len(o.data.materials)>0,(item['file'],o.name,'missing palette')
  mesh=bmesh.new();mesh.from_mesh(o.data)
  assert mesh.calc_volume(signed=True)>0,(item['file'],o.name,'inward or empty mesh')
  mesh.free()
  triangles+=sum(len(p.vertices)-2 for p in o.data.polygons)
 results.append(dict(file=item['file'],objects=len(objects),exported_triangles=triangles,imported=True,outward_normals=True))
(folder/'import-validation.json').write_text(json.dumps(results,indent=2))
print('PASS',len(results),'FBX imports, material assignments and signed-volume checks')
