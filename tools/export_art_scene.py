#!/usr/bin/env python3
"""Exercise WorldArt with a small geometry shim, export its exact parts for Blender.
This validates construction logic, not Roblox engine APIs or rendering.
"""
from pathlib import Path
import argparse,json,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
SHIM=r'''
local vector={}; vector.__index=function(t,k)
 if k=="Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z) end
 return vector[k]
end
vector.__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vector) end
vector.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},vector) end
vector.__mul=function(a,b) if type(a)=="number" then a,b=b,a end return setmetatable({X=a.X*b,Y=a.Y*b,Z=a.Z*b},vector) end
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vector) end}
Vector3.zero=Vector3.new(0,0,0); Vector3.one=Vector3.new(1,1,1)
local color={}; color.__index=color
function color:Lerp(b,t) return setmetatable({R=self.R+(b.R-self.R)*t,G=self.G+(b.G-self.G)*t,B=self.B+(b.B-self.B)*t},color) end
local Color3={fromRGB=function(r,g,b) return setmetatable({R=r/255,G=g/255,B=b/255},color) end}
function Color3.fromHSV(h,s,v)
 local i=math.floor(h*6); local f=h*6-i; local p=v*(1-s); local q=v*(1-f*s); local t=v*(1-(1-f)*s)
 local values={{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}}
 local a=values[i%6+1]; return setmetatable({R=a[1],G=a[2],B=a[3]},color)
end
local cf={}; cf.__index=cf
local CFrame={}
function CFrame.new(x,y,z)
 if type(x)=="table" then x,y,z=x.X,x.Y,x.Z end
 return setmetatable({1,0,0,x or 0,0,1,0,y or 0,0,0,1,z or 0},cf)
end
function cf.__mul(a,b)
 local r={}
 for i=0,2 do
  for j=0,2 do r[i*4+j+1]=a[i*4+1]*b[j+1]+a[i*4+2]*b[j+5]+a[i*4+3]*b[j+9] end
  r[i*4+4]=a[i*4+1]*b[4]+a[i*4+2]*b[8]+a[i*4+3]*b[12]+a[i*4+4]
 end
 return setmetatable(r,cf)
end
function CFrame.Angles(x,y,z)
 local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
 local rx=setmetatable({1,0,0,0,0,cx,-sx,0,0,sx,cx,0},cf)
 local ry=setmetatable({cy,0,sy,0,0,1,0,0,-sy,0,cy,0},cf)
 local rz=setmetatable({cz,-sz,0,0,sz,cz,0,0,0,0,1,0},cf)
 return rx*ry*rz
end
local all={}
local methods={}
local instance={__index=function(t,k)
 local p=rawget(t,"Props")
 if k=="Position" then local c=p.CFrame; return Vector3.new(c[4],c[8],c[12]) end
 return methods[k] or p[k]
end,__newindex=function(t,k,v)
 local p=rawget(t,"Props")
 if k=="Parent" and v then table.insert(v.Children,t) end
 if k=="Position" then p.CFrame=CFrame.new(v) else p[k]=v end
end}
local Instance={}
function Instance.new(class)
 local t=setmetatable({Props={ClassName=class,Name=class,CFrame=CFrame.new(),Size=Vector3.one,Color=Color3.fromRGB(150,150,150),Transparency=0},Children={},Attrs={}},instance)
 table.insert(all,t); return t
end
function methods:IsA(class) return self.ClassName==class or (class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="WedgePart" or self.ClassName=="SpawnLocation")) end
function methods:FindFirstChild(name) for _,v in self.Children do if v.Name==name then return v end end return nil end
function methods:GetChildren() return self.Children end
function methods:SetAttribute(k,v) self.Attrs[k]=v end
function methods:GetAttribute(k) return self.Attrs[k] end
function methods:Clone()
 local t=Instance.new(self.ClassName); for k,v in pairs(self.Props) do if k~="Parent" then t[k]=v end end; return t
end
local UDim2={fromScale=function(...) return {...} end}
local Enum=setmetatable({},{__index=function(t,k) local v=setmetatable({},{__index=function(_,name) return name end}); rawset(t,k,v); return v end})
local lighting=Instance.new("Lighting")
local game={GetService=function(_,name) if name=="CollectionService" then return {AddTag=function() end} elseif name=="Lighting" then return lighting end error(name) end}
'''
TAIL=r'''
local world=Instance.new("Folder")
Art.lighting()
local yard=Art.yard(world,0,1)
for y=0,2 do for x=0,5 do for z=0,5 do
 local b=Instance.new("Part"); b.Name="MineBlock"; b.Size=Vector3.one*4; b.CFrame=CFrame.new((x-2.5)*4,-2-y*4,(z-2.5)*4); b.Parent=world
 local index=if (x*13+z*7+y)%17==0 then 3 elseif (x+z+y)%4==0 then 2 else 1
 b.Color=if index==1 then Color3.fromRGB(220,224,209) elseif index==2 then Color3.fromRGB(223,139,82) else Color3.fromRGB(79,220,179)
 Art.ore(b,index,1)
end end end
local tool=Instance.new("Tool"); tool.Name="YardPickaxe"; tool.Parent=world; Art.pickaxe(tool)
assert(yard.Sell.Position.Y>0,"sell zone must be above walkway")
assert(yard.Prompt.Parent==yard.Sell,"sell prompt must belong to authoritative sell zone")
local numbers=function(v) local r={}; for _,n in v do table.insert(r,tostring(n)) end; return table.concat(r,",") end
for id,node in all do
 if node:IsA("BasePart") and node.Transparency<1 then
  local parent=node.Parent; local group="Quarry"
  while parent do if parent.ClassName=="Model" or parent.ClassName=="Tool" then group=parent.Name; break end; parent=parent.Parent end
  print("PART",id,node.Name,node.ClassName,group,numbers({node.Size.X,node.Size.Y,node.Size.Z}),numbers(node.CFrame),numbers({node.Color.R,node.Color.G,node.Color.B}),node.Material or "SmoothPlastic",node.Shape or "Block")
 elseif node.ClassName=="TextLabel" and node.Parent and node.Parent.ClassName=="SurfaceGui" then
  local p=node.Parent.Parent; local pid=table.find(all,p)
  print("TEXT",pid,node.Text,string.find(node.Text,"•") and "small" or "auto")
 end
end
print("CHECK","world construction completed",#all)
'''
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--luau',default='luau');args=parser.parse_args()
 source=(ROOT/'src/ServerScriptService/Services/WorldArt.luau').read_text()
 script=SHIM+'\nlocal Art=(function()\n'+source+'\nend)()\n'+TAIL
 with tempfile.TemporaryDirectory() as d:
  p=Path(d)/'art.luau';p.write_text(script)
  run=subprocess.run([args.luau,str(p)],capture_output=True,text=True,check=True)
 parts=[];texts=[]
 for line in run.stdout.splitlines():
  cols=line.split('\t')
  if cols[0]=='PART':
   _,id,name,cls,group,size,cf,color,material,shape=cols
   parts.append(dict(id=int(id),name=name,cls=cls,group=group,size=list(map(float,size.split(','))),cf=list(map(float,cf.split(','))),color=list(map(float,color.split(','))),material=material,shape=shape))
  elif cols[0]=='TEXT':texts.append(dict(part=int(cols[1]),text=cols[2]))
  elif cols[0]=='CHECK':print(line)
 assert len(parts)>200
 out=ROOT/'assets/blender';out.mkdir(parents=True,exist_ok=True)
 (out/'scene.json').write_text(json.dumps(dict(parts=parts,texts=texts),indent=2))
 print('Exported',len(parts),'parts and',len(texts),'sign labels from the actual WorldArt module')
if __name__=='__main__':main()
