--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local Tween=game:GetService("TweenService")
local Market=game:GetService("MarketplaceService")
local Debris=game:GetService("Debris")
local player=Players.LocalPlayer
local C=require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local remotes=RS:WaitForChild("YardworkRemotes")
local action=remotes:WaitForChild("Action") :: RemoteEvent
local state=remotes:WaitForChild("State") :: RemoteEvent
local notice=remotes:WaitForChild("Notice") :: RemoteEvent
local current: any=nil
local held=false
local auto=false
local confirmed=false
local page="Shop"
local lastTarget: BasePart?=nil
local gui=Instance.new("ScreenGui"); gui.Name="YardworkUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.Parent=player:WaitForChild("PlayerGui")
local function text(parent: Instance,content: string,size: UDim2): TextLabel
 local t=Instance.new("TextLabel"); t.Size=size; t.BackgroundTransparency=1; t.Text=content; t.TextColor3=Color3.fromRGB(245,247,240); t.Font=Enum.Font.GothamBold; t.TextSize=16; t.TextWrapped=true; t.Parent=parent; return t
end
local function button(parent: Instance,content: string,callback: ()->()): TextButton
 local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-8,0,46); b.BackgroundColor3=Color3.fromRGB(34,119,132); b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold; b.TextSize=15; b.TextWrapped=true; b.Text=content; b.Parent=parent
 local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,10); corner.Parent=b
 b.Activated:Connect(callback); return b
end
local hud=Instance.new("Frame"); hud.Size=UDim2.new(0.96,0,0,116); hud.Position=UDim2.fromScale(0.02,0); hud.BackgroundColor3=Color3.fromRGB(27,42,62); hud.Parent=gui
local summary=text(hud,"Loading profile…",UDim2.new(1,-10,0,58)); summary.Position=UDim2.fromOffset(5,0)
local hint=text(hud,"Mine a block → visit the green sell pad → upgrade.",UDim2.new(1,-10,0,32)); hint.Position=UDim2.fromOffset(5,58); hint.TextSize=13
local bar=Instance.new("Frame"); bar.Position=UDim2.new(0.02,0,1,-17); bar.Size=UDim2.new(0.96,0,0,10); bar.BackgroundColor3=Color3.fromRGB(60,65,78); bar.Parent=hud
local fill=Instance.new("Frame"); fill.Size=UDim2.fromScale(0,1); fill.BackgroundColor3=Color3.fromRGB(80,223,164); fill.Parent=bar
local toast=text(gui,"",UDim2.new(0.85,0,0,58)); toast.Position=UDim2.fromScale(0.075,0.3); toast.TextStrokeTransparency=0.4
local toastId=0
local function sound(name: string)
 if not current or not current.Settings.Effects or C.Audio[name]==0 then return end
 local s=Instance.new("Sound"); s.SoundId="rbxassetid://"..C.Audio[name]; s.Volume=0.35; s.Parent=gui; s:Play(); Debris:AddItem(s,5)
end
local function notify(message: string)
 toastId+=1; local id=toastId; toast.Text=message
 if current and current.Settings.Motion then toast.TextTransparency=1; Tween:Create(toast,TweenInfo.new(0.15),{TextTransparency=0}):Play() else toast.TextTransparency=0 end
 task.delay(3,function() if id==toastId then toast.Text="" end end)
