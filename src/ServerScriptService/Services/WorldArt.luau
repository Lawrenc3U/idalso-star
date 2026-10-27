--!strict
-- Original faceted environment kit. No external asset IDs, plugins, or MeshService needed.
local Tags=game:GetService("CollectionService")
local A: any={}
local P={Sand=Color3.fromRGB(216,194,151),Light=Color3.fromRGB(235,217,176),Stone=Color3.fromRGB(125,143,137),
 Dark=Color3.fromRGB(47,68,69),Teal=Color3.fromRGB(52,119,112),Timber=Color3.fromRGB(132,91,61),
 Copper=Color3.fromRGB(198,115,66),Mint=Color3.fromRGB(110,195,143),Gold=Color3.fromRGB(231,181,74),White=Color3.fromRGB(248,240,214)}
local function model(parent: Instance,name: string): Model local m=Instance.new("Model"); m.Name=name; m.Parent=parent; return m end
local function part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,shape: string?,collide: boolean?): BasePart
 local p=Instance.new(if shape=="Wedge" then "WedgePart" else "Part") :: BasePart
 p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color; p.Anchored=true; p.Material=Enum.Material.SmoothPlastic
 p.CanCollide=collide~=false; p.CanTouch=false; p.CanQuery=collide~=false
 if p:IsA("Part") then p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; if shape=="Cylinder" then p.Shape=Enum.PartType.Cylinder end end
 p.Parent=parent; return p
end
local function sign(parent: Instance,name: string,cf: CFrame,size: Vector3,heading: string,sub: string,color: Color3?)
 local board=part(parent,name,size,cf,color or P.Dark,nil,false)
 local surface=Instance.new("SurfaceGui"); surface.Name="Lettering"; surface.Face=Enum.NormalId.Front; surface.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; surface.PixelsPerStud=45; surface.LightInfluence=0; surface.Parent=board
 local text=Instance.new("TextLabel"); text.BackgroundTransparency=1; text.Size=UDim2.fromScale(.92,.55); text.Position=UDim2.fromScale(.04,.08); text.Font=Enum.Font.GothamBold; text.TextScaled=true; text.TextColor3=P.White; text.Text=heading; text.Parent=surface
 local small=text:Clone(); small.Position=UDim2.fromScale(.04,.65); small.Size=UDim2.fromScale(.92,.24); small.Font=Enum.Font.GothamMedium; small.Text=sub; small.TextColor3=P.Mint; small.Parent=surface
 return board
end
local function rock(parent: Instance,cf: CFrame,scale: number,color: Color3)
 local group=model(parent,"FacetedRock")
 part(group,"Core",Vector3.new(2.4,1.9,2.1)*scale,cf*CFrame.Angles(.12,.2,.1),color,"Wedge",false)
 part(group,"Facet",Vector3.new(1.6,1.4,1.8)*scale,cf*CFrame.new(.8*scale,.1*scale,.1*scale)*CFrame.Angles(.1,2.4,.15),color:Lerp(P.Light,.15),"Wedge",false)
 return group
end
local function tree(parent: Instance,cf: CFrame)
 local group=model(parent,"QuarryTree")
 part(group,"Trunk",Vector3.new(.8,5,.8),cf*CFrame.new(0,2.5,0),P.Timber,nil,false)
 for i=0,3 do
  part(group,"LeafFacet",Vector3.new(3.5,3,3.5),cf*CFrame.new(math.cos(i*math.pi/2)*.7,5.1+(i%2)*.7,math.sin(i*math.pi/2)*.7)*CFrame.Angles(0,i*math.pi/2,0),P.Mint:Lerp(P.Teal,i*.13),"Wedge",false)
 end
end
local function crate(parent: Instance,cf: CFrame,scale: number?)
 local s=scale or 1; local group=model(parent,"SupplyCrate")
 part(group,"Box",Vector3.one*2.3*s,cf,P.Timber,nil,false)
 for _,y in {-1,1} do part(group,"Rim",Vector3.new(2.5,.22,2.5)*s,cf*CFrame.new(0,y*s,0),P.Light,nil,false) end
 part(group,"Brace",Vector3.new(.25,2.6,.15)*s,cf*CFrame.new(0,0,-1.18*s)*CFrame.Angles(0,0,.7),P.Dark,nil,false)
