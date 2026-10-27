--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local GuiService=game:GetService("GuiService")
local Input=game:GetService("UserInputService")
local C=require(RS.Shared.Config)
local Layout=require(RS.Shared.HUDLayout)
local HUD: any={}
local P={Paper=Color3.fromRGB(248,246,237),Ink=Color3.fromRGB(30,48,57),Muted=Color3.fromRGB(100,114,116),
 Green=Color3.fromRGB(40,129,101),Mint=Color3.fromRGB(209,235,217),Gold=Color3.fromRGB(239,188,78),
 Line=Color3.fromRGB(223,226,215),Orange=Color3.fromRGB(185,94,49),Grey=Color3.fromRGB(231,231,221)}
local function make(class: string,props: any,parent: Instance?): any
 local node=Instance.new(class)
 for key,value in pairs(props) do (node :: any)[key]=value end
 node.Parent=parent; return node
end
local function round(node: Instance,r: number)
 local existing=node:FindFirstChildOfClass("UICorner")
 if existing then (existing :: UICorner).CornerRadius=UDim.new(0,r) else make("UICorner",{CornerRadius=UDim.new(0,r)},node) end
end
local function stroke(node: Instance,color: Color3,thickness: number?) make("UIStroke",{Color=color,Thickness=thickness or 1,Transparency=0.2},node) end
local function frame(parent: Instance,color: Color3,radius: number?): Frame
 local f=make("Frame",{BackgroundColor3=color,BorderSizePixel=0},parent); if radius then round(f,radius) end; return f
end
local function label(parent: Instance,content: string,size: number,color: Color3?): TextLabel
 return make("TextLabel",{BackgroundTransparency=1,BorderSizePixel=0,Text=content,TextSize=size,Font=Enum.Font.GothamMedium,
 TextColor3=color or P.Ink,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd},parent)
end
local function place(node: GuiObject,x: number,y: number,w: number,h: number)
 node.Position=UDim2.fromOffset(x,y); node.Size=UDim2.fromOffset(w,h)
end
local function rectangle(node: GuiObject,r: any) place(node,r.X,r.Y,r.W,r.H) end
local function pill(parent: Instance,content: string,callback: ()->(),color: Color3?): TextButton
 local b=make("TextButton",{BackgroundColor3=color or P.Green,BorderSizePixel=0,Text=content,TextSize=14,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,AutoButtonColor=false,Selectable=true},parent)
 round(b,12)
 b.Activated:Connect(callback)
 b.MouseEnter:Connect(function() if b.Active then Tween:Create(b,TweenInfo.new(0.1),{BackgroundTransparency=0.12}):Play() end end)
 b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(0.1),{BackgroundTransparency=0}):Play() end)
 local selection=frame(b,P.Gold,12); selection.BackgroundTransparency=1; selection.Size=UDim2.fromScale(1,1); stroke(selection,P.Gold,3); selection.Visible=false
 b.SelectionGained:Connect(function() selection.Visible=true end); b.SelectionLost:Connect(function() selection.Visible=false end)
 return b
end
local function icon(parent: Instance,kind: string,color: Color3,size: number): Frame
 local root=frame(parent,color); root.BackgroundTransparency=1; root.Size=UDim2.fromOffset(size,size)
 local function shape(x: number,y: number,w: number,h: number,r: number?,rotation: number?): Frame
  local f=frame(root,color,r); f.Position=UDim2.fromScale(x,y); f.Size=UDim2.fromScale(w,h); f.Rotation=rotation or 0; return f
 end
 if kind=="Pick" then shape(.44,.18,.13,.68,3,38); shape(.16,.12,.68,.17,3,38)
 elseif kind=="Bag" then local body=shape(.2,.33,.6,.56,5); shape(.35,.1,.3,.32,4); local stripe=frame(body,P.Paper,2); stripe.Position=UDim2.fromScale(.2,.38); stripe.Size=UDim2.fromScale(.6,.13)
 elseif kind=="Mine" then shape(.1,.12,.13,.76,2); shape(.77,.12,.13,.76,2); shape(.08,.12,.84,.16,2); shape(.38,.56,.3,.3,1,45)
 elseif kind=="Menu" then for n=0,2 do shape(.18,.2+n*.25,.64,.1,3) end
 elseif kind=="Coin" then local circle=shape(.08,.08,.84,.84,50); local dollar=label(circle,"$",math.floor(size*.64),P.Ink); dollar.Size=UDim2.fromScale(1,1); dollar.TextXAlignment=Enum.TextXAlignment.Center; dollar.Font=Enum.Font.GothamBold
 elseif kind=="Token" then shape(.24,.24,.52,.52,3,45)
 end
 return root