end
local controls=Instance.new("Frame"); controls.Size=UDim2.new(0.35,0,0,156); controls.AnchorPoint=Vector2.new(1,1); controls.Position=UDim2.new(0.98,0,1,-175); controls.BackgroundTransparency=1; controls.Parent=gui
local cl=Instance.new("UIListLayout"); cl.Padding=UDim.new(0,5); cl.Parent=controls
local mineButton=button(controls,"Hold to mine",function() end)
button(controls,"Sell All (near pad)",function() action:FireServer("Sell") end)
local panel=Instance.new("Frame"); panel.Size=UDim2.fromScale(0.9,0.62); panel.Position=UDim2.fromScale(0.05,0.2); panel.BackgroundColor3=Color3.fromRGB(27,42,62); panel.Visible=false; panel.Parent=gui
local title=text(panel,"WORKSHOP",UDim2.new(1,-65,0,42))
local close=button(panel,"X",function() panel.Visible=false end); close.Size=UDim2.fromOffset(48,42); close.Position=UDim2.new(1,-52,0,0)
local scroll=Instance.new("ScrollingFrame"); scroll.Position=UDim2.fromOffset(6,48); scroll.Size=UDim2.new(1,-12,1,-54); scroll.BackgroundTransparency=1; scroll.ScrollBarThickness=6; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(); scroll.Parent=panel
local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,6); layout.Parent=scroll
local function clear() for _,child in scroll:GetChildren() do if child~=layout then child:Destroy() end end end
local function line(s: string) text(scroll,s,UDim2.new(1,-10,0,52)) end
local function render()
 if not current then return end
 clear(); title.Text=string.upper(page)
 local p=current
 if page=="Shop" then
  local pick=C.Picks[p.Pick+1]; local bag=C.BagCosts[p.Bag+1]
  if pick and (not C.Prototype or p.Pick<3) then button(scroll,"Pick: "..pick.Name.." • $"..pick.Cost,function() action:FireServer("Shop","Pick") end) end
  if bag and (not C.Prototype or p.Bag<3) then button(scroll,"Backpack: "..C.Bags[p.Bag+1].." • $"..bag,function() action:FireServer("Shop","Bag") end) end
  if not C.Prototype then
   for _,name in {"Fortune","Chain","Burst","Capacity","Skin","Pet"} do
    local cost=C.TokenPrices[name]*(p.Enchants[name]+1)
    button(scroll,name.." Lv "..p.Enchants[name].." • "..cost.." tokens",function() action:FireServer("Shop",name) end)
   end
  end
  if p.Rank<C.RankCount then
   button(scroll,"Rank up to "..string.char(65+p.Rank).." • $"..C.rankCost(p.Rank),function() action:FireServer("Rank") end)
  else line(if C.Prototype then "Prototype complete! Reach C and help test the loop." else "Rank Z reached! Prestige is available below.") end
  button(scroll,"Prestige details",function() page="Prestige"; confirmed=false; render() end)
  if p.Passes.VIP then button(scroll,"Visit VIP lounge",function() action:FireServer("VIP") end) end
  button(scroll,"Choose mine",function() page="Mines"; render() end)
  button(scroll,"Rewards & codes",function() page="Rewards"; render() end)
  button(scroll,"Passes & products",function() page="Store"; render() end)
  button(scroll,"Leaderboards",function() page="Leaders"; render() end)
  button(scroll,"Settings",function() page="Settings"; render() end)
 elseif page=="Mines" then
  button(scroll,"Return to safety",function() action:FireServer("Visit",1) end)
  for tier=1,(if C.Prototype then 1 else p.Rank) do
   button(scroll,"Visit Mine "..string.char(64+tier),function() action:FireServer("Visit",tier) end)
  end
 elseif page=="Prestige" then
  line("Requires Z and $"..C.prestigeCost(p.Prestiges)..". Grants 10 tokens (20 with pass) and +20% sell bonus, capped at 5x.")
  line("RESETS money, rank, cash pickaxe, cash backpack, and unsold ore. Keeps tokens, enchants, cosmetics, passes and statistics.")
  button(scroll,if confirmed then "CONFIRM: erase listed progress" else "I understand the resets",function()
   if confirmed then action:FireServer("Prestige","CONFIRM_RESET"); confirmed=false else confirmed=true end; render()
  end)
 elseif page=="Rewards" then
  line("Daily streak: "..p.Streak.." • claim once per UTC day. Prototype rewards are disabled.")
  button(scroll,"Claim daily reward",function() action:FireServer("Daily") end)
  local box=Instance.new("TextBox"); box.Size=UDim2.new(1,-8,0,48); box.PlaceholderText="Enter code"; box.Text=""; box.TextSize=18; box.Parent=scroll
  button(scroll,"Redeem code",function() action:FireServer("Code",box.Text) end)
  button(scroll,"Use reset credit (30s warning) • owned "..p.ResetCredits,function() action:FireServer("Reset") end)
 elseif page=="Store" then
  line("Optional purchases. All progression is free. Boost time expires even while offline. Check Roblox's prompt for the actual price.")
  for name,id in pairs(C.Passes) do
   if id>0 then button(scroll,name..(if p.Passes[name] then " • Owned" else " • view price"),function() if not p.Passes[name] then Market:PromptGamePassPurchase(player,id) end end) end
  end
  for _,product in C.Products do
   if product.Id>0 then button(scroll,product.Name.." • view price",function() Market:PromptProductPurchase(player,product.Id) end) end
  end
  line("No options? Purchase IDs have not been configured. No payment is needed to play.")
 elseif page=="Settings" then
  for _,key in {"Music","Effects","Motion"} do
   button(scroll,key..": "..tostring(p.Settings[key]),function() action:FireServer("Setting",key) end)
  end
  button(scroll,"Auto-target: "..tostring(auto).." (Auto pass)",function() if p.Passes.Auto then auto=not auto; render() else notify("Free hold-to-mine is always available.") end end)
 elseif page=="Leaders" then
  for _,metric in {"Money","Rank","Prestiges"} do
   line(metric.." — refreshes about every 2 minutes")
   for i,entry in (p.Leaders[metric] or {}) do line(i..". User "..entry.key.." • "..entry.value) end
  end
 end
 if page~="Shop" then button(scroll,"Back",function() page="Shop"; render() end) end
