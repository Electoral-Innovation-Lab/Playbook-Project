-- DEMOCRACY REFORM DATABASE SCHEMA
-- Single source of truth. Both developers build their local DB from this file.
-- To (re)build a clean local database:
--   dropdb democracy 2>/dev/null; createdb democracy
--   psql democracy < schema.sql
--   psql democracy < seed.sql

-- states
CREATE TABLE states (
    state_id     SERIAL PRIMARY KEY,
    name         VARCHAR(100) UNIQUE NOT NULL,
    abbreviation CHAR(2)      UNIQUE NOT NULL
);

-- reform scores (one composite score per state per day)
CREATE TABLE reform_scores (
    score_id  SERIAL PRIMARY KEY,
    state_id  INTEGER NOT NULL REFERENCES states(state_id),
    scored_at DATE    NOT NULL DEFAULT CURRENT_DATE,
    score     NUMERIC(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
    grade     CHAR(2) NOT NULL CHECK (grade IN
                  ('A+','A','A-','B+','B','B-','C+','C','C-','D+','D','D-','F')),
    UNIQUE (state_id, scored_at)
);

-- reform categories (the dimensions that make up a composite score)
CREATE TABLE reform_categories (
    category_id SERIAL PRIMARY KEY,
    category    VARCHAR(100) NOT NULL UNIQUE,   -- e.g. 'Voter Access'
    description TEXT,
    weight      NUMERIC(4,2) NOT NULL DEFAULT 1.0
);

-- per-category scores that roll up into a composite reform_score
CREATE TABLE category_scores (
    cat_score_id SERIAL PRIMARY KEY,
    score_id     INTEGER NOT NULL REFERENCES reform_scores(score_id) ON DELETE CASCADE,
    category_id  INTEGER NOT NULL REFERENCES reform_categories(category_id),
    score        NUMERIC(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
    notes        TEXT,
    UNIQUE (score_id, category_id)
);

-- reform action pathways (concrete reforms in progress per state)
CREATE TABLE action_pathways (
    pathway_id  SERIAL PRIMARY KEY,
    state_id    INTEGER NOT NULL REFERENCES states(state_id),
    category_id INTEGER REFERENCES reform_categories(category_id),
    title       VARCHAR(200) NOT NULL,          -- e.g. 'Ranked-choice voting'
    description TEXT,
    status      VARCHAR(20)  NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','pending','passed','failed')),
    started_at  DATE,
    resolved_at DATE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- relevant news updates regarding democracy reform
CREATE TABLE news_articles (
    article_id   SERIAL PRIMARY KEY,
    state_id     INTEGER REFERENCES states(state_id),  -- NULL = national story
    category_id  INTEGER REFERENCES reform_categories(category_id),
    headline     VARCHAR(500) NOT NULL,
    summary      TEXT,                                 -- 1-sentence impact detail
    source_name  VARCHAR(200),                         -- e.g. 'The Guardian'
    source_url   TEXT,
    published_at TIMESTAMPTZ,
    score_delta  NUMERIC(5,2),                         -- score change from this story
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Helpful indexes for the queries the app runs most
CREATE INDEX idx_reform_scores_state   ON reform_scores(state_id);
CREATE INDEX idx_category_scores_score ON category_scores(score_id);
CREATE INDEX idx_pathways_state        ON action_pathways(state_id);
CREATE INDEX idx_news_published        ON news_articles(published_at DESC);
