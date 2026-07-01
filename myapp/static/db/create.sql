-- Database Schema 

-- all us states to set basis for 50 state comprehensive reform guide
CREATE TABLE States (
    state_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    abbreviation CHAR(2) NOT NULL UNIQUE,
    description TEXT
);

-- final calculated democracy scores
CREATE TABLE Scores (
    score_id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES States(state_id) ON DELETE CASCADE,
    scored_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    score NUMERIC(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
    grade CHAR(2) NOT NULL CHECK (grade IN ('A+','A','A-','B+','B','B-','C+','C','C-','D+','D','D-','F')),
    UNIQUE (state_id, scored_at)
);

-- suggested reforms for democracy
CREATE TABLE Reforms (
    reform_id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES States(state_id),
    action_tag VARCHAR(200) NOT NULL,
    description TEXT,
    UNIQUE(state_id, description)
);

-- categories that determine democracy score
CREATE TABLE Metrics (
    metric_id SERIAL PRIMARY KEY,
    metric VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL
);

-- says which democracy metrics exist in a state 0 or 1
CREATE TABLE MetricsStatus (
    state_metric_id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES States(state_id) ON DELETE CASCADE,
    metric_id INTEGER NOT NULL REFERENCES Metrics(metric_id) ON DELETE CASCADE,
    status INTEGER NOT NULL CHECK(status IN (0,1)),
    UNIQUE(state_id, metric_id)
);

-- news stories with updates to democracy metrics and scores.
CREATE TABLE News (
    article_id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES States(state_id) ON DELETE CASCADE,
    category INTEGER REFERENCES Metrics(category) ON DELETE SET NULL,
    headline VARCHAR(500) NOT NULL,
    summary TEXT,
    source_url TEXT NOT NULL,
    published_at TIMESTAMPTZ NOT NULL,
    score_chg NUMERIC(5,2) NOT NULL, -- might not be necessary
    UNIQUE(state_id, source_url)
);

