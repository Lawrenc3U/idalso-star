--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.Config)
local services=script.Parent.Services
local Data=require(services.DataService)
local E=require(services.EconomyService)
local A=require(services.AnalyticsService)
local B=require(services.BackpackService)
local R=require(services.RankService)
local P=require(services.PrestigeService)
local S=require(services.ShopService)
local T=require(services.RetentionService)
local Mine=require(services.MineService)
local Money=require(services.MonetizationService)
local Leaders=require(services.LeaderboardService)
local remotes=Instance.new("Folder"); remotes.Name="YardworkRemotes"; remotes.Parent=RS
local action=Instance.new("RemoteEvent"); action.Name="Action"; action.Parent=remotes
local state=Instance.new("RemoteEvent"); state.Name="State"; state.Parent=remotes
local notice=Instance.new("RemoteEvent"); notice.Name="Notice"; notice.Parent=remotes
A.new(Data); B.new(Data,E,A); R.new(Data,A); P.new(Data,E,A); S.new(Data,A); T.new(Data,A); Mine.new(Data,B,A); Money.new(Data,E,A)
Mine.build(); Data.start(); Leaders.start(Data)
local buckets: {[Player]: any}={}
local working: {[Player]: boolean}={}
local function push(player: Player)
 local p=Data.read(player); if not p then return end
 local resets={}; for tier,m in pairs(Mine.Mines) do resets[tier]=math.max(0,m.Next-os.time()) end
 -- Explicit projection; receipt IDs, redeemed codes, lock tokens remain server-only.
 state:FireClient(player,{Money=p.Money,Tokens=p.Tokens,Rank=p.Rank,Prestiges=p.Prestiges,
  Pick=p.Pick,Bag=p.Bag,Count=B.count(p),Capacity=B.capacity(player,p),Enchants=p.Enchants,
  BoostUntil=p.BoostUntil,ResetCredits=p.ResetCredits,Streak=p.Streak,Daily=p.Daily,
  MineTier=Mine.Current[player] or 1,Passes=E.Passes[player] or {},Settings=p.Settings,Resets=resets,Leaders=Leaders.Cache})
 local stats=player:FindFirstChild("leaderstats")
 if stats then
  local money=stats:FindFirstChild("Money") :: NumberValue; money.Value=p.Money
  local rank=stats:FindFirstChild("Rank") :: IntValue; rank.Value=p.Rank
  local prestige=stats:FindFirstChild("Prestiges") :: IntValue; prestige.Value=p.Prestiges
 end
end
local function joined(player: Player)
 if not Data.load(player) then player:Kick("Profile busy or unavailable. Please try again shortly; no progress was overwritten."); return end
 if not player.Parent then Data.save(player,true); return end
 if Data.Closing then Data.save(player,true); player:Kick("Server closing. Please rejoin."); return end
 Money.refresh(player); T.join(player)
 local pending=Data.read(player)
 if pending and pending.ResetPending>0 and Mine.Mines[pending.ResetPending] then
  Mine.Mines[pending.ResetPending].Next=math.min(Mine.Mines[pending.ResetPending].Next,os.time()+30)
 end
 local stats=Instance.new("Folder"); stats.Name="leaderstats"; stats.Parent=player
 for _,name in {"Money","Rank","Prestiges"} do
  local v=Instance.new(if name=="Money" then "NumberValue" else "IntValue"); v.Name=name; v.Parent=stats
 end
 local function characterReady(character: Model)
  local root=character:WaitForChild("HumanoidRootPart",10)
  if root then character:PivotTo(CFrame.new(Mine.safe(1))); Mine.Current[player]=1 end
  local humanoid=character:FindFirstChildOfClass("Humanoid")
  if humanoid and E.pass(player,"VIP") then humanoid.DisplayName="[VIP] "..player.DisplayName end
  local tool=Instance.new("Tool"); tool.Name="Yard Pick"; tool.RequiresHandle=true; tool.CanBeDropped=false
  local handle=Instance.new("Part"); handle.Name="Handle"; handle.Size=Vector3.new(0.3,3,0.3); handle.Color=Color3.fromRGB(143,91,58); handle.CanCollide=false; handle.Massless=true; handle.Parent=tool
  local blade=Instance.new("Part"); blade.Name="Blade"; blade.Size=Vector3.new(2.6,0.5,0.5); blade.Color=Color3.fromRGB(117,206,210); blade.CanCollide=false; blade.Massless=true; blade.CFrame=handle.CFrame*CFrame.new(0,1.2,0); blade.Parent=tool
  local weld=Instance.new("WeldConstraint"); weld.Part0=handle; weld.Part1=blade; weld.Parent=handle
  local backpack=player:WaitForChild("Backpack",10); if backpack then tool.Parent=backpack end
 end
 player.CharacterAdded:Connect(characterReady)
 if player.Character then task.spawn(characterReady,player.Character) end
 push(player)
