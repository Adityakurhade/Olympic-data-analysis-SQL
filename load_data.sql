USE practice;

CREATE TABLE IF NOT EXISTS athlete_events(
	id INT,
    name VARCHAR(100),
    sex VARCHAR(30),
    age VARCHAR(30),
    height VARCHAR(30),
    weight VARCHAR(30),
    team VARCHAR(100),
    noc VARCHAR(50),
    games VARCHAR(100),
    year INT,
    season VARCHAR(100),
    city VARCHAR(50),
    sport VARCHAR(50),
    event VARCHAR(100),
    medal VARCHAR(50)
);

SELECT * FROM athlete_events;

SET GLOBAL lOCAL_INFILE= TRUE;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

SHOW GLOBAL VARIABLES LIKE 'secure-file-priv';

LOAD DATA LOCAL INFILE "C:\AdityaDATA\SQLPractice\INTERMEDIATE\Kaggledataset\olympicdata\athlete_events.csv"
INTO TABLE athlete_events
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

