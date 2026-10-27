#!/usr/bin/env python3
"""Build a source-only Studio place without external dependencies or plugins."""
from pathlib import Path
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
serial=0

def item(parent, cls, name):
 global serial
 serial+=1
 node=ET.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{serial}'})
 props=ET.SubElement(node,'Properties')
 ET.SubElement(props,'string',{'name':'Name'}).text=name
 return node,props

def directory(parent, path):
 for file in sorted(path.iterdir()):
  if file.is_dir():
   node,_=item(parent,'Folder',file.name); directory(node,file)
  elif file.suffix=='.luau':
   cls='Script' if file.name.endswith('.server.luau') else 'LocalScript' if file.name.endswith('.client.luau') else 'ModuleScript'
   name=file.name.replace('.server.luau','').replace('.client.luau','').removesuffix('.luau')
   _,props=item(parent,cls,name)
   ET.SubElement(props,'ProtectedString',{'name':'Source'}).text=file.read_text()

def build():
 global serial
 serial=0
 doc=ET.Element('roblox',{'version':'4'})
 ET.SubElement(doc,'External').text='null'; ET.SubElement(doc,'External').text='nil'
 world,props=item(doc,'Workspace','Workspace')
 ET.SubElement(props,'bool',{'name':'StreamingEnabled'}).text='true'
 for service in ['ReplicatedStorage','ServerScriptService']:
  node,_=item(doc,service,service); directory(node,ROOT/'src'/service)
 starter,_=item(doc,'StarterPlayer','StarterPlayer')
 scripts,_=item(starter,'StarterPlayerScripts','StarterPlayerScripts')
 directory(scripts,ROOT/'src/StarterPlayer/StarterPlayerScripts')
 output=ROOT/'dist/Yardwork.rbxlx'; output.parent.mkdir(exist_ok=True)
 ET.indent(doc)
 ET.ElementTree(doc).write(output,encoding='utf-8',xml_declaration=True)
 parsed=ET.parse(output)
 sources=parsed.findall('.//ProtectedString')
 assert len(sources)==len(list((ROOT/'src').rglob('*.luau')))
 print(f'Built {output.name}: {len(sources)} embedded scripts')
if __name__=='__main__': build()
