with bowling_kpi AS (
select p.player_name,
	p.player_role,
    bowl.season,
    SUM(bowl.matches) AS matches,
    SUM(bowl.wickets) AS wickets,
	round(SUM(bowl.runs_given)/NULLIF(SUM(bowl.overs),0),2) AS economy,
	round(SUM(bowl.wickets)/NULLIF(SUM(bowl.matches),0),2) AS wkt_per_match,
	round(SUM(bowl.dot_balls)*100/NULLIF(SUM(bowl.overs)*6,0),2) AS dot_pct
from players p JOIN bowling_stats bowl ON p.player_id=bowl.player_id 
group by p.player_name,p.player_role,bowl.season)

select * from bowling_kpi
order by  wickets desc,economy asc;