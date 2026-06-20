# 🏏 IPL Auction Value vs Performance Auditor

This project answers a simple question: when IPL teams spend crores on a player, do they actually get their money's worth?

Teams often pay big money based on reputation or a bidding war, not always based on real performance. So I built a system that scores every player on **value for money** — how much they performed compared to how much they were sold for. I used SQL to do the analysis and built an interactive dashboard in Excel/Google Sheets to explore the results.

---

## Why I built it this way

I didn't want to just rank players by runs or wickets — that's basic and doesn't tell you much. I wanted to rank them by *value*. A bowler bought for ₹1.5 Cr who has the best economy rate in the league is a better buy than an all-rounder bought for ₹17 Cr who performs averagely. The numbers should show that clearly.

I also didn't want to compare a batsman's strike rate directly to a bowler's economy rate — that's not a fair comparison, they're different skills. So I ranked each role separately: batsmen against batsmen, bowlers against bowlers, all-rounders against all-rounders. Only after each group has its own ranking do I bring in the price they were sold for.

---

## Project Structure

```
IPL-Auction-Value-Auditor/
├── README.md
├── sql/
│   ├── 01_schema_and_data.sql        # creates tables and inserts all data
│   ├── 02_batter_rankings.sql        # batsman ranking view
│   ├── 03_bowler_rankings.sql        # bowler ranking view
│   ├── 04_allrounder_rankings.sql    # all-rounder ranking view
│   ├── 05_final_vfm_scoring.sql      # combines everything into final scores
│   └── drafts/                       # earlier versions, kept to show progress
├── sheets/
│   ├── IPL_Rankings.xlsx             # the dashboard
│   ├── vfm_ratings.csv
│   ├── batting_stats.csv
│   └── bowling_stats.csv
└── screenshots/
    ├── dashboard_overview.png
    ├── bubble_chart_drilldown.png
    ├── filtered_view_allrounders.png
    └── player_rankings_table.png
```

---

## The database

Four tables, all connected by `player_id`.

```
players ──┬── auction        (price paid, per player per season)
          ├── batting_stats  (batsmen and all-rounders only)
          └── bowling_stats  (bowlers and all-rounders only)
```

20 players, 2 seasons (2022 and 2023), 40 total auction records.

One small detail I added on purpose — the `season` column uses `ENUM` instead of a plain number. This means the database only accepts specific years (2022, 2023, etc.) and rejects anything else, like a typo or an invalid year, before it even gets saved.

---

## How the scoring works

**Step 1 — Turn raw stats into rates.**
Total runs alone doesn't mean much. So I calculated strike rate, batting average, and boundary percentage for batsmen. For bowlers, I calculated economy rate, wickets per match, and dot-ball percentage. All-rounders get both sets.

**Step 2 — Rank each player within their own role.**
This is the part I had to think about the most. A normal rank (1st, 2nd, 3rd) doesn't work well when group sizes are different — 8 batsmen vs 5 bowlers means their ranks aren't really comparable. So I used a SQL window function called `PERCENT_RANK()`, which converts every player's rank into a number between 0 and 1, no matter how many players are in that group. This way, a batsman ranked 3rd out of 8 and a bowler ranked 3rd out of 5 can be compared fairly later.

```sql
PERCENT_RANK() OVER (PARTITION BY season ORDER BY strike_rate)
```

**Step 3 — Combine those numbers into one performance rating out of 100.**

```
Batting Rating = 0.5 × Strike Rate score + 0.2 × Average score + 0.3 × Boundary % score
Bowling Rating = 0.3 × Economy score + 0.4 × Wickets/Match score + 0.3 × Dot Ball % score
All-Rounder Rating = average of both
```

**Step 4 — Divide rating by price to get the Value-for-Money score.**

```sql
VFM Score = Performance Rating ÷ Sold Price (in ₹ Cr)
```

So if two players have the same rating but one cost half as much, the cheaper one gets a higher VFM score — which is exactly the point.

**Step 5 — Label each player with a simple verdict** based on their VFM score, so it's easy to read at a glance:

| VFM Score | Verdict |
|---|---|
| 8 or higher | Steal Buy |
| 6 to 8 | Good Buy |
| 4 to 6 | Fair Buy |
| 2 to 4 | Overpriced |
| Below 2 | Poor Buy |

---

## Why I split the SQL into views

