#!/usr/bin/env python3
"""Generate a formula-driven workbook with cached results (pip install xlsxwriter)."""
from pathlib import Path
import math
import xlsxwriter
ROOT=Path(__file__).resolve().parents[1]
out=ROOT/'docs/06-economy.xlsx'
w=xlsxwriter.Workbook(out)
head=w.add_format({'bold':True,'bg_color':'#227784','font_color':'white'})
num=w.add_format({'num_format':'0.00'})
inputfmt=w.add_format({'bg_color':'#FFF2CC'})
def sheet(name,headers):
 s=w.add_worksheet(name);s.freeze_panes(1,1);s.write_row(0,0,headers,head);s.set_column(0,len(headers)-1,19);return s
s=sheet('Assumptions',['Parameter','Value','Meaning'])
values=[('Efficiency',.65,'Fraction of ideal mining/travel throughput'),('Travel seconds',10,'Per full backpack trip'),('Rank growth',1.34,'After first transition'),('First rank cost',900,'A to B'),('Second rank cost',1800,'B to C'),('Ore tier growth',1.2,'Floor each ore value separately'),('Rank bonus',.08,'Additive per rank'),('Prestige bonus',.2,'Additive per prestige'),('Prestige cap',5,'Maximum prestige multiplier'),('Base prestige money',120000,'Additional goal at Z'),('Prestige goal growth',.25,'Additional requirement per completed cycle'),('Tokens per prestige',10,'Before token pass')]
for row,(name,value,meaning) in enumerate(values,1):s.write(row,0,name);s.write(row,1,value,inputfmt);s.write(row,2,meaning)
s.set_column(2,2,56)
o=sheet('Blocks',['Ore','Weight','Base value','Health'])
for i,row in enumerate([['Chalk',.7,1,1],['Copper',.25,3,2],['Glowstone',.05,8,3]],1):o.write_row(i,0,row)
p=sheet('Equipment',['Pick','Cost','Damage','Interval','Bag capacity','Bag cost'])
for i,row in enumerate([['Yard',0,1,.45,30,0],['Trusty',180,2,.38,60,150],['Workshop',800,3,.30,120,650],['Foreman',4500,5,.24,240,2500],['-',0,0,0,480,10000]],1):p.write_row(i,0,row)
r=sheet('Ranks',['Rank','Tier','Pick tier','Bag tier','Weighted ore value','Hits per unit','Units/sec','Bag capacity','Money/min','Rank cost','Upgrade spend','Minutes to goal','Cumulative minutes'])
total=0; rates=[]; times=[]
for i in range(26):
 rank=i+1;row=i+1; n=row+1;pk=min(4,rank);bg=min(5,rank)
 damage=[1,2,3,5][pk-1];interval=[.45,.38,.3,.24][pk-1];cap=[30,60,120,240,480][bg-1]
 ev=sum(a*math.floor(b*1.2**i) for a,b in zip([.7,.25,.05],[1,3,8]))
 hits=sum(a*math.ceil(b/damage) for a,b in zip([.7,.25,.05],[1,2,3]));units=1/(hits*interval)
 rate=cap*ev*(1+i*.08)/(cap/units+10)*60*.65; rates.append(rate)
 cost=(900 if i==0 else math.floor(1800*1.34**(i-1))) if rank<26 else 120000
 spend=[0,330,1450,7000,10000][min(4,i)] if i<5 else 0
 mins=(cost+spend)/rate; total+=mins;times.append(mins)
 r.write_row(row,0,[chr(65+i),rank,pk,bg])
 r.write_formula(row,4,f'=SUMPRODUCT(Blocks!$B$2:$B$4,INT(Blocks!$C$2:$C$4*Assumptions!$B$7^(B{n}-1)))',num,ev)
 r.write_formula(row,5,f'=SUMPRODUCT(Blocks!$B$2:$B$4,ROUNDUP(Blocks!$D$2:$D$4/INDEX(Equipment!$C$2:$C$5,C{n}),0))',num,hits)
 r.write_formula(row,6,f'=1/(F{n}*INDEX(Equipment!$D$2:$D$5,C{n}))',num,units)
 r.write_formula(row,7,f'=INDEX(Equipment!$E$2:$E$6,D{n})',num,cap)
 r.write_formula(row,8,f'=H{n}*E{n}*(1+(B{n}-1)*Assumptions!$B$8)/(H{n}/G{n}+Assumptions!$B$3)*60*Assumptions!$B$2',num,rate)
 costformula=f'=IF(B{n}=26,Assumptions!$B$11,IF(B{n}=1,Assumptions!$B$5,INT(Assumptions!$B$6*Assumptions!$B$4^(B{n}-2))))'
 r.write_formula(row,9,costformula,num,cost)
 r.write_formula(row,10,f'=IF(B{n}=1,0,IF(C{n}>C{n-1},INDEX(Equipment!$B$2:$B$5,C{n}),0)+IF(D{n}>D{n-1},INDEX(Equipment!$F$2:$F$6,D{n}),0))',num,spend)
 r.write_formula(row,11,f'=(J{n}+K{n})/I{n}',num,mins)
 r.write_formula(row,12,f'=SUM(L$2:L{n})',num,total)
