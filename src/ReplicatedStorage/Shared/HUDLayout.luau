--!strict
-- Pure layout arithmetic so small-screen spacing can be checked without Roblox.
export type Rect = {X: number, Y: number, W: number, H: number}
local L = {}
function L.compute(width: number,height: number): any
 local w=math.max(width,320); local h=math.max(height,320)
 local phone=w<600; local landscape=h<500
 local margin=if phone then 12 else 20
 local function rect(x: number,y: number,rw: number,rh: number): Rect return {X=x,Y=y,W=rw,H=rh} end
 local walletW=if phone then (if w<350 then 150 else 174) else 218
 local rankW=if phone then (if w<350 then 134 else 146) else 234
 local topH=if landscape then 54 else 66
 local navSize=if landscape then 48 else 56
 local navGap=8
 local navW=if landscape then navSize*3+navGap*2 else (if phone then 60 else 132)
 local navH=if landscape then navSize else navSize*3+navGap*2
 local goalW=if landscape then math.min(310,w-walletW-rankW-4*margin) else math.min(300,w-2*margin)
 local goalX=if landscape then (w-goalW)/2 else margin
 local goalY=if landscape then margin else margin+topH+10
 local targetW=if w<350 then 140 else 170
 local bagW=if phone then w-2*margin else math.min(400,w-360)
 local bagY=if phone then h-216 else h-84
 local navY=if landscape then 88 else margin+topH+86
 return {
  Phone=phone,Landscape=landscape,Margin=margin,
  Target=rect((w-targetW)/2,h/2+24,targetW,43),
  Wallet=rect(margin,margin,walletW,topH),Rank=rect(w-margin-rankW,margin,rankW,topH),
  Goal=rect(goalX,goalY,math.max(0,goalW),if landscape then 54 else 62),
  Nav=rect(if landscape then (w-navW)/2 else margin,navY,navW,navH),NavSize=navSize,
  Bag=rect((w-bagW)/2,bagY,bagW,68),
  Mine=rect(w-margin-76,if phone then math.min(h*0.49,bagY-88) else (if landscape then math.min(156,h-228) else h-236),76,76),
  Modal=rect((w-math.min(650,w-24))/2,(h-math.min(570,h-24))/2,math.min(650,w-24),math.min(570,h-24)),
 }
end
return L