end
button(controls,"Workshop / ranks",function() panel.Visible=not panel.Visible; page="Shop"; render() end)
local function target(): BasePart?
 local camera=workspace.CurrentCamera; if not camera then return nil end
 local ray: Ray
 if Input.TouchEnabled or Input.GamepadEnabled then ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 else local pos=Input:GetMouseLocation(); ray=camera:ScreenPointToRay(pos.X,pos.Y) end
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=if player.Character then {player.Character} else {}
 local result=workspace:Raycast(ray.Origin,ray.Direction*80,params)
 if result and result.Instance:GetAttribute("Health") then return result.Instance end
 return nil
end
local cross=text(gui,"+",UDim2.fromOffset(24,24)); cross.AnchorPoint=Vector2.new(0.5,0.5); cross.Position=UDim2.fromScale(0.5,0.5)
local health=text(gui,"",UDim2.fromOffset(180,30)); health.AnchorPoint=Vector2.new(0.5,0); health.Position=UDim2.fromScale(0.5,0.54)
local function holding(input: InputObject): boolean return input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 end
mineButton.InputBegan:Connect(function(i) if holding(i) then held=true end end)
Input.InputBegan:Connect(function(i,processed)
 if processed then return end
 if i.UserInputType==Enum.UserInputType.MouseButton1 or i.KeyCode==Enum.KeyCode.ButtonR2 then held=true end
 if i.KeyCode==Enum.KeyCode.ButtonY then panel.Visible=not panel.Visible; render() end
 if i.KeyCode==Enum.KeyCode.ButtonX then action:FireServer("Sell") end
end)
Input.InputEnded:Connect(function(i)
 if holding(i) or i.KeyCode==Enum.KeyCode.ButtonR2 then held=false end
end)
Input.WindowFocusReleased:Connect(function() held=false end)
notice.OnClientEvent:Connect(notify)
state.OnClientEvent:Connect(function(p: any)
 local old=current; current=p
 if old and p.Count>old.Count then
  sound("Break")
  if p.Settings.Effects and lastTarget then
   local marker=Instance.new("Part"); marker.Anchored=true; marker.CanCollide=false; marker.CanQuery=false; marker.Shape=Enum.PartType.Ball; marker.Size=Vector3.one; marker.Color=Color3.fromRGB(90,240,180); marker.Position=lastTarget.Position; marker.Parent=workspace
   Tween:Create(marker,TweenInfo.new(0.3),{Size=Vector3.one*3,Transparency=1}):Play(); Debris:AddItem(marker,0.4)
  end
 end
 local reset=p.Resets[p.MineTier]
 summary.Text=string.format("$%d • %d tokens • Rank %s • Prestige %d\nBag %d/%d • reset %ds",p.Money,p.Tokens,string.char(64+p.Rank),p.Prestiges,p.Count,p.Capacity,reset or 0)
 fill.Size=UDim2.fromScale(math.clamp(p.Count/p.Capacity,0,1),1)
 hint.Text=if p.Count==0 then "Mine blocks → sell at the green pad → buy upgrades." elseif p.Count>=p.Capacity then "Backpack full! Use Return to safety, then visit Sell." else "Next rank: "..(if p.Rank<C.RankCount then "$"..C.rankCost(p.Rank) else "goal reached!")
 if reset and reset<=30 then hint.Text="Mine reset in "..reset.."s — return to the rim." end
 if old and p.Money>old.Money then sound("Sell"); notify("+$"..(p.Money-old.Money)) end
 if old and p.Rank>old.Rank then sound("Rank"); notify("Rank "..string.char(64+p.Rank).." unlocked!") end
 -- Refresh buttons only after local mutations, not on every two-second state update while typing.
 if panel.Visible and page~="Rewards" then render() end
 if player.Character then
  local tool=player.Character:FindFirstChildOfClass("Tool")
  if tool then tool.Name=C.Picks[p.Pick].Name end
 end
end)
local pet: Part?=nil
local music=Instance.new("Sound"); music.Name="YardAmbience"; music.Looped=true; music.Volume=0.15; music.Parent=gui
if C.Audio.Music>0 then music.SoundId="rbxassetid://"..C.Audio.Music; music:Play() end
task.spawn(function()
 while true do
  task.wait(0.12)
  if current then
   music.Volume=if current.Settings.Music then 0.15 else 0
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if current.Enchants.Pet>0 and root and root:IsA("BasePart") then
    if not pet then pet=Instance.new("Part"); pet.Name="WorkshopBuddy"; pet.Size=Vector3.new(1.4,1.4,1.4); pet.Anchored=true; pet.CanCollide=false; pet.CanQuery=false; pet.Color=Color3.fromRGB(237,181,78); pet.Parent=workspace end
    pet.CFrame=root.CFrame*CFrame.new(3,1+(if current.Settings.Motion then math.sin(os.clock()*2)*0.3 else 0),2)
   elseif pet then pet:Destroy(); pet=nil end
   local tool=player.Character and player.Character:FindFirstChildOfClass("Tool")
   local blade=tool and tool:FindFirstChild("Blade")
   if blade and blade:IsA("BasePart") then blade.Color=if current.Enchants.Skin>0 then Color3.fromRGB(242,185,72) else Color3.fromRGB(117,206,210) end
  end
  local block=target(); lastTarget=block
  health.Text=if block then block.Name.." "..tostring(block:GetAttribute("Health")).." HP" else ""
  if current and (held or (auto and current.Passes.Auto)) and not panel.Visible then
   if not block and auto and player.Character then
    local root=player.Character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
     local nearest=C.Reach
     for _,candidate in game:GetService("CollectionService"):GetTagged("MineBlock") do
      if candidate:IsA("BasePart") then local distance=(candidate.Position-root.Position).Magnitude; if distance<nearest then nearest=distance; block=candidate end end
     end
    end
   end
   if block then action:FireServer("Mine",block) end
  end
 end
end)
action:FireServer("Sync")