end
function HUD.new(send: (string,any?)->()): any
 local self: any={Data=nil,Page="Gear",Bindings={},Signature="",Held=false,Confirmed=false,Auto=false,ToastId=0}
 local gui=make("ScreenGui",{Name="YardworkUI",ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=10},Players.LocalPlayer:WaitForChild("PlayerGui"))
 local root=frame(gui,P.Paper); root.BackgroundTransparency=1; root.Size=UDim2.fromScale(1,1)
 local wallet=frame(root,P.Paper,16); stroke(wallet,P.Line)
 local coin=icon(wallet,"Coin",P.Gold,34); coin.Position=UDim2.fromOffset(12,14)
 local balance=label(wallet,"Loading…",24); balance.Font=Enum.Font.GothamBold; place(balance,56,4,150,32)
 local tokens=label(wallet,"0 tokens",12,P.Muted); place(tokens,58,34,140,20)
 local rankCard=frame(root,P.Ink,16)
 local badge=frame(rankCard,P.Gold,11); place(badge,10,10,44,44)
 local rankLetter=label(badge,"A",25); rankLetter.Font=Enum.Font.GothamBlack; rankLetter.TextXAlignment=Enum.TextXAlignment.Center; rankLetter.Size=UDim2.fromScale(1,1)
 local rankName=label(rankCard,"NEW ARRIVAL",12,P.Paper); rankName.Font=Enum.Font.GothamBold; place(rankName,65,9,158,22)
 local resetLabel=label(rankCard,"Mine A · 5:00",12,Color3.fromRGB(190,207,202)); place(resetLabel,65,31,158,20)
 local objective=frame(root,P.Paper,14); stroke(objective,P.Line)
 local goalCaption=label(objective,"YOUR NEXT STEP",10,P.Green); goalCaption.Font=Enum.Font.GothamBold; place(goalCaption,14,5,260,17)
 local goalText=label(objective,"Mine a few blocks to get started",13); place(goalText,14,22,270,23)
 local progress=frame(objective,P.Line,3); progress.Position=UDim2.new(0,14,1,-10); progress.Size=UDim2.new(1,-28,0,4)
 local progressFill=frame(progress,P.Green,3); progressFill.Size=UDim2.fromScale(0,1)
 local nav=frame(root,P.Paper); nav.BackgroundTransparency=1
 local navButtons={}
 local open: (string)->()
 for _,entry in {{"Gear","Upgrades","Pick"},{"Mines","Mines","Mine"},{"More","Menu","Menu"}} do
  local b=pill(nav,"",function() open(entry[1]) end,P.Paper); stroke(b,P.Line)
  local symbol=icon(b,entry[3],P.Green,26); symbol.Name="Symbol"
  local caption=label(b,entry[2],12); caption.Name="Caption"; caption.Font=Enum.Font.GothamBold
  table.insert(navButtons,b)
 end
 local bag=frame(root,P.Paper,16); stroke(bag,P.Line)
 local bagSymbol=icon(bag,"Bag",P.Green,29); bagSymbol.Position=UDim2.fromOffset(12,10)
 local bagTitle=label(bag,"BACKPACK",10,P.Muted); place(bagTitle,49,7,115,18)
 local bagCount=label(bag,"0 / 30",16); bagCount.Font=Enum.Font.GothamBold; place(bagCount,49,24,160,23)
 local bagBar=frame(bag,P.Line,4); bagBar.Position=UDim2.new(0,14,1,-13); bagBar.Size=UDim2.new(1,-142,0,5)
 local bagFill=frame(bagBar,P.Green,4); bagFill.Size=UDim2.fromScale(0,1)
 local sell=pill(bag,"Go to sell",function()
  if not self.Data or self.Data.Count==0 then self.notify("Mine some ore first."); return end
  if self.Data.NearSell then send("Sell") else send("VisitSell"); self.notify("At the sell stall — press Sell all to cash in.") end
 end)
 sell.AnchorPoint=Vector2.new(1,0.5); sell.Position=UDim2.new(1,-10,.5,0); sell.Size=UDim2.fromOffset(112,46)
 local mineButton=pill(root,"",function() end,P.Green); round(mineButton,22)
 local mineIcon=icon(mineButton,"Pick",P.Paper,35); place(mineIcon,21,8,35,35)
 local mineCaption=label(mineButton,"HOLD",11,P.Paper); mineCaption.Font=Enum.Font.GothamBold; mineCaption.TextXAlignment=Enum.TextXAlignment.Center; place(mineCaption,0,47,76,20)
 local cross=label(root,"+",23,P.Paper); cross.TextXAlignment=Enum.TextXAlignment.Center; cross.AnchorPoint=Vector2.new(.5,.5); cross.Position=UDim2.fromScale(.5,.5); cross.Size=UDim2.fromOffset(24,24); cross.TextStrokeTransparency=.65
 local targetCard=frame(root,P.Ink,10); targetCard.AnchorPoint=Vector2.zero; targetCard.Position=UDim2.new(.5,0,.5,28); targetCard.Size=UDim2.fromOffset(170,43); targetCard.Visible=false
 local targetName=label(targetCard,"",12,P.Paper); place(targetName,10,3,150,21); targetName.Size=UDim2.new(1,-20,0,21); targetName.TextXAlignment=Enum.TextXAlignment.Center
 local hp=frame(targetCard,Color3.fromRGB(65,82,86),4); place(hp,12,29,146,5); hp.Size=UDim2.new(1,-24,0,5)
 local hpFill=frame(hp,P.Mint,4); hpFill.Size=UDim2.fromScale(1,1)
 local highlight=make("Highlight",{FillTransparency=.92,FillColor=P.Mint,OutlineColor=P.Paper,OutlineTransparency=.15,DepthMode=Enum.HighlightDepthMode.Occluded,Enabled=false},workspace)
 local toast=frame(gui,P.Ink,14); toast.AnchorPoint=Vector2.new(.5,0); toast.Size=UDim2.fromOffset(330,48); toast.Position=UDim2.new(.5,0,0,92); toast.Visible=false
 local toastText=label(toast,"",14,P.Paper); toastText.Position=UDim2.fromOffset(12,0); toastText.Size=UDim2.new(1,-24,1,0); toastText.TextXAlignment=Enum.TextXAlignment.Center; toastText.TextWrapped=true
 local overlay=make("TextButton",{Size=UDim2.fromScale(1,1),BackgroundColor3=P.Ink,BackgroundTransparency=.35,Text="",AutoButtonColor=false,Visible=false,Selectable=false},gui)
 local panel=frame(overlay,P.Paper,20); stroke(panel,P.Line)
 local panelTitle=label(panel,"UPGRADES",23); panelTitle.Font=Enum.Font.GothamBold; place(panelTitle,22,14,460,30)
 local panelSub=label(panel,"Better tools. Bigger hauls.",12,P.Muted); place(panelSub,22,48,460,20)
 local close=pill(panel,"×",function() self.close() end,P.Ink); close.AnchorPoint=Vector2.new(1,0); close.Position=UDim2.new(1,-14,0,14); close.Size=UDim2.fromOffset(44,44); close.TextSize=24
 local scroll=make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,84),Size=UDim2.new(1,-32,1,-100),ScrollBarThickness=4,ScrollBarImageColor3=P.Green,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},panel)
 local list=make("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
 make("UIPadding",{PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},scroll)
 local function compact(value: number): string
  if value>=1e9 then return string.format("%.1fB",value/1e9) elseif value>=1e6 then return string.format("%.1fM",value/1e6) elseif value>=10000 then return string.format("%.1fK",value/1000) end
  local digits=tostring(math.floor(value)); local formatted=digits:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,",""); return formatted
 end
 function self.notify(message: string)
  self.ToastId+=1; local id=self.ToastId; toastText.Text=message; toast.Visible=true
  task.delay(3.2,function() if id==self.ToastId then toast.Visible=false end end)
 end
 local function info(title: string,body: string)
  local card=frame(scroll,P.Grey,12); card.Size=UDim2.new(1,-2,0,92)
  local heading=label(card,title,14); heading.Font=Enum.Font.GothamBold; place(heading,14,10,540,22); heading.Size=UDim2.new(1,-28,0,22)
  local desc=label(card,body,12,P.Muted); desc.Position=UDim2.fromOffset(14,36); desc.Size=UDim2.new(1,-28,0,48); desc.TextWrapped=true; desc.TextTruncate=Enum.TextTruncate.None; desc.TextYAlignment=Enum.TextYAlignment.Top
 end
 local function card(name: string,description: string,cta: string,callback: ()->(),affordable: ((any)->boolean)?): TextButton
  local row=frame(scroll,Color3.fromRGB(255,254,248),14); row.Size=UDim2.new(1,-2,0,if self.Small then 116 else 90); stroke(row,P.Line)
  local heading=label(row,name,15); heading.Font=Enum.Font.GothamBold; heading.Position=UDim2.fromOffset(14,10); heading.Size=UDim2.new(1,if self.Small then -28 else -140,0,25)
  local detail=label(row,description,12,P.Muted); detail.Position=UDim2.fromOffset(14,37); detail.Size=UDim2.new(1,-142,0,40); detail.TextWrapped=true; detail.TextTruncate=Enum.TextTruncate.None; detail.TextYAlignment=Enum.TextYAlignment.Top
  local b=pill(row,cta,function()
   if affordable and not affordable(self.Data) then self.notify("Not enough currency yet — keep mining and selling."); return end
   callback()
  end)
  b.AnchorPoint=Vector2.new(1,if self.Small then 1 else .5); b.Position=if self.Small then UDim2.new(1,-12,1,-12) else UDim2.new(1,-12,.5,0); b.Size=UDim2.fromOffset(112,46)
  if affordable then
   table.insert(self.Bindings,function(p: any)
    local yes=affordable(p); b.BackgroundColor3=if yes then P.Green else P.Grey; b.TextColor3=if yes then P.Paper else P.Muted
   end)
  end
  return b
 end
 local titles={Gear={"UPGRADES","Earn it. Equip it. Dig a little deeper."},Mines={"YOUR MINES","Choose an unlocked quarry. Return here any time."},More={"THE YARD","Rewards, settings and everything else."},Rewards={"REWARDS","A little extra for a good day's work."},Settings={"SETTINGS","Make the yard feel right for you."},Prestige={"A FRESH START","Read what resets before you graduate."},Store={"OPTIONAL EXTRAS","All progression is available through play."},Leaders={"YARD LEGENDS","Global snapshots update about every two minutes."}}
 local render: ()->()
 render=function()
  if not self.Data then return end
  local oldPosition=scroll.CanvasPosition
  for _,child in scroll:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
  self.Bindings={}; local p=self.Data; local page=self.Page; local t=titles[page]
  panelTitle.Text=t[1]; panelSub.Text=t[2]
  if page=="Gear" then
   local pick=C.Picks[p.Pick+1]
   if pick and (not C.Prototype or p.Pick<3) then
    card(pick.Name,"Damage "..pick.Damage.." · "..pick.Interval.."s swing interval","$"..compact(pick.Cost),function() send("Shop","Pick") end,function(d) return d.Money>=pick.Cost end)
   else info("Pickaxe maxed","You've earned the best pickaxe available in this release.") end
   local tier=p.Bag+1; local cost=C.BagCosts[tier]
   if cost and (not C.Prototype or tier<=3) then card("Bigger backpack",C.Bags[p.Bag].." → "..C.Bags[tier].." base capacity","$"..compact(cost),function() send("Shop","Bag") end,function(d) return d.Money>=cost end)
   else info("Backpack maxed","Your current bag is the largest available in this release.") end
   if p.Rank<C.RankCount then
    local rankCost=C.rankCost(p.Rank)
    card("Rank "..string.char(65+p.Rank),"Unlock a rank and a permanent sell perk.","$"..compact(rankCost),function() send("Rank") end,function(d) return d.Money>=rankCost end)
   else info("Rank goal reached!",if C.Prototype then "You've reached C. Keep upgrading and exploring the yard." else "Rank Z! You can now work toward prestige.") end
   if not C.Prototype then
    for _,name in {"Fortune","Chain","Burst","Capacity","Skin","Pet"} do
     local level=p.Enchants[name]; local cap=if name=="Skin" or name=="Pet" then 1 else 5
     if level<cap then
      local price=C.TokenPrices[name]*(level+1)
      local descriptions={Fortune="Bonus ore chance",Chain="Break adjacent blocks",Burst="Bounded area break",Capacity="+15 base capacity",Skin="Golden pickaxe finish",Pet="A cosmetic workshop buddy"}
      card(name.." · Lv "..level,descriptions[name],price.." tokens",function() send("Shop",name) end,function(d) return d.Tokens>=price end)
     end
    end
    card("Prestige","Permanent rewards. A new beginning.","Details",function() open("Prestige") end)
   end
  elseif page=="Mines" then
   card("Back to the rim","Leave the pit safely with all your ore.","Return",function() send("Visit",p.MineTier) end)
   card("Sell your haul","Travel to this mine's green sell counter.","Go to sell",function() send("VisitSell"); self.close() end)
   for tier=1,(if C.Prototype then 1 else C.RankCount) do
    local unlocked=tier<=p.Rank
    card("Mine "..string.char(64+tier),if unlocked then "Ready to explore" else "Reach rank "..string.char(64+tier).." to enter",if unlocked then "Travel" else "Locked",function()
     if unlocked then send("Visit",tier); self.close() else self.notify("Rank up to unlock this mine.") end
    end)
   end
   if p.Passes.VIP then card("VIP lounge","A quiet spot above the quarry.","Visit",function() send("VIP"); self.close() end) end
  elseif page=="More" then
   card("Daily rewards & codes","Claim rewards and redeem a code.","Open",function() open("Rewards") end)
   card("Settings","Sound, effects and reduced motion.","Open",function() open("Settings") end)
   if not C.Prototype then
    card("Yard legends","Money, rank and prestige leaderboards.","Open",function() open("Leaders") end)
    card("Prestige","See your next long-term goal.","Details",function() open("Prestige") end)
   end
   local enabled=false; for _,id in pairs(C.Passes) do if id>0 then enabled=true end end; for _,prod in C.Products do if prod.Id>0 then enabled=true end end
   if enabled then card("Optional extras","View passes and products. No purchase needed.","Browse",function() open("Store") end) end
  elseif page=="Rewards" then
   if C.Prototype then info("Coming with the next chapter","Daily rewards and codes unlock with expanded progression. Your mining progress still saves normally.") else
    local claimed=p.Daily>=math.floor(os.time()/86400)
    card("Daily reward · "..p.Streak.." day streak",if claimed then "Claimed today. Come back next UTC day." else "Claim a free reward. No purchase required.",if claimed then "Claimed" else "Claim",function() if not claimed then send("Daily") end end)
    local box=make("TextBox",{Size=UDim2.new(1,-2,0,50),BackgroundColor3=P.Grey,BorderSizePixel=0,Text="",PlaceholderText="Enter a reward code",TextColor3=P.Ink,PlaceholderColor3=P.Muted,Font=Enum.Font.GothamMedium,TextSize=15,ClearTextOnFocus=false},scroll); round(box,12)
    card("Have a code?","Enter it above, then redeem.","Redeem",function() send("Code",box.Text) end)
    if p.ResetCredits>0 then card("Mine reset credits · "..p.ResetCredits,"Schedules a safe reset with a 30s warning.","Use credit",function() send("Reset") end) end
   end
  elseif page=="Settings" then
   for _,entry in {{"Music","Background music"},{"Effects","Sound & break effects"},{"Motion","Interface motion & pet bobbing"}} do
    local key=entry[1]
    card(entry[2],if key=="Motion" then "Turn off for a calmer screen." else "Saved with your profile.",if p.Settings[key] then "On" else "Off",function() send("Setting",key) end)
   end
   if p.Passes.Auto then card("Auto-target","Nearby targets only. Hold-to-mine is always free.",if self.Auto then "On" else "Off",function() self.Auto=not self.Auto; render() end) end
  elseif page=="Prestige" then
   info("Requires Z + $"..compact(C.prestigeCost(p.Prestiges)),"Grants 10 tokens (20 with pass) and +20% permanent sell bonus, up to 5×.")
   info("What resets","Money, rank, cash pickaxe, cash backpack and unsold ore. You keep tokens, token upgrades, cosmetics, passes and statistics.")
   card(if self.Confirmed then "Confirm your fresh start" else "Ready to graduate?","This resets the progress listed above.",if self.Confirmed then "Confirm reset" else "Review reset",function()
    if self.Confirmed then send("Prestige","CONFIRM_RESET"); self.Confirmed=false; self.close() else self.Confirmed=true; render() end
   end,function(d) return not C.Prototype and d.Rank>=26 and d.Money>=C.prestigeCost(d.Prestiges) end)
  elseif page=="Store" then
   info("Only buy if you'd like to","Check Roblox's purchase prompt for the actual price. Boost time expires while offline; repeated boosts extend time, not strength.")
   for _,name in {"Money","Tokens","Auto","Backpack","VIP"} do
    local id=C.Passes[name]
    if id>0 then
     local descriptions={Money="2× ore-sale money",Tokens="2× eligible prestige tokens",Auto="Optional nearby auto-targeting",Backpack="+50% bag capacity",VIP="Tag and cosmetic lounge"}
     card(name.." pass",descriptions[name],if p.Passes[name] then "Owned" else "View price",function() if not self.Data.Passes[name] then self.Purchase("Pass",id) end end)
    end
   end
   for _,product in C.Products do if product.Id>0 then card(product.Name,"Optional developer product.","View price",function() self.Purchase("Product",product.Id) end) end end
  elseif page=="Leaders" then
   for _,metric in {"Money","Rank","Prestiges"} do
    local entries=p.Leaders[metric] or {}
    if #entries==0 then info(metric,"The board is warming up. Check again shortly.") end
    for i,entry in entries do info(metric.." · #"..i,"User "..entry.key.." — "..compact(entry.value)) end
   end
  end
  for _,binding in self.Bindings do binding(p) end
  scroll.CanvasPosition=oldPosition
 end
 function self.close() overlay.Visible=false; root.Visible=true; self.Held=false; GuiService.SelectedObject=nil end
 open=function(page: string)
  self.Page=page; self.Confirmed=false; self.Signature=""; self.Held=false
  overlay.Visible=true; root.Visible=false; render(); scroll.CanvasPosition=Vector2.zero
  if Input:GetLastInputType()==Enum.UserInputType.Gamepad1 then GuiService.SelectedObject=close end
 end
 self.open=open
 function self.isOpen(): boolean return overlay.Visible end
 local function press(i: InputObject): boolean return i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 end
 local mineInput: InputObject?=nil
 mineButton.InputBegan:Connect(function(i) if press(i) and not mineInput then mineInput=i; self.Held=true end end)
 Input.InputEnded:Connect(function(i) if i==mineInput then mineInput=nil; self.Held=false end end)
 Input.WindowFocusReleased:Connect(function() mineInput=nil; self.Held=false end)
 function self.target(block: BasePart?)
  highlight.Adornee=block; highlight.Enabled=block~=nil and not overlay.Visible
  targetCard.Visible=block~=nil
  if block then
   targetName.Text=block.Name.." · "..tostring(block:GetAttribute("Health")).." HP"
   hpFill.Size=UDim2.fromScale(math.clamp((block:GetAttribute("Health") or 0)/math.max(1,block:GetAttribute("MaxHealth") or 1),0,1),1)
  end
 end
 local function signature(p: any): string
  local parts={self.Page,tostring(p.Pick),tostring(p.Bag),tostring(p.Rank),tostring(p.Streak),tostring(p.Daily),tostring(p.ResetCredits),tostring(p.MineTier)}
  for _,key in {"Fortune","Chain","Burst","Capacity","Skin","Pet"} do table.insert(parts,tostring(p.Enchants[key])) end
  for _,key in {"Music","Effects","Motion"} do table.insert(parts,tostring(p.Settings[key])) end
  for _,key in {"Money","Tokens","Auto","Backpack","VIP"} do table.insert(parts,tostring(p.Passes[key])) end
  return table.concat(parts,"|")
 end
 function self.update(p: any)
  self.Data=p
  balance.Text="$"..compact(p.Money); tokens.Text=compact(p.Tokens).." tokens"..(if p.Prestiges>0 then " · P"..p.Prestiges else "")
  rankLetter.Text=string.char(64+p.Rank)
  rankName.Text=if p.Rank==1 then "NEW ARRIVAL" elseif p.Rank==2 then "YARD APPRENTICE" elseif p.Rank==3 then "TRUSTED DIGGER" else "RANK "..string.char(64+p.Rank)
  local seconds=p.Resets[p.MineTier] or 0
  resetLabel.Text=string.format("Mine %s · %d:%02d",string.char(64+p.MineTier),math.floor(seconds/60),seconds%60)
  resetLabel.TextColor3=if seconds<=30 then P.Gold else Color3.fromRGB(190,207,202)
  local full=p.Count>=p.Capacity
  bagTitle.Text=if full then "BACKPACK FULL" else "BACKPACK"
  bagTitle.TextColor3=if full then P.Orange else P.Muted; bagCount.Text=p.Count.." / "..p.Capacity
  local color=if full then P.Orange else P.Green
  bagFill.BackgroundColor3=color
  local ratio=math.clamp(p.Count/p.Capacity,0,1)
  if p.Settings.Motion then Tween:Create(bagFill,TweenInfo.new(.18),{Size=UDim2.fromScale(ratio,1)}):Play() else bagFill.Size=UDim2.fromScale(ratio,1) end
  sell.Text=if p.NearSell then "Sell all" else "Go to sell"
  goalCaption.Text=if full then "TIME TO CASH IN" elseif p.Rank<C.RankCount then "NEXT RANK · "..string.char(65+p.Rank) else "YARD GOAL COMPLETE"
  if full then goalText.Text="Sell your haul to make room." elseif p.Count==0 and p.Money==0 then goalText.Text="Aim at a block and hold to mine." elseif p.Rank<C.RankCount then goalText.Text="$"..compact(p.Money).." / $"..compact(C.rankCost(p.Rank)).." · keep going!" else goalText.Text="Keep upgrading your gear." end
  progressFill.Size=UDim2.fromScale(if p.Rank<C.RankCount then math.clamp(p.Money/C.rankCost(p.Rank),0,1) else 1,1)
  if overlay.Visible then
   local key=signature(p)
   -- Wallet ticks update bindings only: do not destroy focused controls every two seconds.
   if key~=self.Signature then render(); self.Signature=key end
   for _,binding in self.Bindings do binding(p) end
  end
 end
 local function resize()
  local size=root.AbsoluteSize; if size.X<=0 or size.Y<=0 then return end
  local l=Layout.compute(size.X,size.Y)
  local wasSmall=self.Small; self.Small=l.Modal.W<420
  for _,entry in {{wallet,l.Wallet},{rankCard,l.Rank},{objective,l.Goal},{nav,l.Nav},{bag,l.Bag},{mineButton,l.Mine},{panel,l.Modal},{targetCard,l.Target}} do rectangle(entry[1],entry[2]) end
  objective.Visible=l.Goal.W>=130
  place(balance,52,if l.Landscape then 1 else 5,l.Wallet.W-62,30); balance.TextSize=if l.Phone then 21 else 24
  place(tokens,54,if l.Landscape then 28 else 35,l.Wallet.W-64,18)
  coin.Position=UDim2.fromOffset(10,if l.Landscape then 10 else 16)
  place(badge,9,if l.Landscape then 7 else 11,40,40)
  place(rankName,58,if l.Landscape then 6 else 12,l.Rank.W-64,20); rankName.TextSize=if l.Phone then 9 else 11
  place(resetLabel,58,if l.Landscape then 27 else 34,l.Rank.W-64,18); resetLabel.TextSize=if l.Phone then 10 else 12
  goalText.Size=UDim2.new(1,-28,0,23); goalCaption.Size=UDim2.new(1,-28,0,17)
  for i,b in navButtons do
   local horizontal=l.Landscape
   local buttonW=if horizontal then l.NavSize else l.Nav.W
   place(b,if horizontal then (i-1)*(l.NavSize+8) else 0,if horizontal then 0 else (i-1)*(l.NavSize+8),buttonW,l.NavSize)
   local symbol=b:FindFirstChild("Symbol") :: Frame; local caption=b:FindFirstChild("Caption") :: TextLabel
   if l.Phone or horizontal then place(symbol,(buttonW-25)/2,5,25,25); place(caption,0,l.NavSize-21,buttonW,18); caption.TextXAlignment=Enum.TextXAlignment.Center; caption.TextSize=10
   else place(symbol,12,15,26,26); place(caption,48,0,80,l.NavSize); caption.TextXAlignment=Enum.TextXAlignment.Left; caption.TextSize=13 end
  end
  toast.Size=UDim2.fromOffset(math.min(350,size.X-32),48); toast.Position=UDim2.new(.5,0,0,if l.Landscape then 145 else 90)
  panelTitle.Size=UDim2.new(1,-96,0,30); panelSub.Size=UDim2.new(1,-44,0,20)
  if wasSmall~=self.Small and overlay.Visible then render() end
 end
 root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize); task.defer(resize)
 return self
end
return HUD
