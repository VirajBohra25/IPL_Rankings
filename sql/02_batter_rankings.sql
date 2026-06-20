CREATE OR REPLACE VIEW v_batter_rankings AS
WITH batting_rank AS (
    -- First, calculate raw stats and the individual percentile ranks
    SELECT 
        p.player_id,
        p.player_name,
        p.team,
        p.player_role,
        bat.season,
        SUM(bat.runs) AS runs,
        ROUND(SUM(bat.runs) * 1.0 / NULLIF(SUM(bat.matches), 0), 2) AS average,
        ROUND(SUM(bat.runs) * 100.0 / NULLIF(SUM(bat.balls_faced), 0), 2) AS strike_rate,
        ROUND((SUM(bat.fours)*4 + SUM(bat.sixes)*6) * 100.0 / NULLIF(SUM(bat.runs), 0), 2) AS bdry_pct,
        
        PERCENT_RANK() OVER (PARTITION BY bat.season ORDER BY SUM(bat.runs) * 100.0 / NULLIF(SUM(bat.balls_faced), 0)) AS sr_pct_rnk,
        PERCENT_RANK() OVER (PARTITION BY bat.season ORDER BY SUM(bat.runs) * 1.0 / NULLIF(SUM(bat.matches), 0)) AS avg_pct_rnk,
        PERCENT_RANK() OVER (PARTITION BY bat.season ORDER BY (SUM(bat.fours)*4 + SUM(bat.sixes)*6) * 100.0 / NULLIF(SUM(bat.runs), 0)) AS bdry_pct_rank
    FROM players p 
    JOIN batting_stats bat ON p.player_id = bat.player_id 
    WHERE p.player_role = 'Batsman' 
    GROUP BY p.player_id, p.player_name, p.team, bat.season
)
SELECT *,
    ROUND((0.5 * sr_pct_rnk + 0.2 * avg_pct_rnk + 0.3 * bdry_pct_rank) * 100, 1) AS batting_rating,
    RANK() OVER (PARTITION BY season ORDER BY (0.5 * sr_pct_rnk + 0.2 * avg_pct_rnk + 0.3 * bdry_pct_rank) DESC) AS batting_ranking from batting_rank;
