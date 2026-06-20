WITH all_players AS(
select player_id,player_name,player_role,team,season,batting_ranking AS IPL_RANK ,batting_rating AS rating from v_batter_rankings
UNION 
select player_id,player_name,player_role,team,season,bowling_rank AS IPL_RANK,bowling_rating AS rating from v_bowler_rankings
UNION
select player_id,player_name,player_role,team,season,allrounder_rank AS IPL_RANK,allrounder_rating AS rating from v_allrounder_rankings),
vfm AS(
select
        ap.player_id,
        ap.player_name, 
        ap.player_role, 
        ap.team, 
        ap.season, 
        ap.IPL_RANK, 
        ap.rating,
        a.sold_price_cr , 
ROUND((ap.rating/a.sold_price_cr),2) AS valueformoney,
case 
	when (ap.rating / a.sold_price_cr)>=8  then '5 - Steal_Buy'
    when (ap.rating / a.sold_price_cr)>=6  then '4 - Good_Buy'
    when (ap.rating / a.sold_price_cr)>=4  then '3 - Fair_Buy'
    when (ap.rating / a.sold_price_cr)>=2  then '2 - Overpriced'
   else '1 - Poor Buy'
   end AS stars
from all_players ap JOIN auction a ON ap.player_id=a.player_id AND ap.season=a.season)
SELECT 
    player_name, player_role, team, season,
    sold_price_cr, rating, IPL_rank,
    valueformoney,stars
FROM vfm
ORDER BY season, valueformoney DESC;