end
local function lamp(parent: Instance,cf: CFrame)
 part(parent,"LampPost",Vector3.new(.3,6,.3),cf*CFrame.new(0,3,0),P.Dark,nil,false)
 part(parent,"LanternFrame",Vector3.new(1,1.1,1),cf*CFrame.new(0,6,0),P.Dark,nil,false)
 local bulb=part(parent,"Lamp",Vector3.new(.72,.7,.72),cf*CFrame.new(0,6.05,-.1),P.Gold,nil,false); bulb.Material=Enum.Material.Neon
 -- No per-lamp shadow lights; warm emissive details remain cheap on mobile.
end
local function roof(parent: Instance,cf: CFrame,width: number,depth: number,color: Color3)
 part(parent,"RoofLeft",Vector3.new(width/2+1,.35,depth),cf*CFrame.new(-width/4,0,0)*CFrame.Angles(0,0,.2),color,nil,false)
 part(parent,"RoofRight",Vector3.new(width/2+1,.35,depth),cf*CFrame.new(width/4,0,0)*CFrame.Angles(0,0,-.2),color:Lerp(P.Dark,.15),nil,false)
 part(parent,"RoofRidge",Vector3.new(.55,.4,depth+.1),cf*CFrame.new(0,width*.05,0),color,nil,false)
end
local function stall(parent: Instance,cf: CFrame,title: string,subtitle: string,color: Color3): Model
 local group=model(parent,title.."Stall")
 part(group,"Counter",Vector3.new(9,3.2,4),cf*CFrame.new(0,1.6,0),P.Timber,nil,true)
 part(group,"Countertop",Vector3.new(9.5,.45,4.5),cf*CFrame.new(0,3.4,0),P.Light,nil,true)
 for _,x in {-4.4,4.4} do part(group,"Upright",Vector3.new(.45,7,.45),cf*CFrame.new(x,3.5,.8),P.Timber,nil,false) end
 roof(group,cf*CFrame.new(0,7.3,0),10,6,color)
 sign(group,"ShopSign",cf*CFrame.new(0,5.35,-1.2),Vector3.new(7.6,1.9,.25),title,subtitle)
 for _,x in {-3,-1,1,3} do part(group,"CounterPanel",Vector3.new(.12,2.4,.1),cf*CFrame.new(x,1.6,-2.06),P.Light,nil,false) end
 return group
end
local function tower(parent: Instance,cf: CFrame)
 local group=model(parent,"GuardTower")
 for _,x in {-2.2,2.2} do for _,z in {-2.2,2.2} do part(group,"Support",Vector3.new(.65,11,.65),cf*CFrame.new(x,5.5,z),P.Timber,nil,false) end end
 part(group,"Cabin",Vector3.new(6,3.2,6),cf*CFrame.new(0,11,0),P.Light,nil,false)
 for _,x in {-1.5,1.5} do part(group,"Window",Vector3.new(1.7,1.5,.12),cf*CFrame.new(x,11.3,-3.08),P.Teal,nil,false) end
 part(group,"Deck",Vector3.new(7,.45,7),cf*CFrame.new(0,9.3,0),P.Dark,nil,false)
 roof(group,cf*CFrame.new(0,13.2,0),8,8,P.Teal)
