CREATE TABLE IF NOT EXISTS olympicdata (
	id INT,
    name VARCHAR,
    sex VARCHAR,
    age VARCHAR,
    height VARCHAR,
    weight VARCHAR,
    team VARCHAR,
    noc VARCHAR,
    games VARCHAR,
    year INT,
    season VARCHAR,
    city VARCHAR,
    sport VARCHAR,
    event VARCHAR,
    medal VARCHAR
);

CREATE TABLE IF NOT EXISTS olympicregions (
	noc VARCHAR,
	region VARCHAR,
	notes VARCHAR
);