s=sheet('Scenarios',['Scenario','Money pass','Boost','Social/event','Prestige multiplier','Estimated hours'])
for i,row in enumerate([['Free first prestige',1,1,1,1],['Money pass',2,1,1,1],['Pass + boost',2,2,1,1],['All reward factors',2,2,2.15,5]],1):
 s.write_row(i,0,row);s.write_formula(i,5,f'=Ranks!M27/60/PRODUCT(B{i+1}:E{i+1})',num,total/60/math.prod(row[1:]))
s=sheet('Prestige',['Cycle','Previous prestiges','Permanent multiplier','Money goal at Z','Estimated cycle hours','Tokens'])
for i in range(1,11):
 n=i+1;prev=i-1;multi=min(5,1+prev*.2);goal=math.floor(120000*(1+prev*.25))
 s.write_row(i,0,[i,prev]);s.write_formula(i,2,f'=MIN(Assumptions!$B$10,1+B{n}*Assumptions!$B$9)',num,multi)
 s.write_formula(i,3,f'=INT(Assumptions!$B$11*(1+B{n}*Assumptions!$B$12))',num,goal)
 estimate=(total-times[-1]+goal/rates[-1])/multi/60
 s.write_formula(i,4,f'=(Ranks!M26+D{n}/Ranks!I27)/C{n}/60',num,estimate)
 s.write_formula(i,5,'=Assumptions!$B$13',num,10)
s=sheet('Token shop',['Upgrade','Base cost','Level cap','Pricing','Effect'])
for i,row in enumerate([['Fortune',5,5,'base * next level','8% bonus-unit chance/level'],['Chain',8,5,'base * next level','+1 adjacent block/level'],['Burst',12,5,'base * next level','Extra bounded radius targets'],['Capacity',5,5,'base * next level','+15 base capacity/level'],['Skin',10,1,'fixed','Gold blade cosmetic'],['Pet',15,1,'fixed','Local cosmetic buddy']],1):s.write_row(i,0,row)
s=sheet('Read me',['Notes'])
notes=['Design estimates, not playtest results. Yellow assumption cells are editable.','Cached values correspond to the shipped Config at generation; Excel recalculates formulas on open.','Ranks sheet assumes one mine per rank (expanded mode), no Fortune and no boosts.','Default prototype has one tier-1 mine; its B-to-C income is lower than the expanded model.','Equipment advances one tier each rank until max; upgrade spend is included in that rank goal.','Travel and efficiency dominate timing. Real upgrade order and shared-mine contention change results.','Prestige estimates exclude retained token-upgrade acceleration; treat later-cycle timing as conservative.','All-factor scenario assumes bonuses last the entire cycle; it is a bound, not expected behaviour.','Currency sources/sinks and reset rules are detailed in 01-game-design-doc.md.','Verify receipt handling, current monetization rules and actual prices on Creator Hub before launch.']
for i,t in enumerate(notes,1):s.write(i,0,t)
s.set_column(0,0,125)
w.close()
assert 5<=total/60<=8, total/60
print(f'Workbook saved: free first prestige {total/60:.2f} hours; early rank estimates {times[0]:.1f}/{times[1]:.1f} minutes')