end
local function guard(parent: Instance,cf: CFrame)
 local m=model(parent,"WardenMilo")
 for _,x in {-.45,.45} do
  part(m,"Boot",Vector3.new(.72,.45,1),cf*CFrame.new(x,.24,-.1),P.Dark,nil,false)
  part(m,"Trouser",Vector3.new(.68,1.45,.68),cf*CFrame.new(x,1.15,0),P.Teal,nil,false)
 end
 part(m,"Uniform",Vector3.new(1.8,1.8,.9),cf*CFrame.new(0,2.7,0),P.Teal,nil,false)
 for _,x in {-1.17,1.17} do
  part(m,"Sleeve",Vector3.new(.55,1.3,.65),cf*CFrame.new(x,2.8,0)*CFrame.Angles(0,0,if x<0 then -.15 else .15),P.Teal,nil,false)
  part(m,"Hand",Vector3.new(.5,.5,.55),cf*CFrame.new(x,1.95,0),Color3.fromRGB(227,181,136),nil,false)
 end
 part(m,"Head",Vector3.new(1.3,1.25,1.15),cf*CFrame.new(0,4.2,0),Color3.fromRGB(227,181,136),nil,false)
 for _,x in {-.25,.25} do part(m,"Eye",Vector3.new(.1,.13,.04),cf*CFrame.new(x,4.3,-.59),P.Dark,nil,false) end
 part(m,"Smile",Vector3.new(.25,.06,.04),cf*CFrame.new(0,3.95,-.59),P.Dark,nil,false)
 part(m,"Cap",Vector3.new(1.5,.45,1.4),cf*CFrame.new(0,4.95,0),P.Dark,nil,false)
 part(m,"Visor",Vector3.new(1.6,.12,.7),cf*CFrame.new(0,4.78,-.65),P.Teal,nil,false)
 part(m,"Badge",Vector3.new(.25,.35,.08),cf*CFrame.new(.45,3,-.5),P.Gold,nil,false)
 sign(m,"Nameplate",cf*CFrame.new(0,6.15,0),Vector3.new(4,1.1,.15),"WARDEN MILO","Small steps. Big rocks.")
end
function A.lighting()
 local lighting=game:GetService("Lighting"); lighting.ClockTime=15; lighting.Brightness=2.3
 lighting.Ambient=Color3.fromRGB(125,137,147); lighting.OutdoorAmbient=Color3.fromRGB(151,155,143)
 lighting.EnvironmentDiffuseScale=.7; lighting.EnvironmentSpecularScale=.35; lighting.ShadowSoftness=.45
 for _,name in {"YardAtmosphere","YardBloom","YardGrade"} do local old=lighting:FindFirstChild(name); if old then old:Destroy() end end
 local air=Instance.new("Atmosphere"); air.Name="YardAtmosphere"; air.Density=.22; air.Offset=.15; air.Color=Color3.fromRGB(231,222,194); air.Decay=Color3.fromRGB(153,170,173); air.Parent=lighting
 local bloom=Instance.new("BloomEffect"); bloom.Name="YardBloom"; bloom.Intensity=.12; bloom.Size=18; bloom.Threshold=1.8; bloom.Parent=lighting
 local grade=Instance.new("ColorCorrectionEffect"); grade.Name="YardGrade"; grade.Saturation=.08; grade.Contrast=.06; grade.TintColor=Color3.fromRGB(255,247,230); grade.Parent=lighting
