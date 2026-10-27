#!/usr/bin/env python3
"""Check real layout arithmetic for safe areas and conflicting primary controls."""
from pathlib import Path
import argparse,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
TEST=r'''
local checks=0
local function check(ok,message) assert(ok,message); checks+=1 end
local function overlap(a,b)
 return a.X<b.X+b.W and b.X<a.X+a.W and a.Y<b.Y+b.H and b.Y<a.Y+a.H
end
for _,size in {{320,568},{360,640},{390,844},{600,960},{640,360},{844,390},{1024,768},{1280,720},{1920,1080}} do
 local w,h=size[1],size[2]
 local l=Layout.compute(w,h)
 local primary={"Wallet","Rank","Nav","Bag","Mine","Target"}
 if l.Goal.W>=130 then table.insert(primary,"Goal") end
 for _,key in primary do
  local r=l[key]
  check(r.X>=0 and r.Y>=0 and r.X+r.W<=w+.01 and r.Y+r.H<=h+.01,key.." outside "..w.."x"..h)
 end
 for i,a in primary do for j=i+1,#primary do
  local b=primary[j]
  check(not overlap(l[a],l[b]),a.." overlaps "..b.." at "..w.."x"..h)
 end end
 -- Keep action controls clear of typical bottom-corner touch movement areas.
 if w<900 then
  local left={X=0,Y=h-144,W=150,H=144}; local right={X=w-150,Y=h-144,W=150,H=144}
  for _,key in {"Bag","Nav","Mine"} do
   check(not overlap(l[key],left),key.." covers left touch zone")
   check(not overlap(l[key],right),key.." covers right touch zone")
  end
 end
 check(l.Modal.X>=0 and l.Modal.Y>=0 and l.Modal.X+l.Modal.W<=w and l.Modal.Y+l.Modal.H<=h,"modal bounds")
 print("PASS layout",w,h)
end
print("RESULT",checks,"HUD geometry checks passed")
'''
def main():
 p=argparse.ArgumentParser();p.add_argument('--luau',default='luau');args=p.parse_args()
 script='local Layout=(function()\n'+(ROOT/'src/ReplicatedStorage/Shared/HUDLayout.luau').read_text()+'\nend)()\n'+TEST
 with tempfile.TemporaryDirectory() as d:
  f=Path(d)/'layout.luau';f.write_text(script);subprocess.run([args.luau,str(f)],check=True)
if __name__=='__main__':main()