My first attempt at this was one giant query with everything stacked inside it, and it was a nightmare to debug — if something looked wrong, I had no way to tell which part was broken. So I split the logic into three separate views instead: `v_batter_rankings`, `v_bowler_rankings`, and `v_allrounder_rankings`. Each one can be tested on its own. If the final numbers ever look off, I can check each view individually instead of untangling one massive query.

```sql
-- Final scoring query (sql/05_final_vfm_scoring.sql)
WITH all_players AS (
    SELECT player_id, player_name, player_role, team, season,
           batting_ranking AS IPL_RANK, batting_rating AS rating
    FROM v_batter_rankings
    UNION
    SELECT player_id, player_name, player_role, team, season,
           bowling_rank AS IPL_RANK, bowling_rating AS rating
    FROM v_bowler_rankings
    UNION
    SELECT player_id, player_name, player_role, team, season,
           allrounder_rank AS IPL_RANK, allrounder_rating AS rating
    FROM v_allrounder_rankings
)
SELECT player_name, player_role, team, season, sold_price_cr, rating,
       ROUND(rating / sold_price_cr, 2) AS valueformoney,
       CASE
           WHEN rating / sold_price_cr >= 8 THEN 'Steal Buy'
           WHEN rating / sold_price_cr >= 6 THEN 'Good Buy'
           WHEN rating / sold_price_cr >= 4 THEN 'Fair Buy'
           WHEN rating / sold_price_cr >= 2 THEN 'Overpriced'
           ELSE 'Poor Buy'
       END AS verdict
FROM all_players ap
JOIN auction a ON ap.player_id = a.player_id AND ap.season = a.season
ORDER BY season, valueformoney DESC;
```

I also used `NULLIF()` in every division in the project. Early on I ran into divide-by-zero errors on a few rows, and adding this guard fixed it — so I kept using it everywhere as good practice.

---

## The DASHBOARD Overview

SQL gives the right numbers, but a dashboard makes those numbers usable for someone who isn't going to read a query. Here's what it has:

<img width="1847" height="612" alt="dashboard_overview" src="https://github.com/user-attachments/assets/c7be7121-128b-4eb9-a5db-8b38c4167cf9" />


**Three slicers — Season, Role, and Name.** These are connected, so picking "All-Rounder" in the Role slicer automatically updates the Name slicer to only show all-rounder names. Both charts on the dashboard update at the same time when you change any slicer.

<img width="1852" height="612" alt="filtered_view_allrounders" src="https://github.com/user-attachments/assets/846e6105-489f-48ce-81d0-244f12b1d529" />


**A bar chart** ranking players by their value-for-money score according to season(2022 above and 2023 below), highest at the top. Switching the role filter to "Bowler" shows Deepak Nair clearly at the top — which matches the data, since he had the best value-for-money score in the whole dataset, in both seasons.

<img width="642" height="485" alt="image" src="https://github.com/user-attachments/assets/88c694c9-7dfc-495b-a9e0-1a01c19ae268" />

**A bubble chart** plotting price paid against performance rating, with bubble size showing value. Hovering over any bubble shows a small box with that player's full details — name, price, rating, role, and VFM score. Good value players cluster toward the top-left (high rating, low price), overpriced players cluster toward the bottom-right.

<img width="1852" height="622" alt="bubble_chart_drilldown" src="https://github.com/user-attachments/assets/fb92aeda-feb1-4062-8e76-149add7fb084" />

**A rankings table** showing the full leaderboard for whichever role and season is selected, sorted by rank — similar to how a sports ranking page would look.

<img width="1847" height="533" alt="player_rankings_table" src="https://github.com/user-attachments/assets/9724dbde-4d0f-4c63-a10a-93f9d425e5a9" />


---

## A couple of things the data showed me

Deepak Nair, a bowler bought for just ₹1.5 Cr, had the best economy rate, most wickets per match, and best dot-ball percentage among bowlers — a perfect rating of 100. His value-for-money score came out to 66.67, the best in the whole dataset, in both seasons.

On the other side, Marco de Bruyn was bought for ₹9-11 Cr in both seasons but only had a rating of 15-16. That's a clear example of a player being overpaid compared to what they delivered.

---

## Tech I used

MySQL · Google Sheets · Window Functions · Views · PivotTables 

---

## A note on the data

Player names, prices, and stats in this project are made up — I built them to follow realistic IPL patterns without using any real player data. The point of the project was the method, not the specific numbers.

---

