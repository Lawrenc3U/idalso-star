--!strict
export type Profile = {
 Version: number, Money: number, Tokens: number, Rank: number, Prestiges: number,
 Pick: number, Bag: number, Ore: {[string]: number}, Enchants: {[string]: number},
 BoostUntil: number, ResetCredits: number, ResetPending: number, StarterOwned: boolean, Codes: {[string]: boolean},
 Daily: number, Streak: number, Receipts: {[string]: boolean}, Milestones: {[string]: boolean},
 TotalEarned: number, LastDay: number, FirstDay: number, Settings: {[string]: boolean},
}
return {}
