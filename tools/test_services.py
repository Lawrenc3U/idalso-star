#!/usr/bin/env python3
"""Run actual service implementations in a small mocked engine via the Luau CLI.
Not a Roblox integration test. Requires luau on PATH or --luau /path/to/luau.
"""
import argparse,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def module(path):
 return '(function()\n'+(ROOT/path).read_text().replace('require(game.ReplicatedStorage.Shared.Config)','Config')+'\nend)()'
HEADER=r'''
local passed=0
local function check(ok, message) assert(ok,message); passed+=1; print("PASS",message) end
local records={}
local fail=false
local serial=0
local mockStore={}
function mockStore:UpdateAsync(key,fn)
 if fail then error("injected storage outage") end
 local result=fn(records[key])
 if result then records[key]=result end
 return records[key]
end
local market={PromptGamePassPurchaseFinished={Connect=function() end}}
local players={}
local Run={IsStudio=function() return false end}
local Http={GenerateGUID=function() serial+=1; return tostring(serial) end}
local DSS={GetDataStore=function() return mockStore end}
local ps={GetPlayerByUserId=function(_,id) return players[id] end,GetPlayers=function() return {} end}
local svc={DataStoreService=DSS,HttpService=Http,RunService=Run,MarketplaceService=market,Players=ps}
local game={GetService=function(_,name) return svc[name] end}
local task={wait=function() end}
local function warn() end
local Color3={fromRGB=function() return {} end}
local Enum={ProductPurchaseDecision={NotProcessedYet="retry",PurchaseGranted="granted"}}
'''
TESTS=r'''
Config.Products={{Id=111,Kind="Money",Amount=2000},{Id=222,Kind="Reset",Amount=1}}
local a={UserId=100}; local b={UserId=100}; players[100]=a
check(Data.load(a),"new profile loads")
check(not Data.load(b),"live session lock refuses concurrent owner")
check(Data.read(a).Money==0,"default balance")
Data.transaction(a,function(p) p.Money=100; return true end)
local snapshot=Data.read(a); snapshot.Money=999
check(Data.read(a).Money==100,"read snapshots cannot mutate profile")
check(not Data.transaction(a,function(p) p.Money=900; return false end),"rejected transaction")
check(Data.read(a).Money==100,"rejected mutation rolls back")
Data.Sessions[a].Busy=true
check(not Data.transaction(a,function() return true end),"busy profile refuses concurrent mutation without yielding")
Data.Sessions[a].Busy=false
check(Data.save(a,true),"release persists and unlocks")
check(Data.load(b),"next session acquires released lock")
check(Data.read(b).Money==100,"saved money survives rejoin")
players[100]=b
local economy={Passes={},pass=function() return false end}
local analytics={once=function() end}
Money.new(Data,economy,analytics)
local receipt={PlayerId=100,ProductId=111,PurchaseId="purchase-1"}
check(market.ProcessReceipt(receipt)=="granted","known product persists before acknowledgement")
check(records.p_100.Data.Money==2100,"grant exists in durable record")
check(market.ProcessReceipt(receipt)=="granted","receipt replay acknowledged")
check(Data.read(b).Money==2100,"receipt replay does not double-grant")
check(market.ProcessReceipt({PlayerId=100,ProductId=999,PurchaseId="unknown"})=="retry","unknown product deferred")
check(market.ProcessReceipt({PlayerId=999,ProductId=111,PurchaseId="offline"})=="retry","offline player deferred")
fail=true
check(market.ProcessReceipt({PlayerId=100,ProductId=111,PurchaseId="outage"})=="retry","storage failure never acknowledges receipt")
check(not records.p_100.Data.Receipts.outage,"failed write does not durably mark receipt")
check(Data.read(b)==nil,"storage ownership uncertainty freezes profile")
fail=false
-- Simulate lease expiry after disconnected server; a new session recovers durable state.
records.p_100.Lock.Expires=0
local c={UserId=100}; players[100]=c
check(Data.load(c),"expired session lease can recover")
check(Data.read(c).Money==2100,"failed receipt did not corrupt persisted balance")
check(market.ProcessReceipt({PlayerId=100,ProductId=111,PurchaseId="outage"})=="granted","deferred receipt retries after recovery")
check(Data.read(c).Money==4100,"recovered receipt grants once")
Bag.new(Data,economy,analytics)
check(Bag.capacity(c,Data.read(c))==30,"starter capacity")
Data.transaction(c,function(p) p.Ore={["1:1"]=10,["1:2"]=2}; return true end)
economy.multiplier=function() return 2 end
check(Bag.sell(c),"inventory can sell")
check(Data.read(c).Money==4132 and Bag.count(Data.read(c))==0,"sale consumes inventory and applies multiplier once")
check(not Bag.sell(c),"empty inventory cannot be sold twice")
Rank.new(Data,analytics)
check(Rank.buy(c) and Data.read(c).Rank==2,"rank purchase charges and advances")
Shop.new(Data,analytics)
check(Shop.buy(c,"Pick") and Data.read(c).Pick==2,"pick upgrade purchase")
check(not Shop.buy(c,"NotReal"),"unknown upgrade rejected")
Config.Prototype=false
Data.transaction(c,function(p) p.Rank=26; p.Money=120000; p.Ore={["1:1"]=5}; return true end)
Prestige.new(Data,economy,analytics)
check(Prestige.buy(c),"eligible prestige succeeds")
local p=Data.read(c)
check(p.Rank==1 and p.Money==0 and p.Pick==1 and Bag.count(p)==0 and p.Tokens==10,"prestige resets and grants exact retained token award")
Retention.new(Data,analytics)
check(Retention.daily(c),"daily reward grants")
check(not Retention.daily(c),"same-day claim rejected")
check(Retention.code(c,"WELCOME"),"valid code grants")
check(not Retention.code(c,"WELCOME"),"code replay rejected")
print("RESULT",passed,"checks passed")
'''
def main():
 parser=argparse.ArgumentParser(); parser.add_argument('--luau',default='luau'); args=parser.parse_args()
 script=HEADER+'\nlocal Config='+module('src/ReplicatedStorage/Shared/Config.luau')
 for name,file in [('Data','DataService'),('Money','MonetizationService'),('Bag','BackpackService'),('Rank','RankService'),('Shop','ShopService'),('Prestige','PrestigeService'),('Retention','RetentionService')]:
  script+='\nlocal '+name+'='+module('src/ServerScriptService/Services/'+file+'.luau')
 with tempfile.TemporaryDirectory() as d:
  file=Path(d)/'services.luau';file.write_text(script+'\n'+TESTS)
  subprocess.run([args.luau,str(file)],check=True)
if __name__=='__main__':main()
