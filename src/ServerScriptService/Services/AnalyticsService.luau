--!strict
local Platform = game:GetService("AnalyticsService")
local Run = game:GetService("RunService")
local A: any = {}
function A.new(data: any)
 A.Data=data
end
function A.once(player: Player, name: string)
 local fresh=false
 A.Data.transaction(player,function(p: any)
  if not p.Milestones[name] then p.Milestones[name]=true; fresh=true end
  return true
 end)
 if fresh then
  if Run:IsStudio() then print("Yardwork milestone:",name) else
   pcall(function() Platform:LogCustomEvent(player,name,1) end)
  end
 end
end
return A
