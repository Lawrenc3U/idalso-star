#!/usr/bin/env python3
"""Run actual HUD callbacks against a small UI/service mock, not Roblox rendering."""
from pathlib import Path
import argparse,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
SHIM=r'''
local passed=0
local function check(ok,message) assert(ok,message);passed+=1;print("PASS",message) end
local function signal()
 local s={Handlers={}}
 function s:Connect(fn) table.insert(self.Handlers,fn);return {Disconnect=function() end} end
 function s:Fire(...) for _,fn in self.Handlers do fn(...) end end
 return s
end
local Vector2={new=function(x,y) return {X=x,Y=y} end,zero={X=0,Y=0}}
local UDim={new=function(s,o) return {Scale=s,Offset=o} end}
local UDim2={new=function(xs,xo,ys,yo) return {X=UDim.new(xs or 0,xo or 0),Y=UDim.new(ys or 0,yo or 0)} end}
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
local Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end,new=function(r,g,b) return {R=r,G=g,B=b} end}
local Enum=setmetatable({},{__index=function(t,k) local v=setmetatable({},{__index=function(_,key) return key end}); rawset(t,k,v);return v end})
local all={}; local methods={}
local mt={__index=function(t,key)
 if methods[key] then return methods[key] end
 local p=rawget(t,"Props")
 if key=="AbsoluteSize" then
  if p.ClassName=="ScreenGui" or p.ClassName=="PlayerGui" then return Vector2.new(1280,720) end
  local parent=p.Parent and p.Parent.AbsoluteSize or Vector2.new(1280,720)
  local size=p.Size or UDim2.fromOffset(100,100)
  return Vector2.new(parent.X*size.X.Scale+size.X.Offset,parent.Y*size.Y.Scale+size.Y.Offset)
 end
 if string.find(key,"Changed") or key=="Activated" or key=="MouseEnter" or key=="MouseLeave" or key=="SelectionGained" or key=="SelectionLost" or key=="InputBegan" then
  if not p[key] then p[key]=signal() end
 end
 return p[key]
end,__newindex=function(t,k,v)
 local p=rawget(t,"Props")
 if k=="Parent" and v then table.insert(v.Children,t) end
 p[k]=v
end}
local Instance={}
function Instance.new(cls)
 local t=setmetatable({Props={ClassName=cls,Name=cls,CanvasPosition=Vector2.zero,Visible=true,Active=true},Children={}},mt);table.insert(all,t);return t
end
function methods:IsA(cls) return self.ClassName==cls or (cls=="GuiObject" and (self.ClassName=="Frame" or self.ClassName=="ScrollingFrame" or self.ClassName=="TextButton" or self.ClassName=="TextLabel" or self.ClassName=="TextBox")) end
function methods:GetChildren() return table.clone(self.Children) end
function methods:FindFirstChild(name) for _,v in self.Children do if v.Name==name then return v end end end
function methods:FindFirstChildOfClass(cls) for _,v in self.Children do if v.ClassName==cls then return v end end end
function methods:GetPropertyChangedSignal(_) return signal() end
function methods:WaitForChild(name) return self:FindFirstChild(name) end
function methods:Destroy()
 self.Destroyed=true
 if self.Parent then local index=table.find(self.Parent.Children,self);if index then table.remove(self.Parent.Children,index) end end
 for _,v in self:GetChildren() do v:Destroy() end
end
local player=Instance.new("Player");local pg=Instance.new("PlayerGui");pg.Parent=player
local input={InputEnded=signal(),WindowFocusReleased=signal(),GetLastInputType=function() return Enum.UserInputType.MouseButton1 end}
local tween={Create=function(_,node,_,props) return {Play=function() for k,v in props do node[k]=v end end} end}
local svc={Players={LocalPlayer=player},ReplicatedStorage={},UserInputService=input,TweenService=tween,GuiService={}}
local game={GetService=function(_,name) return svc[name] end}
local workspace=Instance.new("Workspace")
local task={defer=function(fn) fn() end,delay=function() end}
local TweenInfo={new=function() return {} end}
local function widget(text)
 for i=#all,1,-1 do local n=all[i];if not n.Destroyed and n.Text==text and n.ClassName=="TextButton" then return n end end
 error("missing button: "..text)
end
'''
TEST=r'''
local requests={}
local hud=HUD.new(function(verb,arg) table.insert(requests,{verb,arg}) end)
local p={Money=200,Tokens=0,Rank=1,Prestiges=0,Pick=1,Bag=1,Count=10,Capacity=30,MineTier=1,NearSell=false,
 Resets={280},Enchants={Fortune=0,Chain=0,Burst=0,Capacity=0,Skin=0,Pet=0},Settings={Music=true,Effects=true,Motion=true},Passes={},Daily=-1,Streak=0,ResetCredits=0,Leaders={}}
hud.update(p)
widget("Go to sell").Activated:Fire()
check(requests[#requests][1]=="VisitSell","go-to-sell uses server travel request")
p.NearSell=true;hud.update(p);widget("Sell all").Activated:Fire()
check(requests[#requests][1]=="Sell","nearby sell button requests inventory sale")
p.Count=0;hud.update(p);local before=#requests;widget("Sell all").Activated:Fire()
check(#requests==before,"empty bag does not send pointless sell request")
hud.open("Gear");check(hud.isOpen(),"upgrade panel opens")
hud.update(p)
local buy=widget("$180");buy.Activated:Fire()
check(requests[#requests][1]=="Shop" and requests[#requests][2]=="Pick","pick card sends whitelisted upgrade key")
p.Money=10;hud.update(p);before=#requests;buy.Activated:Fire()
check(#requests==before,"unaffordable card does not submit purchase")
check(not buy.Destroyed,"wallet ticks preserve focused upgrade button")
hud.open("Settings");widget("On").Activated:Fire()
check(requests[#requests][1]=="Setting","settings toggle submits preference")
hud.close();check(not hud.isOpen(),"close returns to gameplay HUD")
local mineButton
for _,n in all do if not n.Destroyed and n.Text=="HOLD" then mineButton=n.Parent end end
assert(mineButton)
local touch={UserInputType=Enum.UserInputType.Touch};local joystick={UserInputType=Enum.UserInputType.Touch}
mineButton.InputBegan:Fire(touch);check(hud.Held,"touch hold starts mining")
input.InputEnded:Fire(joystick);check(hud.Held,"releasing joystick does not cancel mine finger")
input.InputEnded:Fire(touch);check(not hud.Held,"releasing mining finger stops mining")
mineButton.InputBegan:Fire(touch);hud.open("More");check(not hud.Held,"opening a menu clears held mining")
Config.Prototype=false;hud.open("Rewards");hud.update(p)
local code
for _,n in all do if not n.Destroyed and n.ClassName=="TextBox" then code=n end end
assert(code);code.Text="WELCOME";p.Money=25;hud.update(p)
check(not code.Destroyed and code.Text=="WELCOME","wallet updates preserve typed reward code")
widget("Redeem").Activated:Fire()
check(requests[#requests][1]=="Code" and requests[#requests][2]=="WELCOME","code redemption uses typed value")
print("RESULT",passed,"HUD interaction checks passed")
'''
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--luau',default='luau');args=parser.parse_args()
 config=(ROOT/'src/ReplicatedStorage/Shared/Config.luau').read_text()
 layout=(ROOT/'src/ReplicatedStorage/Shared/HUDLayout.luau').read_text()
 hud=(ROOT/'src/StarterPlayer/StarterPlayerScripts/HUDController.luau').read_text().replace('require(RS.Shared.Config)','Config').replace('require(RS.Shared.HUDLayout)','Layout')
 script=SHIM+'\nlocal Config=(function()\n'+config+'\nend)()\nlocal Layout=(function()\n'+layout+'\nend)()\nlocal HUD=(function()\n'+hud+'\nend)()\n'+TEST
 with tempfile.TemporaryDirectory() as d:
  file=Path(d)/'hud.luau';file.write_text(script);subprocess.run([args.luau,str(file)],check=True)
if __name__=='__main__':main()
