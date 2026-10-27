--!strict
local C=require(game.ReplicatedStorage.Shared.Config)
local S: any = {}
function S.new(data: any,analytics: any) S.Data=data; S.A=analytics end
function S.buy(player: Player,item: string): boolean
 local ok=S.Data.transaction(player,function(p: any)
  if item=="Pick" then
   local nextTier=p.Pick+1; local pick=C.Picks[nextTier]
   if not pick or (C.Prototype and nextTier>3) or p.Money<pick.Cost then return false end
   p.Money-=pick.Cost; p.Pick=nextTier
  elseif item=="Bag" then
   local tier=p.Bag+1; local cost=C.BagCosts[tier]
   if not cost or (C.Prototype and tier>3) or p.Money<cost then return false end
   p.Money-=cost; p.Bag=tier
  elseif C.TokenPrices[item] and not C.Prototype then
   local level=p.Enchants[item]; local cap=if item=="Skin" or item=="Pet" then 1 else 5
   local cost=C.TokenPrices[item]*(level+1)
   if level>=cap or p.Tokens<cost then return false end
   p.Tokens-=cost; p.Enchants[item]+=1
  else return false end
  return true
 end,true)
 if ok then S.A.once(player,"FirstUpgrade") end; return ok
end
return S
