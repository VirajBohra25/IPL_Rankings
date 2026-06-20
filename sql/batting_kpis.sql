USE ipl;
WITH batting_kpi AS
 (select p.player_name,bat.season,SUM(bat.runs) as runs,SUM(bat.matches) as matches,p.player_role,
ROUND((SUM(bat.runs) * 100.0 / NULLIF(SUM(bat.balls_faced), 0)),2) AS strike_rate,
ROUND(((SUM(bat.fours) * 4 + SUM(bat.sixes) * 6) * 100.0 / NULLIF(SUM(bat.runs), 0)),2) AS bdry_pct
from players p JOIN batting_stats bat ON p.player_id=bat.player_id
group by p.player_name,bat.season,p.player_role)
select player_name,player_role,season,runs,ROUND((runs/matches),2) AS average,strike_rate,bdry_pct from batting_kpi;



