--!strict
local C=require(game.ReplicatedStorage.Shared.Config)
local R: any = {}
function R.new(data: any,analytics: any) R.Data=data; R.A=analytics end
function R.buy(player: Player): boolean
 local ok=R.Data.transaction(player,function(p: any)
  if p.Rank>=C.RankCount then return false end
  local cost=C.rankCost(p.Rank); if p.Money<cost then return false end
  p.Money-=cost; p.Rank+=1; return true
 end,true)
 if ok then R.A.once(player,"FirstRankUp") end; return ok
end
return R
