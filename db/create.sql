CREATE TABLE States (
    state_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    abbreviation CHAR(2) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE Metrics (
    metric_id SERIAL PRIMARY KEY,
    metric VARCHAR(100) NOT NULL UNIQUE,
    weight NUMERIC(4,2) NOT NULL DEFAULT 1.0,
    category VARCHAR(100) NOT NULL,
    score_id SERIAL NOT NULL REFERENCES Scores(score_id),
    state_id SERIAL NOT NULL REFERENCES States(state_id),
    status INTEGER NOT NULL DEFAULT 0,
    category_id SERIAL NOT NULL,
    UNIQUE(state_id, metric_id)
);

CREATE TABLE Scores (
    score_id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES States(state_id),
    scored_at DATE NOT NULL DEFAULT CURRENT_DATE,
    score NUMERIC(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
    grade CHAR(2) NOT NULL CHECK (grade IN ('A+','A','A-','B+','B','B-','C+','C','C-','D+','D','D-','F')),
    UNIQUE (state_id, score, scored_at)
);

CREATE TABLE News (
    article_id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES States(state_id),
    category_id INTEGER NOT NULL REFERENCES Metrics(category_id),
    headline VARCHAR(500) NOT NULL,
    summary TEXT,
    source_url TEXT NOT NULL,
    published_at TIMESTAMPTZ NOT NULL,
    score_chg NUMERIC(5,2) NOT NULL,
    UNIQUE(state_id, source_url)
);

CREATE TABLE Reforms (
    reform_id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES States(state_id),
    action_tag VARCHAR(200) NOT NULL,
    description TEXT,
    UNIQUE(state_id, description)
);

