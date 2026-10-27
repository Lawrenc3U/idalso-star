--!strict
local Players=game:GetService("Players")
local C=require(game.ReplicatedStorage.Shared.Config)
local E: any = {Passes={}}
function E.pass(player: Player, name: string): boolean
 return E.Passes[player] and E.Passes[player][name]==true or false
end
function E.multiplier(player: Player, p: any): number
 local friends=0
 for _,other in Players:GetPlayers() do
  if other~=player then
   local ok,isFriend=pcall(function() return player:IsFriendsWith(other.UserId) end)
   if ok and isFriend then friends+=1 end
  end
 end
 local event=if os.time()>=C.Event.Start and os.time()<C.Event.Finish then C.Event.Bonus else 0
 local social=math.min(2.15,1+math.min(friends,3)*0.05+event)
 return C.rankMultiplier(p.Rank)*math.min(5,1+p.Prestiges*0.2)
  *(if E.pass(player,"Money") then 2 else 1)*(if p.BoostUntil>os.time() then 2 else 1)*social
end
return E
