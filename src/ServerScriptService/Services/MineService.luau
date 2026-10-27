--!strict
local Tags=game:GetService("CollectionService")
local Players=game:GetService("Players")
local C=require(game.ReplicatedStorage.Shared.Config)
local Art=require(script.Parent.WorldArt)
local M: any = {Mines={},Blocks={},Last={},Visits={},Current={},Random=Random.new()}
local function part(name: string,size: Vector3,position: Vector3,color: Color3,parent: Instance): Part
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=position
 p.Color=color; p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent; return p
end
function M.new(data: any,bag: any,analytics: any) M.Data=data; M.Bag=bag; M.A=analytics end
function M.safe(tier: number): Vector3 return Vector3.new((tier-1)*90,5,24) end
function M.teleport(player: Player,tier: number): boolean
 local p=M.Data.read(player)
 if not p or tier%1~=0 or tier<1 or tier>p.Rank or not M.Mines[tier] then return false end
 local character=player.Character; if not character then return false end
 character:PivotTo(CFrame.new(M.safe(tier)))
 M.Visits[player]=os.clock(); M.Current[player]=tier; return true
end
function M.nearSell(player: Player): boolean
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then return false end
 local p=M.Data.read(player); if not p then return false end
 for tier,mine in pairs(M.Mines) do
  if tier<=p.Rank and (root.Position-mine.Sell.Position).Magnitude<=16 then return true end
 end
 return false
end
function M.reset(tier: number)
 local mine=M.Mines[tier]; if mine.Resetting then return end
 mine.Resetting=true; mine.Generation+=1
 for _,player in Players:GetPlayers() do
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if root and root:IsA("BasePart") and math.abs(root.Position.X-mine.X)<38 and math.abs(root.Position.Z)<18 then
   if player.Character then player.Character:PivotTo(CFrame.new(M.safe(tier))) end
  end
 end
 for _,block in mine.Folder:GetChildren() do M.Blocks[block]=nil; block:Destroy() end
 for y=0,C.Depth-1 do
  for x=0,C.Grid-1 do
   for z=0,C.Grid-1 do
    local roll=M.Random:NextInteger(1,100); local index=1
    for i,ore in C.Ores do roll-=ore.Weight; if roll<=0 then index=i; break end end
    local ore=C.Ores[index]
    local b=part(ore.Name,Vector3.one*C.BlockSize,Vector3.new(mine.X+(x-2.5)*4,-2-y*4,(z-2.5)*4),ore.Color,mine.Folder)
    Art.ore(b,index,tier)
    b:SetAttribute("Health",ore.Health); b:SetAttribute("MaxHealth",ore.Health); b:SetAttribute("Tier",tier)
    Tags:AddTag(b,"MineBlock")
    M.Blocks[b]={Tier=tier,Ore=index,Health=ore.Health,Generation=mine.Generation}
   end
  end
  task.wait() -- bounded reset batches
 end
 mine.Next=os.time()+C.ResetSeconds; mine.Resetting=false
 -- Pending reset intents survive crashes; clear only after a completed rebuild.
 for player in pairs(M.Data.Sessions) do
  local d=M.Data.read(player)
  if d and d.ResetPending==tier then
   M.Data.transaction(player,function(p: any) p.ResetPending=0; return true end,true)
  end
 end
end
function M.goSell(player: Player): boolean
 local p=M.Data.read(player); if not p then return false end
 local tier=M.Current[player] or 1
 if tier>p.Rank then return false end
 local mine=M.Mines[tier]; local character=player.Character
 local human=character and character:FindFirstChildOfClass("Humanoid")
 if not mine or not character or not human or human.Health<=0 then return false end
 local destination=mine.Sell.Position+Vector3.new(0,4,-1)
 character:PivotTo(CFrame.lookAt(destination,destination+Vector3.new(0,0,1)))
 M.Current[player]=tier; return true
end
function M.build()
 local world=Instance.new("Folder"); world.Name="YardworkWorld"; world.Parent=workspace
 Art.lighting()
 local count=if C.Prototype then 1 else 26
 for tier=1,count do
  local x=(tier-1)*90
  local yard=Art.yard(world,x,tier)
  yard.Prompt.Triggered:Connect(function(player: Player)
   if M.PromptSell then M.PromptSell(player) end
  end)
  local folder=Instance.new("Folder"); folder.Name="Blocks"..tier; folder.Parent=world
  M.Mines[tier]={X=x,Folder=folder,Sell=yard.Sell,Next=0,Resetting=false,Generation=0}
  M.reset(tier)
 end
 task.spawn(function()
  while true do
   task.wait(1)
   for tier,mine in pairs(M.Mines) do
    if os.time()>=mine.Next and not mine.Resetting then task.spawn(M.reset,tier) end
   end
  end
 end)
end
function M.hit(player: Player,block: Instance): boolean
 local info=M.Blocks[block]; if not info or not block:IsA("BasePart") then return false end
 local mine=M.Mines[info.Tier]; if mine.Resetting or info.Generation~=mine.Generation then return false end
 local p=M.Data.read(player); if not p or info.Tier>p.Rank then return false end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local head=player.Character and player.Character:FindFirstChild("Head")
 local human=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if not root or not root:IsA("BasePart") or not head or not head:IsA("BasePart") or not human or human.Health<=0 then return false end
 if (root.Position-block.Position).Magnitude>C.Reach then return false end
 local pick=C.Picks[p.Pick]
 if os.clock()-(M.Last[player] or 0)<pick.Interval then return false end
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={player.Character :: Instance}
 local ray=workspace:Raycast(head.Position,(block.Position-head.Position),params)
 if ray and ray.Instance~=block then return false end
 if M.Bag.count(p)>=M.Bag.capacity(player,p) then return false end
 M.Last[player]=os.clock()
 info.Health-=pick.Damage; block:SetAttribute("Health",math.max(0,info.Health))
 if info.Health>0 then return true end
 -- No yields between reward transaction and removing blocks: a break can resolve only once.
 local targets={block}
 local limit=1+p.Enchants.Chain+(if p.Enchants.Burst>0 then 1+p.Enchants.Burst else 0)
 if limit>1 then
  for candidate,entry in pairs(M.Blocks) do
   if #targets>=math.min(12,limit) then break end
   if candidate~=block and entry.Tier==info.Tier and (candidate.Position-block.Position).Magnitude<=7 then table.insert(targets,candidate) end
  end
 end
 local removed: {Instance}={}
 local accepted=M.Data.transaction(player,function(d: any)
  local room=M.Bag.capacity(player,d)-M.Bag.count(d)
  for _,target in targets do
   local entry=M.Blocks[target]
   if room<=0 then break end
   if entry then
    local amount=math.min(room,1+(if M.Random:NextNumber()<d.Enchants.Fortune*0.08 then 1 else 0))
    local key=entry.Tier..":"..entry.Ore
    d.Ore[key]=(d.Ore[key] or 0)+amount; room-=amount; table.insert(removed,target)
   end
  end
  return #removed>0
 end)
 if accepted then
  for _,target in removed do M.Blocks[target]=nil; target:Destroy() end
  M.A.once(player,"FirstMine")
 else info.Health=1; block:SetAttribute("Health",1) end
 return accepted
end
return M
