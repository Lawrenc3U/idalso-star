--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local Market=game:GetService("MarketplaceService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Tags=game:GetService("CollectionService")
local player=Players.LocalPlayer
local C=require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local remotes=RS:WaitForChild("YardworkRemotes")
local action=remotes:WaitForChild("Action") :: RemoteEvent
local state=remotes:WaitForChild("State") :: RemoteEvent
local notice=remotes:WaitForChild("Notice") :: RemoteEvent
local HUD=require(script.Parent:WaitForChild("HUDController"))
local hud=HUD.new(function(verb: string,arg: any?) action:FireServer(verb,arg) end)
hud.Purchase=function(kind: string,id: number)
 if kind=="Pass" then Market:PromptGamePassPurchase(player,id) else Market:PromptProductPurchase(player,id) end
end
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt: ProximityPrompt)
 if prompt.Name=="WorkshopPrompt" then hud.open("Gear") end
end)
local current: any=nil
local held=false
local lastPosition: Vector3?=nil
local lastColor=Color3.fromRGB(206,222,208)
local audio=Instance.new("Folder"); audio.Name="YardworkAudio"; audio.Parent=player:WaitForChild("PlayerGui")
local function sound(name: string)
 if not current or not current.Settings.Effects or C.Audio[name]==0 then return end
 local s=Instance.new("Sound"); s.SoundId="rbxassetid://"..C.Audio[name]; s.Volume=.3; s.Parent=audio; s:Play(); Debris:AddItem(s,5)
end
local function target(): BasePart?
 local camera=workspace.CurrentCamera; if not camera then return nil end
 local last=Input:GetLastInputType()
 local ray: Ray
 if Input.TouchEnabled or string.find(last.Name,"Gamepad") then ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 else local pos=Input:GetMouseLocation(); ray=camera:ScreenPointToRay(pos.X,pos.Y) end
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=if player.Character then {player.Character} else {}
 local hit=workspace:Raycast(ray.Origin,ray.Direction*80,params)
 if hit and hit.Instance:GetAttribute("Health") then return hit.Instance end
 return nil
end
Input.InputBegan:Connect(function(i,processed)
 if hud.isOpen() and i.KeyCode==Enum.KeyCode.ButtonB then hud.close(); return end
 if processed or Input:GetFocusedTextBox() then return end
 if i.KeyCode==Enum.KeyCode.B or i.KeyCode==Enum.KeyCode.ButtonY then hud.open("Gear") end
 if i.KeyCode==Enum.KeyCode.M then hud.open("Mines") end
 if i.KeyCode==Enum.KeyCode.N then hud.open("More") end
 if i.KeyCode==Enum.KeyCode.ButtonX then
  if current and current.NearSell then action:FireServer("Sell") else action:FireServer("VisitSell") end
 end
 if i.UserInputType==Enum.UserInputType.MouseButton1 or i.KeyCode==Enum.KeyCode.ButtonR2 then held=true end
end)
Input.InputEnded:Connect(function(i)
 if i.UserInputType==Enum.UserInputType.MouseButton1 or i.KeyCode==Enum.KeyCode.ButtonR2 then held=false end
end)
Input.WindowFocusReleased:Connect(function() held=false end)
notice.OnClientEvent:Connect(hud.notify)
state.OnClientEvent:Connect(function(p: any)
 local old=current; current=p; hud.update(p)
 if old and p.Count>old.Count then
  sound("Break")
  if p.Settings.Effects and lastPosition then
   for i=1,4 do
    local chip=Instance.new("Part"); chip.Name="OreChip"; chip.Anchored=true; chip.CanCollide=false; chip.CanQuery=false; chip.CanTouch=false
    chip.Size=Vector3.one*.25; chip.Material=Enum.Material.SmoothPlastic; chip.Color=lastColor; chip.Position=lastPosition; chip.Parent=workspace
    local direction=Vector3.new(math.cos(i*1.6)*1.8,1+i*.15,math.sin(i*1.6)*1.8)
    Tween:Create(chip,TweenInfo.new(.35),{Position=chip.Position+direction,Transparency=1,Size=Vector3.one*.08}):Play(); Debris:AddItem(chip,.4)
   end
  end
 end
 if old and p.Money>old.Money then
  sound("Sell"); hud.notify((if p.Count<old.Count then "Sold your ore! +$" else "+$")..tostring(math.floor(p.Money-old.Money)))
 end
 if old and p.Rank>old.Rank then sound("Rank"); hud.notify("Rank "..string.char(64+p.Rank).." unlocked. Nice work!") end
end)
local pet: Model?=nil
local music=Instance.new("Sound"); music.Name="YardAmbience"; music.Looped=true; music.Volume=.15; music.Parent=audio
if C.Audio.Music>0 then music.SoundId="rbxassetid://"..C.Audio.Music; music:Play() end
local function buddy(): Model
 local model=Instance.new("Model"); model.Name="WorkshopBuddy"
 local function piece(name: string,size: Vector3,position: Vector3,color: Color3)
  local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=CFrame.new(position); p.Color=color; p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.Parent=model; return p
 end
 model.PrimaryPart=piece("Body",Vector3.new(1.2,1.1,1.2),Vector3.zero,Color3.fromRGB(239,188,78))
 piece("Hat",Vector3.new(1.4,.2,1.4),Vector3.new(0,.65,0),Color3.fromRGB(40,129,101))
 for _,x in {-.25,.25} do piece("Eye",Vector3.new(.12,.17,.08),Vector3.new(x,.1,-.62),Color3.fromRGB(30,48,57)) end
 model.Parent=workspace; return model
end
task.spawn(function()
 while true do
  task.wait(.12)
  if current then
   music.Volume=if current.Settings.Music then .15 else 0
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if current.Enchants.Pet>0 and root and root:IsA("BasePart") then
    if not pet then pet=buddy() end
    pet:PivotTo(root.CFrame*CFrame.new(3,1+(if current.Settings.Motion then math.sin(os.clock()*2)*.2 else 0),2))
   elseif pet then pet:Destroy(); pet=nil end
  end
  local block=target(); hud.target(block)
  if block then lastPosition=block.Position; lastColor=block.Color end
  if current and (held or hud.Held or (hud.Auto and current.Passes.Auto)) and not hud.isOpen() then
   if not block and hud.Auto and player.Character then
    local root=player.Character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
     local closest=C.Reach
     for _,candidate in Tags:GetTagged("MineBlock") do
      if candidate:IsA("BasePart") then
       local distance=(candidate.Position-root.Position).Magnitude
       if distance<closest then closest=distance; block=candidate end
      end
     end
    end
   end
   if block then lastPosition=block.Position; lastColor=block.Color; action:FireServer("Mine",block) end
  end
 end
end)
action:FireServer("Sync")
