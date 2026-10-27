--!strict
-- All profile mutations use transaction(). No mutable profiles escape this module.
local DSS = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local Run = game:GetService("RunService")
local C = require(game.ReplicatedStorage.Shared.Config)
local Data: any = {Sessions={}, Closing=false}
local store = DSS:GetDataStore(C.DataStore)
local memory: {[string]: any} = {}
local function copy(x: any): any
 if type(x) ~= "table" then return x end
 local r = {}; for k,v in pairs(x) do r[k]=copy(v) end; return r
end
local function defaults(): any
 return {Version=1, Money=0, Tokens=0, Rank=1, Prestiges=0, Pick=1, Bag=1, Ore={},
 Enchants={Fortune=0,Chain=0,Burst=0,Capacity=0,Skin=0,Pet=0}, BoostUntil=0,
 ResetCredits=0, ResetPending=0, StarterOwned=false, Codes={}, Daily=-1, Streak=0, Receipts={},
 Milestones={}, TotalEarned=0, LastDay=-1, FirstDay=-1,
 Settings={Music=true,Effects=true,Motion=true}}
end
local function update(key: string, fn: (any)->any): (boolean, any)
 for attempt=1,4 do
  local ok,res=pcall(function()
   if Run:IsStudio() and C.StudioMemory then
    local nextValue=fn(copy(memory[key])); if nextValue then memory[key]=copy(nextValue) end
    return copy(memory[key])
   end
   return store:UpdateAsync(key,fn)
  end)
  if ok then return true,res end
  warn("Profile store retry",attempt) -- no private data in output
  task.wait(math.min(2^(attempt-1),8))
 end
 return false,nil
end
function Data.load(player: Player): boolean
 if Data.Closing then return false end
 local key="p_"..player.UserId
 local token=Http:GenerateGUID(false)
 local ok,record=update(key,function(old: any)
  if old and old.Data and old.Data.Version > 1 then return nil end
  if old and old.Lock and old.Lock.Expires > os.time() then return nil end
  local d=if old and old.Data then old.Data else defaults()
  -- v1 migration: fill newly introduced fields; unknown future versions are refused.
  for k,v in pairs(defaults()) do if d[k]==nil then d[k]=v end end
  return {Data=d,Lock={Token=token,Expires=os.time()+180}}
 end)
 if not ok or not record or not record.Lock or record.Lock.Token~=token then return false end
 Data.Sessions[player]={Key=key,Token=token,Profile=record.Data,Busy=false,Lost=false,Lease=record.Lock.Expires}
 return true
end
local function acquire(s: any): boolean
 while s.Busy do task.wait() end
 if s.Lost then return false end
 s.Busy=true; return true
end
local function persist(s: any, p: any, release: boolean): boolean
 local revision=Http:GenerateGUID(false)
 local ok,record=update(s.Key,function(old: any)
  if not old or not old.Lock or old.Lock.Token~=s.Token or old.Lock.Expires<=os.time() then return nil end
  return {Data=p,Revision=revision,Lock=if release then nil else {Token=s.Token,Expires=os.time()+180}}
 end)
 local valid=ok and record and record.Revision==revision and (if release then record.Lock==nil else record.Lock and record.Lock.Token==s.Token)
 if valid and not release then s.Lease=record.Lock.Expires end
 if not valid then s.Lost=true end
 return valid==true
end
function Data.read(player: Player): any
 local s=Data.Sessions[player]
 if not s or s.Lost or os.time() >= s.Lease-10 then return nil end
 return copy(s.Profile)
end
function Data.transaction(player: Player, fn: (any)->boolean, durable: boolean?): boolean
 local s=Data.Sessions[player]
 if not s or s.Busy or not acquire(s) then return false end
 if os.time()>=s.Lease-10 then s.Busy=false; return false end
 local candidate=copy(s.Profile)
 local ok,accept=pcall(fn,candidate)
 if not ok then warn("Profile transaction failed") end
 local success=ok and accept==true
 if success and durable then success=persist(s,candidate,false) end
 if success then s.Profile=candidate end
 s.Busy=false
 return success
end
function Data.save(player: Player, release: boolean?): boolean
 local s=Data.Sessions[player]; if not s or not acquire(s) then return false end
 local ok=persist(s,s.Profile,release==true)
 s.Busy=false
 if release or not ok then Data.Sessions[player]=nil end
 return ok
end
function Data.start()
 task.spawn(function()
  while not Data.Closing do
   task.wait(45)
   for player in pairs(Data.Sessions) do
    if not Data.save(player,false) then player:Kick("Saving unavailable. Please rejoin to protect your progress.") end
   end
  end
 end)
end
return Data
