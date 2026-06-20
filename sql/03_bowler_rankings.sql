CREATE OR REPLACE VIEW v_bowler_rankings AS
WITH BowlerStats AS (
    -- Calculate raw metrics and individual percentile ranks first
    SELECT 
        p.player_id,
        p.player_name,
        p.team,
        p.player_role,
        bowl.season,
        SUM(bowl.wickets) AS wickets,
        ROUND(SUM(bowl.runs_given) / NULLIF(SUM(bowl.overs), 0), 2) AS economy,
        ROUND(SUM(bowl.wickets) * 1.0 / NULLIF(SUM(bowl.matches), 0), 2) AS wkt_per_match,
        ROUND(SUM(bowl.dot_balls) * 100.0 / NULLIF(SUM(bowl.overs) * 6, 0), 2) AS dot_pct,
      
        PERCENT_RANK() OVER (PARTITION BY bowl.season ORDER BY SUM(bowl.runs_given) / NULLIF(SUM(bowl.overs), 0) DESC) AS eco_pct,
        PERCENT_RANK() OVER (PARTITION BY bowl.season ORDER BY SUM(bowl.wickets) * 1.0 / NULLIF(SUM(bowl.matches), 0)) AS wpm_pct,
        PERCENT_RANK() OVER (PARTITION BY bowl.season ORDER BY SUM(bowl.dot_balls) * 100.0 / NULLIF(SUM(bowl.overs) * 6, 0)) AS dot_pct_rank
    FROM players p
    JOIN bowling_stats bowl ON p.player_id = bowl.player_id
    WHERE p.player_role = 'Bowler'
    GROUP BY p.player_id, p.player_name, p.team, bowl.season
)
SELECT *,
    ROUND((0.3 * eco_pct + 0.4 * wpm_pct + 0.3 * dot_pct_rank) * 100, 1) AS bowling_rating,
    RANK() OVER (PARTITION BY season ORDER BY (0.3 * eco_pct + 0.4 * wpm_pct + 0.3 * dot_pct_rank) DESC) AS bowling_rank
FROM BowlerStats;
