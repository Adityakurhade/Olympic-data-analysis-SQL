SELECT * FROM olympicdata;

select * from olympicregions;

-- QUESTIONS

-- Q. 1. Find how many olympic games have been held

SELECT COUNT(DISTINCT games)
FROM olympicdata;

-- Q 2. List Down all the olympic games held so far

SELECT year, season, city
FROM OLYMPICDATA
GROUP BY year, season, city
ORDER BY year;


-- Q 3. Mention the total no of nations who participated in each olympics game?

with all_countries as 
	(select games, nr.region
	from olympicdata od
	join olympicregions nr
	on od.noc = nr.noc
	group by games, nr.region)
select games, count(1) as no_countries
from all_countries
group by games
order by games;


-- Q 4. Which year saw the highest and lowest no of countries participating in olympics

WITH all_countries as(
	SELECT games, nr.region
	FROM olympicdata od
	JOIN olympicregions nr
	ON od.noc = nr.noc
	GROUP BY games, nr.region
),
country_count AS(
	SELECT games, COUNT(1) AS no_countries
	FROM all_countries
	GROUP BY games
	ORDER BY games
)
SELECT DISTINCT CONCAT(FIRST_VALUE(games) OVER(ORDER BY no_countries), '-',
			  FIRST_VALUE(no_countries) OVER(ORDER BY no_countries)) AS lowest_countries,
	   CONCAT(FIRST_VALUE(games) OVER(ORDER BY no_countries),'-',
			 FIRST_VALUE(no_countries) OVER(ORDER BY no_countries DESC)) AS highest_countries
FROM country_count
ORDER BY 1;

-- Q. 5. Which nation has participated in all of the olympic games

WITH all_countries AS (
	SELECT games, nr.region
	FROM olympicdata od
	JOIN olympicregions nr
	ON od.noc = nr.noc
	GROUP BY games, nr.region
	ORDER BY games),
game_count_result AS
	(SELECT region, COUNT(games) as game_count
	FROM all_countries
	GROUP BY region
	ORDER BY game_count DESC)
SELECT region AS Countries, game_count -- just for reference
FROM game_count_result
WHERE game_count >= (SELECT COUNT(DISTINCT games)
					FROM all_countries);


-- Q. 6.  Identify the sport which was played in all summer olympics.


-- counting number of games played in summer
WITH total_summer_games AS (
	SELECT COUNT(DISTINCT games) AS total_summer_game_count
	FROM olympicdata
	WHERE games LIKE '%Summer'
),
-- counting number of games for each sport
no_games_for_sport AS (
	SELECT sport,COUNT(DISTINCT games) AS game_count_sport
	FROM olympicdata
	GROUP BY sport
)
SELECT sport, game_count_sport, total_summer_game_count
FROM no_games_for_sport ns
JOIN total_summer_games nt
ON ns.game_count_sport = nt.total_summer_game_count;

----- different approach to return only names of sports

SELECT sport
FROM olympicdata
GROUP BY sport
HAVING COUNT(DISTINCT games) = (SELECT COUNT(DISTINCT games)
								FROM olympicdata
								WHERE games LIKE '%Summer');



-- Q 7. Which Sports were just played only once in all the olympics.

SELECT * 
FROM (
	SELECT sport, games, COUNT(1) AS sport_played_times
	FROM olympicdata
	GROUP BY sport, games
	ORDER BY sport_played_times ) x
WHERE x.sport_played_times = 1;


-- Q.8. Write SQL query to fetch the total no of sports played in each olympics.

SELECT games, COUNT(DISTINCT sport) AS no_sports_played
FROM olympicdata
GROUP BY games
ORDER BY no_sports_played;

-- Q. 9. Fetch oldest athletes to win a gold medal

WITH maxage AS (
	SELECT MAX(age) as age
	FROM olympicdata
	WHERE medal = 'Gold' AND age <> 'NA'
)
SELECT DISTINCT * 
FROM olympicdata od
JOIN maxage mg
ON od.age = mg.age;


-- approach 2

