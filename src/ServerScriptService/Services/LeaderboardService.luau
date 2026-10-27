--!strict
local DSS=game:GetService("DataStoreService")
local Run=game:GetService("RunService")
local C=require(game.ReplicatedStorage.Shared.Config)
local L: any = {Cache={}}
function L.start(data: any)
 if Run:IsStudio() or C.Prototype then return end
 task.spawn(function()
  while true do
   task.wait(120)
   for _,metric in {"Money","Rank","Prestiges"} do
    local store=DSS:GetOrderedDataStore("Yardwork_"..metric.."_v1")
    for player in pairs(data.Sessions) do
     local p=data.read(player)
     if p then pcall(function() store:SetAsync(tostring(player.UserId),math.floor(p[metric])) end); task.wait(0.3) end
    end
    local ok,pages=pcall(function() return store:GetSortedAsync(false,10) end)
    if ok then L.Cache[metric]=pages:GetCurrentPage() end
   end
  end
 end)
end
return L
