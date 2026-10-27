--!strict
local C=require(game.ReplicatedStorage.Shared.Config)
local R: any = {}
function R.new(data: any,analytics: any) R.Data=data; R.A=analytics end
function R.join(player: Player)
 local day=math.floor(os.time()/86400); local dayOne=false
 R.Data.transaction(player,function(p: any)
  if p.FirstDay<0 then p.FirstDay=day end
  dayOne=day==p.FirstDay+1
  p.LastDay=day; return true
 end)
 if dayOne then R.A.once(player,"Day1Return") end
end
function R.daily(player: Player): boolean
 if C.Prototype then return false end
 return R.Data.transaction(player,function(p: any)
  local day=math.floor(os.time()/86400)
  if p.Daily>=day then return false end
  p.Streak=if p.Daily==day-1 then math.min(7,p.Streak+1) else 1
  p.Daily=day; p.Money+=100*p.Streak; return true
 end,true)
end
function R.code(player: Player,code: string): boolean
 if C.Prototype then return false end
 local reward=C.Codes[code]; if not reward then return false end
 return R.Data.transaction(player,function(p: any)
  if p.Codes[code] then return false end
  p.Codes[code]=true; p.Money+=reward.Money; p.Tokens+=reward.Tokens; return true
 end,true)
end
return R