SELECT * 
FROM olympicdata
WHERE age = (SELECT MAX(age)
			FROM olympicdata
			WHERE medal ='Gold' AND age <> 'NA')
AND medal = 'Gold';
			
			
-- Q. 10. Write a SQL query to get the ratio of male and female participants			
			
WITH male_count AS (
	SELECT COUNT(DISTINCT name) AS m_participants
	FROM olympicdata
	WHERE sex = 'M'),
female_count AS (
	SELECT COUNT(DISTINCT name) AS f_participants
	FROM olympicdata
	WHERE sex = 'F'),
participants AS (SELECT COUNT (DISTINCT name) as tot_participants
				FROM olympicdata)
SELECT ROUND(male_count.m_participants::decimal/participants.tot_participants::decimal, 3) AS male_ratio,
ROUND(female_count.f_participants::decimal/participants.tot_participants::decimal, 3) AS female_ratio
FROM male_count, female_count, participants;

-- different approach if we have to find male to female ratio

WITH male_count AS (
	SELECT COUNT(DISTINCT name) AS m_participants
	FROM olympicdata
	WHERE sex = 'M'),
female_count AS (
	SELECT COUNT(DISTINCT name) AS f_participants
	FROM olympicdata
	WHERE sex = 'F')
SELECT CONCAT('1 : ',
			 ROUND(m_participants::decimal/f_participants::decimal,3)) AS male_to_female_ratio
FROM male_count, female_count;


-- Q.11. fetch the top 5 athletes who have won the most gold medals.

WITH t1 AS 
	(SELECT name, team, COUNT(medal) g_ct
	FROM olympicdata
	WHERE medal = 'Gold'
	GROUP BY name, team
	ORDER BY g_ct DESC),
t2 AS (
	SELECT *,
	DENSE_RANK() OVER(ORDER BY g_ct DESC) AS rnk
	FROM t1
)
SELECT name, team, g_ct AS Gold_medals
FROM t2
WHERE rnk <= 5;

-- Q. 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

WITH t1 AS
	(SELECT name, team, COUNT(medal) medal_count
	FROM olympicdata
	WHERE medal in ('Gold', 'Silver', 'Bronze')
	GROUP BY name, team
	ORDER BY medal_count DESC),
t2 AS (
	SELECT *,
	DENSE_RANK() OVER(ORDER BY medal_count DESC) AS rnk
	FROM t1
)
SELECT name, team, medal_count
FROM t2
WHERE rnk <= 5;

-- Q. 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

WITH countries AS (
	SELECT nr.region, COUNT(medal) AS total_medals
	FROM olympicdata od
	JOIN olympicregions nr
	ON od.noc = nr.noc
	WHERE medal in ('Gold', 'Silver', 'Bronze')
	GROUP BY nr.region
	ORDER BY total_medals DESC
),
medal_rank AS (
	SELECT *,
	DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rnk
	FROM countries
)
SELECT region, total_medals, rnk
FROM medal_rank
WHERE rnk <= 5;

-- Q. 14. List down total gold, silver and bronze medals won by each country.

SELECT nr.region AS country, medal, COUNT(medal) as total_medals
FROM olympicdata od
JOIN olympicregions nr
ON od.noc= nr.noc
WHERE medal <> 'NA'
GROUP BY nr.region, medal
ORDER BY nr.region, medal;

CREATE EXTENSION tablefunc;

SELECT country
-- replace null values with
,COALESCE(gold, 0) AS gold,
COALESCE(silver, 0) AS silver
,COALESCE(bronze, 0) AS bronze
FROM CROSSTAB('SELECT nr.region AS country, medal, COUNT(medal) as total_medals
			  FROM olympicdata od
			  JOIN olympicregions nr
			  ON od.noc= nr.noc
              WHERE medal <> ''NA''
			  GROUP BY nr.region, medal
			  ORDER BY nr.region, medal',
			 'values (''Bronze''),(''Gold''), (''Silver'')')
			AS result(country VARCHAR, bronze BIGINT, gold BIGINT, silver BIGINT)
ORDER BY gold DESC, silver DESC, bronze DESC;

-- Q. 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

select * from olympicdata;