end
function A.yard(parent: Instance,x: number,tier: number): any
 local group=model(parent,"Quarry_"..string.char(64+tier))
 local cf=CFrame.new(x,0,0)
 local tint=P.Teal:Lerp(Color3.fromHSV(((tier-1)*.075+.38)%1,.45,.65),.3)
 part(group,"Foundation",Vector3.new(80,2,80),cf*CFrame.new(0,-14,2),P.Stone,nil,true)
 part(group,"FrontPlaza",Vector3.new(76,2,28),cf*CFrame.new(0,-1,27),P.Sand,nil,true)
 part(group,"RearPlaza",Vector3.new(76,2,28),cf*CFrame.new(0,-1,-27),P.Sand,nil,true)
 for _,dx in {-26,26} do part(group,"SideWalk",Vector3.new(24,2,26),cf*CFrame.new(dx,-1,0),P.Sand,nil,true) end
 -- A dark pit liner and staggered stone bands make the mine read as an excavated quarry.
 for _,y in {-3,-7,-11} do
  for _,dx in {-12.8,12.8} do part(group,"PitStone",Vector3.new(1.4,3.8,26),cf*CFrame.new(dx,y,0),P.Stone:Lerp(P.Dark,math.abs(y)/24),nil,true) end
  for _,dz in {-12.8,12.8} do part(group,"PitStone",Vector3.new(24,3.8,1.4),cf*CFrame.new(0,y,dz),P.Stone:Lerp(P.Dark,math.abs(y)/24),nil,true) end
 end
 for _,dx in {-13.7,13.7} do part(group,"TimberRim",Vector3.new(.65,.7,28),cf*CFrame.new(dx,.3,0),P.Timber,nil,true) end
 for _,dz in {-13.7,13.7} do part(group,"TimberRim",Vector3.new(28,.7,.65),cf*CFrame.new(0,.3,dz),P.Timber,nil,true) end
 for i=-5,5 do
  part(group,"SafetyMark",Vector3.new(.9,.05,.65),cf*CFrame.new(i*2.3,.69,13.7)*CFrame.Angles(0,-.45,0),if i%2==0 then P.Gold else P.Dark,nil,false)
 end
 -- Tall entrance with a readable sign behind the excavation, facing the spawn.
 for _,dx in {-14.7,14.7} do
  part(group,"EntrancePost",Vector3.new(1.3,10,1.3),cf*CFrame.new(dx,5,-15.4),P.Timber,nil,true)
  part(group,"Footing",Vector3.new(2.2,1.2,2.2),cf*CFrame.new(dx,.6,-15.4),P.Stone,nil,true)
 end
 part(group,"EntranceBeam",Vector3.new(32,1.3,1.4),cf*CFrame.new(0,10,-15.4),P.Timber,nil,false)
 sign(group,"MineSign",cf*CFrame.new(0,9,-14.5)*CFrame.Angles(0,math.pi,0),Vector3.new(12,2.8,.35),"QUARRY "..string.char(64+tier),"MINE • SELL • MOVE UP",tint)
 for _,dx in {-34,34} do
  part(group,"BoundaryWall",Vector3.new(2,7,67),cf*CFrame.new(dx,3.5,-1),P.Light,nil,true)
  part(group,"WallCap",Vector3.new(2.8,.6,67),cf*CFrame.new(dx,7,-1),tint,nil,false)
 end
 part(group,"BackWall",Vector3.new(67,7,2),cf*CFrame.new(0,3.5,-34),P.Light,nil,true)
 part(group,"BackCap",Vector3.new(68,.6,2.8),cf*CFrame.new(0,7,-34),tint,nil,false)
 for _,dx in {-22,-11,0,11,22} do
  part(group,"CellWindow",Vector3.new(5,2.8,.1),cf*CFrame.new(dx,4.4,-32.95),P.Dark,nil,false)
  for j=-1,1 do part(group,"WindowBar",Vector3.new(.12,2.9,.18),cf*CFrame.new(dx+j*1.25,4.4,-32.8),P.Stone,nil,false) end
 end
 tower(group,cf*CFrame.new(-30,0,-29))
 -- Faceted outcrops create a quarry silhouette without importing heavy meshes.
 for i=1,6 do
  rock(group,cf*CFrame.new(-30+i*9,-2,-40)*CFrame.Angles(0,i*.8,0),3+(i%3)*1.1,P.Stone:Lerp(P.Teal,.18))
 end
 for _,dx in {-27,27} do tree(group,cf*CFrame.new(dx,0,-15)) end
 for _,dx in {-15,15} do
  local planter=model(group,"YardPlanter")
  part(planter,"Planter",Vector3.new(4,.9,2),cf*CFrame.new(dx,.45,37),P.Copper,nil,false)
  for j=-1,1 do part(planter,"Shrub",Vector3.new(1.3,1.2,1.5),cf*CFrame.new(dx+j,1.3,37)*CFrame.Angles(0,j*.8,0),P.Mint,"Wedge",false) end
 end

 -- Front plaza: separate sell stall and workshop with unobstructed routes.
 local sellStall=stall(group,cf*CFrame.new(-20,0,30),"ORE EXCHANGE","SELL YOUR HAUL",P.Mint)
 local sell=part(group,"SellZone",Vector3.new(10,.15,7),cf*CFrame.new(-20,.09,23),P.Mint,nil,false)
 Tags:AddTag(sell,"SellZone")
 local prompt=Instance.new("ProximityPrompt"); prompt.Name="SellPrompt"; prompt.ActionText="Sell all ore"; prompt.ObjectText="Ore Exchange"; prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.MaxActivationDistance=10; prompt.RequiresLineOfSight=false; prompt.Parent=sell
 local shop=stall(group,cf*CFrame.new(20,0,30),"THE WORKSHOP","BETTER GEAR. BIGGER HAULS.",tint)
 local anvil=part(shop,"Anvil",Vector3.new(2,.65,1.3),cf*CFrame.new(20,3.9,30),P.Dark,nil,false)
 part(shop,"AnvilTop",Vector3.new(3,.4,1.5),anvil.CFrame*CFrame.new(0,.4,0),P.Stone,nil,false)
 local workshopPrompt=Instance.new("ProximityPrompt"); workshopPrompt.Name="WorkshopPrompt"; workshopPrompt.ActionText="Upgrade gear"; workshopPrompt.ObjectText="The Workshop"; workshopPrompt.KeyboardKeyCode=Enum.KeyCode.E; workshopPrompt.MaxActivationDistance=10; workshopPrompt.RequiresLineOfSight=false; workshopPrompt.Parent=anvil
 crate(group,cf*CFrame.new(-28,1.2,21)*CFrame.Angles(0,.2,0))
 crate(group,cf*CFrame.new(28,1.2,23)*CFrame.Angles(0,-.3,0),.8)
 local cart=model(group,"OreCart")
 part(cart,"Hopper",Vector3.new(3.3,1.8,2.4),cf*CFrame.new(24,1.8,15),P.Dark,nil,false)
 part(cart,"HopperLip",Vector3.new(3.6,.25,2.7),cf*CFrame.new(24,2.8,15),tint,nil,false)
 for _,dx in {-1.2,1.2} do for _,dz in {-1.1,1.1} do part(cart,"Wheel",Vector3.new(.4,.9,.9),cf*CFrame.new(24+dx,.6,15+dz),P.Timber,"Cylinder",false) end end
 rock(cart,cf*CFrame.new(24,3,15),.6,P.Copper)
 for i=1,5 do
  local side=if i%2==0 then -1 else 1
  rock(group,cf*CFrame.new(side*28,.8,-20+i*6)*CFrame.Angles(0,i,0),.6+(i%3)*.25,P.Stone)
 end
 for _,dx in {-29,29} do lamp(group,cf*CFrame.new(dx,0,5)) end
 for _,dx in {-19,19} do
  part(group,"BenchSeat",Vector3.new(6,.4,1.6),cf*CFrame.new(dx,1.5,-24),P.Timber,nil,false)
  for _,leg in {-2,2} do part(group,"BenchLeg",Vector3.new(.4,1.5,1.5),cf*CFrame.new(dx+leg,.75,-24),P.Dark,nil,false) end
 end
 guard(group,cf*CFrame.new(8,0,30))
 -- Shallow stair on the front of the plaza; a clean sightline faces the mine.
 for i=1,3 do part(group,"WelcomePaver",Vector3.new(6,.07,2.4),cf*CFrame.new(0,.06,18+i*5),P.Light,nil,false) end
 local region=part(group,"MineRegion",Vector3.new(24,12,24),cf*CFrame.new(0,-6,0),P.Dark,nil,false)
 region.Transparency=1; region:SetAttribute("Tier",tier); Tags:AddTag(region,"MineRegion")
 if tier==1 then
  local spawn=Instance.new("SpawnLocation"); spawn.Name="YardSpawn"; spawn.Size=Vector3.new(6,.2,6); spawn.Position=Vector3.new(x,.1,24); spawn.Anchored=true; spawn.Neutral=true; spawn.Transparency=1; spawn.CanCollide=false; spawn.Duration=0; spawn.Parent=group
  part(group,"VIPPlinth",Vector3.new(18,14,18),CFrame.new(-50,-7,25),P.Stone,nil,true)
  part(group,"VIPDeck",Vector3.new(18,.4,18),CFrame.new(-50,.2,25),P.Timber,nil,true)
  for _,dx in {-57,-43} do for _,dz in {18,32} do part(group,"LoungePost",Vector3.new(.55,7,.55),CFrame.new(dx,3.5,dz),P.Timber,nil,false) end end
  roof(group,CFrame.new(-50,7.3,25),19,19,P.Teal)
  sign(group,"VIPSign",CFrame.new(-50,3,31),Vector3.new(9,2,.4),"THE QUIET CORNER","VIP LOUNGE",P.Teal)
 end
 return {Sell=sell,Prompt=prompt}
