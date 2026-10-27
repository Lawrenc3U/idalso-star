--!strict
local C=require(game.ReplicatedStorage.Shared.Config)
local B: any = {}
function B.new(data: any,economy: any,analytics: any) B.Data=data; B.E=economy; B.A=analytics end
function B.count(p: any): number
 local n=0; for _,v in pairs(p.Ore) do n+=v end; return n
end
function B.capacity(player: Player,p: any): number
 return math.floor((C.Bags[p.Bag]+p.Enchants.Capacity*15)*(if B.E.pass(player,"Backpack") then 1.5 else 1))
end
function B.sell(player: Player): boolean
 local p=B.Data.read(player); if not p then return false end
 -- Friend calls may yield, so calculate before entering the non-yielding mutation.
 local multiplier=B.E.multiplier(player,p)
 local sold=B.Data.transaction(player,function(d: any)
  local value=0
  for key,n in pairs(d.Ore) do
   local tier,ore=string.match(key,"^(%d+):(%d+)$")
   if tier and ore then value+=C.oreValue(tonumber(ore),tonumber(tier))*n end
  end
  if value<=0 then return false end
  local reward=math.floor(value*multiplier)
  d.Money+=reward; d.TotalEarned+=reward; d.Ore={}; return true
 end)
 if sold then B.A.once(player,"FirstSell") end
 return sold
end
return B
