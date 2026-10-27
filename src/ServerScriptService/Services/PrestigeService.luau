--!strict
local C=require(game.ReplicatedStorage.Shared.Config)
local P: any = {}
function P.new(data: any,economy: any,analytics: any) P.Data=data; P.E=economy; P.A=analytics end
function P.buy(player: Player): boolean
 if C.Prototype then return false end
 local ok=P.Data.transaction(player,function(p: any)
  if p.Rank<26 or p.Money<C.prestigeCost(p.Prestiges) then return false end
  p.Prestiges+=1; p.Tokens+=10*(if P.E.pass(player,"Tokens") then 2 else 1)
  p.Money=0; p.Rank=1; p.Pick=1; p.Bag=1; p.Ore={}; return true
 end,true)
 if ok then P.A.once(player,"FirstPrestige") end; return ok
end
return P