end
function A.ore(block: BasePart,index: number,tier: number)
 block.Material=if index==1 then Enum.Material.Sandstone else Enum.Material.Slate
 local shade=Color3.fromHSV(((tier-1)*.075+.38)%1,.25,.65)
 if tier>1 then block.Color=block.Color:Lerp(shade,.15) end
 if index==1 then return end
 local tint=if index==2 then P.Copper else P.Mint
 local ore=part(block,"OreVein",Vector3.new(1.1,.45,1.5),block.CFrame*CFrame.new(.45,block.Size.Y/2+.1,.15)*CFrame.Angles(0,.55,0),tint,"Wedge",false)
 if index==3 then
  ore.Material=Enum.Material.Neon
  part(block,"CrystalFacet",Vector3.new(.7,.8,.8),block.CFrame*CFrame.new(-.6,block.Size.Y/2+.2,-.5)*CFrame.Angles(.15,-.35,.15),P.Mint,"Wedge",false)
 end
end
function A.pickaxe(tool: Tool)
 local handle=part(tool,"Handle",Vector3.new(.32,3.1,.38),CFrame.new(),P.Timber,nil,false)
 local function attach(name: string,size: Vector3,cf: CFrame,color: Color3,shape: string?)
  local p=part(tool,name,size,cf,color,shape,false); p.Anchored=false; p.Massless=true
  local weld=Instance.new("WeldConstraint"); weld.Part0=handle; weld.Part1=p; weld.Parent=p; return p
 end
 handle.Anchored=false; handle.Massless=true
 attach("Blade",Vector3.new(2.4,.5,.6),CFrame.new(0,1.1,0),P.Stone)
 attach("LeftTip",Vector3.new(.8,.65,.6),CFrame.new(-1.45,.99,0)*CFrame.Angles(0,0,.4),P.Stone,"Wedge")
 attach("RightTip",Vector3.new(.8,.65,.6),CFrame.new(1.45,.99,0)*CFrame.Angles(0,math.pi,-.4),P.Stone,"Wedge")
 for _,y in {-.9,-.6,-.3} do attach("Grip",Vector3.new(.4,.14,.45),CFrame.new(0,y,0),P.Dark) end
 attach("Collar",Vector3.new(.55,.65,.65),CFrame.new(0,1.1,0),P.Teal)
end
function A.stylePickaxe(tool: Tool,tier: number,gold: boolean)
 local stamp=tostring(tier)..":"..tostring(gold)
 if tool:GetAttribute("ArtStyle")==stamp then return end
 tool:SetAttribute("ArtStyle",stamp)
 local colors={P.Stone,P.Copper,P.Teal,P.Mint}
 for _,name in {"Blade","LeftTip","RightTip"} do
  local p=tool:FindFirstChild(name)
  if p and p:IsA("BasePart") then p.Color=if gold then P.Gold else colors[math.clamp(tier,1,#colors)] end
 end
 local config=require(game.ReplicatedStorage.Shared.Config)
 tool.Name=config.Picks[tier].Name
end
return A
