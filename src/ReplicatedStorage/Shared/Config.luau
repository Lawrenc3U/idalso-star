--!strict
-- Set IDs to your own published products. Zero IDs hide purchase buttons.
local C: any = {}
C.Audio = {Break=0, Sell=0, Rank=0, Music=0} -- upload assets/audio/*.wav and set IDs
C.DataStore = "YardworkProfiles_v1"
C.Prototype = true -- false enables all 26 ranks and prestige
C.StudioMemory = true -- Studio-only, never used by published servers
C.PlayerCap = 8 -- set the same cap in experience settings; profile on devices before raising
C.RankCount = if C.Prototype then 3 else 26
C.ResetSeconds = 300
C.Grid = 6
C.Depth = 3
C.BlockSize = 4
C.Reach = 22
C.Ores = {
 {Name="Chalk", Weight=70, Value=1, Health=1, Color=Color3.fromRGB(220,224,209)},
 {Name="Copper", Weight=25, Value=3, Health=2, Color=Color3.fromRGB(223,139,82)},
 {Name="Glowstone", Weight=5, Value=8, Health=3, Color=Color3.fromRGB(79,220,179)},
}
C.Picks = {
 {Name="Yard Pick", Cost=0, Damage=1, Interval=0.45},
 {Name="Trusty Pick", Cost=180, Damage=2, Interval=0.38},
 {Name="Workshop Pick", Cost=800, Damage=3, Interval=0.30},
 {Name="Foreman Pick", Cost=4500, Damage=5, Interval=0.24},
}
C.Bags = {30,60,120,240,480}
C.BagCosts = {0,150,650,2500,10000}
C.Passes = {Money=0, Tokens=0, Auto=0, Backpack=0, VIP=0}
-- IDs must be unique, nonzero, and belong to this experience before enabling.
C.Products = {
 {Id=0, Name="Starter Pack", Kind="Starter", Amount=500, Robux=49},
 {Id=0, Name="Pocket Money", Kind="Money", Amount=2000, Robux=29},
 {Id=0, Name="Workshop Fund", Kind="Money", Amount=12000, Robux=99},
 {Id=0, Name="2x Money: 15 min", Kind="Boost", Amount=900, Robux=29},
 {Id=0, Name="2x Money: 30 min", Kind="Boost", Amount=1800, Robux=49},
 {Id=0, Name="2x Money: 60 min", Kind="Boost", Amount=3600, Robux=79},
 {Id=0, Name="Mine Reset Credit", Kind="Reset", Amount=1, Robux=19},
}
C.Codes = {WELCOME={Money=100, Tokens=0}} -- rotate/expire on server before campaigns
C.Event = {Name="Workshop Weekend", Start=0, Finish=0, Bonus=1} -- UTC timestamps; inactive by default
C.TokenPrices = {Fortune=5, Chain=8, Burst=12, Capacity=5, Skin=10, Pet=15}
function C.rankCost(rank: number): number return if rank==1 then 900 else math.floor(1800 * 1.34 ^ (rank-2)) end
function C.rankMultiplier(rank: number): number return 1 + (rank-1)*0.08 end
function C.prestigeCost(prestiges: number): number return math.floor(120000*(1+prestiges*0.25)) end
function C.oreValue(ore: number, tier: number): number return math.floor(C.Ores[ore].Value * 1.2^(tier-1)) end
return C