SELECT  od.games, nr.region,
SUM(CASE WHEN medal = 'Gold'THEN 1 ELSE 0 END) AS gold,
SUM(CASE WHEN medal = 'Silver'THEN 1 ELSE 0 END) AS silver,
SUM(CASE WHEN medal = 'Bronze'THEN 1 ELSE 0 END) AS bronze
FROM olympicdata od
JOIN olympicregions nr
ON od.noc = nr.noc
GROUP BY games, nr.region
ORDER BY games;


-- Q.16 Identify which country won the most gold, most silver and most bronze medals in each olympic games

WITH t AS 
	(SELECT  od.games, nr.region,
	SUM(CASE WHEN medal = 'Gold'THEN 1 ELSE 0 END) AS gold,
	SUM(CASE WHEN medal = 'Silver'THEN 1 ELSE 0 END) AS silver,
	SUM(CASE WHEN medal = 'Bronze'THEN 1 ELSE 0 END) AS bronze
	FROM olympicdata od
	JOIN olympicregions nr
	ON od.noc = nr.noc
	GROUP BY games, nr.region
	ORDER BY games)
SELECT DISTINCT games,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY gold DESC),'-',
	  FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY gold DESC)) AS max_gold,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY silver DESC),'-',
	  FIRST_VALUE(silver) OVER(PARTITION BY games ORDER BY silver DESC)) AS max_silver,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY bronze DESC),'-',
	  FIRST_VALUE(bronze) OVER(PARTITION BY games ORDER BY bronze DESC)) AS max_bronze
FROM t
ORDER BY games;

-- Q. 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

WITH t AS 
	(SELECT  od.games, nr.region,
	SUM(CASE WHEN medal = 'Gold'THEN 1 ELSE 0 END) AS gold,
	SUM(CASE WHEN medal = 'Silver'THEN 1 ELSE 0 END) AS silver,
	SUM(CASE WHEN medal = 'Bronze'THEN 1 ELSE 0 END) AS bronze,
	SUM(CASE WHEN medal <> 'NA' THEN 1 ELSE 0 END) AS all_medals
	FROM olympicdata od
	JOIN olympicregions nr
	ON od.noc = nr.noc
	GROUP BY games, nr.region
	ORDER BY games)
SELECT DISTINCT games,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY gold DESC),'-',
	  FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY gold DESC)) AS max_gold,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY silver DESC),'-',
	  FIRST_VALUE(silver) OVER(PARTITION BY games ORDER BY silver DESC)) AS max_silver,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY bronze DESC),'-',
	  FIRST_VALUE(bronze) OVER(PARTITION BY games ORDER BY bronze DESC)) AS max_bronze,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY all_medals DESC),'-',
	  FIRST_VALUE(all_medals) OVER(PARTITION BY games ORDER BY all_medals DESC)) AS max_medals
FROM t
ORDER BY games;


-- Q.18. Which countries have never won gold medal but have won silver/bronze medals?

WITH T1 AS 
	(SELECT nr.region,
	SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold,
	SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
	SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
	FROM olympicdata od
	JOIN olympicregions nr 
	ON od.noc = nr.noc
	GROUP BY nr.region
	ORDER BY silver, bronze)
SELECT region, gold, silver, bronze
FROM T1
WHERE gold = 0 AND (silver > 0 or bronze > 0);

-- Q.19 In which Sport/event, India has won highest medals.

SELECT sport, COUNT(medal) AS total_medals
FROM olympicdata od
JOIN olympicregions nr
ON od.noc = nr.noc
WHERE medal <> 'NA' AND nr.region = 'India'
GROUP BY od.sport
ORDER BY total_medals DESC
LIMIT 1;

-- Q.20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

SELECT nr.region, od.sport, od.games, COUNT(od.medal) AS total_medals
FROM olympicdata od
JOIN olympicregions nr
ON od.noc = nr.noc
WHERE medal <> 'NA' AND nr.region = 'India' AND od.sport = 'Hockey'
GROUP BY od.games, nr.region, od.sport
ORDER BY od.games;






