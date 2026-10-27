--!strict
local Market=game:GetService("MarketplaceService")
local Players=game:GetService("Players")
local C=require(game.ReplicatedStorage.Shared.Config)
local M: any = {Products={}}
function M.new(data: any,economy: any,analytics: any)
 M.Data=data; M.E=economy; M.A=analytics
 for _,product in C.Products do
  if product.Id>0 then assert(not M.Products[product.Id],"Duplicate product ID"); M.Products[product.Id]=product end
 end
 Market.ProcessReceipt=function(receipt: any)
  local player=Players:GetPlayerByUserId(receipt.PlayerId)
  local product=M.Products[receipt.ProductId]
  if not player or not product then return Enum.ProductPurchaseDecision.NotProcessedYet end
  local id=tostring(receipt.PurchaseId)
  local ok=data.transaction(player,function(p: any)
   if p.Receipts[id] then return true end
   -- Never prune IDs without an archival design: delayed replays must remain idempotent.
   if product.Kind=="Money" then p.Money+=product.Amount
   elseif product.Kind=="Starter" then
    -- Repeat purchases still fulfil the advertised money grant; skin already owned is harmless.
    p.Money+=product.Amount; p.StarterOwned=true; p.Enchants.Skin=1
   elseif product.Kind=="Boost" then p.BoostUntil=math.max(os.time(),p.BoostUntil)+product.Amount
   elseif product.Kind=="Reset" then p.ResetCredits+=product.Amount
   else return false end
   p.Receipts[id]=true; return true
  end,true)
  if not ok then return Enum.ProductPurchaseDecision.NotProcessedYet end
  analytics.once(player,"FirstPurchase")
  return Enum.ProductPurchaseDecision.PurchaseGranted
 end
 Market.PromptGamePassPurchaseFinished:Connect(function(player: Player,_id: number,bought: boolean)
  if bought then M.refresh(player) end
 end)
end
function M.refresh(player: Player)
 local owned={}
 for name,id in pairs(C.Passes) do
  if id>0 then
   local ok,res=pcall(function() return Market:UserOwnsGamePassAsync(player.UserId,id) end)
   if ok and res then owned[name]=true end
  end
 end
 M.E.Passes[player]=owned
end
return M
