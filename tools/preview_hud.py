#!/usr/bin/env python3
"""Generate schematic SVGs from actual HUD widgets in the mock. Not Studio captures."""
from pathlib import Path
import argparse,importlib.util,subprocess,tempfile,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('hud_mock',ROOT/'tools/test_hud_interactions.py');mock=importlib.util.module_from_spec(spec);spec.loader.exec_module(mock)
EXPORT=r'''
local hud=HUD.new(function() end)
hud.update({Money=1248,Tokens=12,Rank=2,Prestiges=0,Pick=2,Bag=2,Count=48,Capacity=60,MineTier=1,NearSell=false,
 Resets={272},Enchants={Fortune=0,Chain=0,Burst=0,Capacity=0,Skin=0,Pet=0},Settings={Music=true,Effects=true,Motion=true},Passes={},Daily=-1,Streak=0,ResetCredits=0,Leaders={}})
local function visible(n)
 if n.Destroyed or n.Visible==false then return false end
 if n.Parent then return visible(n.Parent) end
 return true
end
local function position(n)
 if n.ClassName=="ScreenGui" or n.ClassName=="PlayerGui" or not n.Parent then return Vector2.zero end
 local parent=position(n.Parent);local parentSize=n.Parent.AbsoluteSize
 local p=n.Position or UDim2.new();local a=n.AnchorPoint or Vector2.zero;local size=n.AbsoluteSize
 return Vector2.new(parent.X+p.X.Scale*parentSize.X+p.X.Offset-a.X*size.X,parent.Y+p.Y.Scale*parentSize.Y+p.Y.Offset-a.Y*size.Y)
end
local function rgb(c) if not c then return "none" end return string.format("#%02x%02x%02x",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)) end
local function visit(n)
 if not visible(n) then return end
 if n:IsA("GuiObject") then
  local p=position(n);local size=n.AbsoluteSize;local corner=n:FindFirstChildOfClass("UICorner")
  local fields={"UI",n.ClassName,tostring(p.X),tostring(p.Y),tostring(size.X),tostring(size.Y),rgb(n.BackgroundColor3),tostring(n.BackgroundTransparency or 0),tostring(corner and corner.CornerRadius.Offset or 0),tostring(n.Rotation or 0),n.Text or "",tostring(n.TextSize or 14),rgb(n.TextColor3),n.Font or "",n.TextXAlignment or "Center"}
  print(table.concat(fields,"\t"))
 end
 for _,child in n.Children do visit(child) end
end
for _,n in all do if n.ClassName=="ScreenGui" then visit(n) end end
'''
def build(luau,w,h,name):
 config=(ROOT/'src/ReplicatedStorage/Shared/Config.luau').read_text();layout=(ROOT/'src/ReplicatedStorage/Shared/HUDLayout.luau').read_text()
 hud=(ROOT/'src/StarterPlayer/StarterPlayerScripts/HUDController.luau').read_text().replace('require(RS.Shared.Config)','Config').replace('require(RS.Shared.HUDLayout)','Layout')
 shim=mock.SHIM.replace('Vector2.new(1280,720)',f'Vector2.new({w},{h})')
 script=shim+'\nlocal Config=(function()\n'+config+'\nend)()\nlocal Layout=(function()\n'+layout+'\nend)()\nlocal HUD=(function()\n'+hud+'\nend)()\n'+EXPORT
 with tempfile.TemporaryDirectory() as d:
  p=Path(d)/'preview.luau';p.write_text(script);run=subprocess.run([luau,str(p)],capture_output=True,text=True,check=True)
 svg=ET.Element('svg',{'xmlns':'http://www.w3.org/2000/svg','width':str(w),'height':str(h),'viewBox':f'0 0 {w} {h}'})
 ET.SubElement(svg,'title').text='Yardwork HUD layout reference — not a Studio screenshot'
 ET.SubElement(svg,'rect',{'width':str(w),'height':str(h),'fill':'#cbd5c9'})
 # A neutral field keeps the gameplay view visibly open.
 ET.SubElement(svg,'text',{'x':str(w/2),'y':str(h/2-50),'fill':'#74877a','font-family':'sans-serif','font-size':'12','text-anchor':'middle'}).text='GAMEPLAY VIEW'
 for line in run.stdout.splitlines():
  if not line.startswith('UI\t'):continue
  _,cls,x,y,rw,rh,bg,alpha,radius,rotation,text,fs,tc,font,align=line.split('\t')
  x,y,rw,rh,alpha,radius,rotation,fs=map(float,[x,y,rw,rh,alpha,radius,rotation,fs]);group=ET.SubElement(svg,'g')
  if rotation:group.set('transform',f'rotate({rotation} {x+rw/2} {y+rh/2})')
  if bg!='none' and alpha<1:ET.SubElement(group,'rect',{'x':str(x),'y':str(y),'width':str(max(0,rw)),'height':str(max(0,rh)),'rx':str(min(radius,rh/2)),'fill':bg,'opacity':str(1-alpha)})
  if text:
   clipid='clip'+str(len(svg));defs=ET.SubElement(group,'defs');clip=ET.SubElement(defs,'clipPath',{'id':clipid});ET.SubElement(clip,'rect',{'x':str(x),'y':str(y),'width':str(max(0,rw)),'height':str(max(0,rh))})
   tx=x if align=='Left' else x+rw if align=='Right' else x+rw/2
   ET.SubElement(group,'text',{'x':str(tx),'y':str(y+rh/2),'dominant-baseline':'middle','text-anchor':'start' if align=='Left' else 'end' if align=='Right' else 'middle','font-family':'Arial, sans-serif','font-weight':'700' if 'Bold' in font or 'Black' in font else '500','font-size':str(fs),'fill':tc if tc!='none' else '#1e3039','clip-path':'url(#'+clipid+')'}).text=text
 ET.SubElement(svg,'text',{'x':str(w/2),'y':str(h-8),'fill':'#526b61','font-family':'sans-serif','font-size':'9','text-anchor':'middle'}).text='Layout reference · Actual Studio rendering still needs device validation'
 out=ROOT/'docs/previews';out.mkdir(parents=True,exist_ok=True);ET.ElementTree(svg).write(out/name,encoding='utf-8',xml_declaration=True)
 print('Generated',name)
def main():
 p=argparse.ArgumentParser();p.add_argument('--luau',default='luau');args=p.parse_args()
 build(args.luau,1280,720,'hud-desktop.svg');build(args.luau,360,640,'hud-phone.svg');build(args.luau,844,390,'hud-landscape.svg')
if __name__=='__main__':main()
