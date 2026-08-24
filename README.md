# 🏏 IPL Auction Value vs Performance Auditor

This project answers a simple question: when IPL teams spend crores on a player, do they actually get their money's worth?

Teams often pay big money based on reputation or a bidding war, not always based on real performance. So I built a system that scores every player on **value for money** — how much they performed compared to how much they were sold for. I used SQL to do the analysis and built a dashboard in Google Sheets to explore the results.

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

One small detail I added on purpose — the `season` column uses `ENUM` instead of a plain number. This means the database only accepts specific years (2022, 2023) and rejects anything else, like a typo or an invalid year, before it even gets saved.

---

## How the scoring works

**Step 1 — Turn raw stats into rates.**
Total runs alone doesn't mean much. So I calculated strike rate, batting average, and boundary percentage for batsmen. For bowlers, I calculated economy rate, wickets per match, and dot-ball percentage. All-rounders get both sets.

**Step 2 — Rank each player within their own role.**
A normal rank (1st, 2nd, 3rd) doesn't work well when group sizes are different — 8 batsmen vs 5 bowlers means their ranks aren't really comparable. So I used a SQL window function called `PERCENT_RANK()`, which converts every player's rank into a number between 0 and 1, no matter how many players are in that group.

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


```

```

---

## The DASHBOARD Overview

SQL gives the right numbers, but a dashboard makes those numbers usable for someone who isn't going to read a query. Here's what it has:
1) A bar chart depicting Value for money ratings
2) A table with complete rankings of players


<img width="1215" height="746" alt="image" src="https://github.com/user-attachments/assets/12a5e440-762f-48b0-b1b3-f11a7ac4aa78" />



**A bar chart** ranking players by their value-for-money score according to season(2022 above and 2023 below), highest at the top. Switching the role filter to "Bowler" shows Deepak Nair clearly at the top — which matches the data, since he had the best value-for-money score in the whole dataset, in both seasons.

<img width="1131" height="462" alt="Bar" src="https://github.com/user-attachments/assets/41b4da96-2d03-448b-9744-ce746a0d0ac4" />



**A rankings table** showing the full leaderboard for whichever role and season is selected, sorted by rank — similar to how a sports ranking page would look.

<img width="1836" height="395" alt="Ranking" src="https://github.com/user-attachments/assets/6ccb3e80-af06-4e38-85ae-823e52b12d6d" />



---

## A couple of things the data showed me

Deepak Nair, a bowler bought for just ₹1.5 Cr, had the best economy rate, most wickets per match, and best dot-ball percentage among bowlers — a perfect rating of 100. His value-for-money score came out to 66.67, the best in the whole dataset, in both seasons.

On the other side, Marco de Bruyn was bought for ₹9-11 Cr in both seasons but only had a rating of 15-16. That's a clear example of a player being overpaid compared to what they delivered.

---

## Tech I used

MySQL · Google Sheets · Window Functions 

---

## A note on the data

Player names, prices, and stats in this project are made up — I built them to follow realistic IPL patterns without using any real player data.

---

