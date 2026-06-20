CREATE OR REPLACE VIEW v_allrounder_rankings AS
WITH ar_bat AS (
    SELECT
        p.player_id, p.player_name, p.team,p.player_role, bat.season,
        ROUND(SUM(bat.runs)*100.0 / NULLIF(SUM(bat.balls_faced), 0), 2) AS strike_rate,
        ROUND(SUM(bat.runs)*1.0 / NULLIF(SUM(bat.matches), 0), 2) AS average,
        ROUND((SUM(bat.fours)*4 + SUM(bat.sixes)*6)*100.0 / NULLIF(SUM(bat.runs), 0), 2) AS bdry_pct
    FROM players p
    JOIN batting_stats bat ON p.player_id = bat.player_id
    WHERE p.player_role = 'All-Rounder'
    GROUP BY p.player_id, p.player_name, p.team, bat.season
),
ar_bowl AS (
    SELECT
        p.player_id, bowl.season,
        ROUND(SUM(bowl.runs_given) / NULLIF(SUM(bowl.overs), 0), 2) AS economy,
        ROUND(SUM(bowl.wickets)*1.0 / NULLIF(SUM(bowl.matches), 0), 2) AS wkt_per_match,
        ROUND(SUM(bowl.dot_balls)*100.0 / NULLIF(SUM(bowl.overs)*6, 0), 2) AS dot_pct
    FROM players p
    JOIN bowling_stats bowl ON p.player_id = bowl.player_id
    WHERE p.player_role = 'All-Rounder'
    GROUP BY p.player_id, bowl.season
),
-- Calculate individual percentile ranks here
RankedScores AS (
    SELECT
        b.*, bw.economy, bw.wkt_per_match, bw.dot_pct,
        PERCENT_RANK() OVER (PARTITION BY b.season ORDER BY b.strike_rate) AS sr_pct,
        PERCENT_RANK() OVER (PARTITION BY b.season ORDER BY b.average) AS avg_pct,
        PERCENT_RANK() OVER (PARTITION BY b.season ORDER BY b.bdry_pct) AS bdry_rank,
        PERCENT_RANK() OVER (PARTITION BY b.season ORDER BY bw.economy DESC) AS eco_rank,
        PERCENT_RANK() OVER (PARTITION BY b.season ORDER BY bw.wkt_per_match) AS wpm_rank,
        PERCENT_RANK() OVER (PARTITION BY b.season ORDER BY bw.dot_pct) AS dot_rank
    FROM ar_bat b
    JOIN ar_bowl bw ON b.player_id = bw.player_id AND b.season = bw.season
)
-- Perform final aggregation
SELECT *,
    ROUND((0.5 * sr_pct + 0.1 * avg_pct + 0.4 * bdry_rank) * 100, 1) AS batting_score,
    ROUND((0.3 * eco_rank + 0.4 * wpm_rank + 0.3 * dot_rank) * 100, 1) AS bowling_score,
    ROUND(((0.5 * sr_pct + 0.1 * avg_pct + 0.4 * bdry_rank) * 100 + 
           (0.3 * eco_rank + 0.4 * wpm_rank + 0.3 * dot_rank) * 100) / 2, 1) AS allrounder_rating,
    RANK() OVER (
        PARTITION BY season 
        ORDER BY ((0.5 * sr_pct + 0.1 * avg_pct + 0.4 * bdry_rank) * 100 + 
                  (0.3 * eco_rank + 0.4 * wpm_rank + 0.3 * dot_rank) * 100) / 2 DESC
    ) AS allrounder_rank
FROM RankedScores;