end
Players.PlayerAdded:Connect(joined)
for _,player in Players:GetPlayers() do task.spawn(joined,player) end
Players.PlayerRemoving:Connect(function(player: Player)
 Data.save(player,true); E.Passes[player]=nil; buckets[player]=nil; working[player]=nil; Mine.Last[player]=nil; Mine.Visits[player]=nil; Mine.Current[player]=nil
end)
action.OnServerEvent:Connect(function(player: Player,verb: any,arg: any)
 if type(verb)~="string" or #verb>20 then return end
 local now=os.clock(); local bucket=buckets[player] or {Tokens=16,At=now}
 bucket.Tokens=math.min(16,bucket.Tokens+(now-bucket.At)*8); bucket.At=now; buckets[player]=bucket
 if bucket.Tokens<1 or working[player] then return end
 bucket.Tokens-=1
 if not Data.read(player) then return end
 working[player]=true
 local ok,err=pcall(function()
  local success=false
  if verb=="Sync" then push(player); return
  elseif verb=="Mine" and typeof(arg)=="Instance" then success=Mine.hit(player,arg)
  elseif verb=="Sell" and Mine.nearSell(player) then success=B.sell(player)
  elseif verb=="Rank" then success=R.buy(player)
  elseif verb=="Prestige" and arg=="CONFIRM_RESET" then success=P.buy(player); if success then Mine.teleport(player,1) end
  elseif verb=="Shop" and type(arg)=="string" and #arg<=20 then success=S.buy(player,arg)
  elseif verb=="VIP" and E.pass(player,"VIP") and player.Character then
   player.Character:PivotTo(CFrame.new(-50,5,25)); success=true
  elseif verb=="Visit" and type(arg)=="number" and arg==arg and math.abs(arg)<100 then success=Mine.teleport(player,arg)
  elseif verb=="Daily" then success=T.daily(player)
  elseif verb=="Code" and type(arg)=="string" and #arg<=32 then success=T.code(player,string.upper(arg))
  elseif verb=="Reset" then
   local p=Data.read(player); local tier=Mine.Current[player] or 1
   local m=Mine.Mines[tier]
   if not m.Resetting and m.Next-os.time()<C.ResetSeconds-60 then
    -- Queue intent persists before the credit is consumed; world operation cannot grant currency.
    success=Data.transaction(player,function(d: any)
     if d.ResetCredits<=0 then return false end
     if d.ResetPending>0 then return false end
     d.ResetCredits-=1; d.ResetPending=tier; return true
    end,true)
    if success then m.Next=math.min(m.Next,os.time()+30); notice:FireAllClients("Extra mine reset in 30 seconds. Move to the rim!") end
   end
  elseif verb=="Setting" and type(arg)=="string" and (arg=="Music" or arg=="Effects" or arg=="Motion") then
   success=Data.transaction(player,function(p: any) p.Settings[arg]=not p.Settings[arg]; return true end)
  end
  if verb~="Mine" then notice:FireClient(player,if success then "Done!" else "Unavailable: check cost, access, capacity, or stand near Sell.") end
  push(player)
 end)
 working[player]=nil
 if not ok then warn("Action failed:",tostring(err)); notice:FireClient(player,"Action could not complete. Try again.") end
end)
task.spawn(function()
 while true do task.wait(2); for _,player in Players:GetPlayers() do push(player) end end
end)
game:BindToClose(function()
 Data.Closing=true
 local count=0
 for player in pairs(Data.Sessions) do count+=1; task.spawn(function() Data.save(player,true); count-=1 end) end
 local deadline=os.clock()+25; while count>0 and os.clock()<deadline do task.wait(0.1) end
end)
