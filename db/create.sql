-- DEMOCRACY REFORM DATABASE SCHEMA
-- To (re)build a clean local database:
--   dropdb democracy 2>/dev/null; createdb democracy
--   psql democracy < schema.sql
--   psql democracy < seed.sql

-- states
CREATE TABLE states (
    state_id SERIAL PRIMARY KEY,
    state_name VARCHAR(100) UNIQUE NOT NULL,
    abbreviation CHAR(2) UNIQUE NOT NULL,
    electoral_votes INTEGER NOT NULL
);

-- reform scores (one composite score per state per time - allow multiple updates in one day)
CREATE TABLE reform_scores (
    score_id  SERIAL PRIMARY KEY,
    state_id  INTEGER NOT NULL REFERENCES states(state_id),
    scored_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    score     NUMERIC(5,2) NOT NULL, -- CHECK (score BETWEEN 0 AND 100)
    grade     CHAR(2) CHECK (grade IN
                  ('A+','A','A-','B+','B','B-','C+','C','C-','D+','D','D-','F')),
    UNIQUE (state_id, scored_at)
);

-- reform categories (the dimensions that make up a composite score)
CREATE TABLE reform_categories (
    category_id SERIAL PRIMARY KEY,
    category    VARCHAR(100) NOT NULL UNIQUE CHECK(category IN
                    ('Electoral Participation', 'Fair Representation', 'Political Accountability',
                    'Campaign Finance', 'Civil Society', 'Political and Institutional Factors', 'Demographics')),   -- e.g. 'electoral participation'
    cat_description TEXT, -- description of each category
    cat_weight      NUMERIC(4,2) NOT NULL DEFAULT 1.0
);

-- per-category scores that roll up into a composite reform_score
CREATE TABLE category_scores (
    cat_score_id SERIAL PRIMARY KEY,
    score_id     INTEGER NOT NULL REFERENCES reform_scores(score_id) ON DELETE CASCADE,
    category_id  INTEGER NOT NULL REFERENCES reform_categories(category_id) ON DELETE CASCADE,
    score        NUMERIC(5,2),
    notes        TEXT,
    UNIQUE (score_id, category_id)
);

-- reform specific variables. these make up the reform categories
CREATE TABLE reform_category_variables (
    var_id SERIAL PRIMARY KEY,
    var_name VARCHAR(500) UNIQUE NOT NULL CHECK (var_name IN 
                            ('voter_turnout', 'voter_registration', 'partisan_fairness', 'competitiveness',
                            'compactness', 'per_county_split', 'county_split', 'num_county', 'elected_supreme_justice', 'retention_election_justice',
                            'partisan_justice_election', 'court_curbing_bill', 'statutory_initiative', 'constitutional_initiative',
                            'popular_referendum', 'congressional_money', 'legislative_money', 'congressional_money_percapita', 'legislative_money_percapita',
                            'lobbyist_money', 'campaign_finance_index', 'protest_index', 'local_news', 'free_speech', 'press_incidents', 'democratic_leaning',
                            'divided_government', 'divided_legislatures', 'bachelor_share','minority_share')),
    var_description TEXT,
    category_id INTEGER NOT NULL REFERENCES reform_categories(category_id)
);

-- values of the reform specific vars
CREATE TABLE category_variable_values (
    value_id SERIAL PRIMARY KEY,
    var_value NUMERIC(7,4),
    score_id INTEGER NOT NULL REFERENCES reform_scores(score_id) ON DELETE CASCADE,
    var_id INTEGER NOT NULL REFERENCES reform_category_variables(var_id) ON DELETE CASCADE
);

-- reform action pathways (concrete reforms in progress per state)
CREATE TABLE action_pathways (
    pathway_id  SERIAL PRIMARY KEY,
    state_id    INTEGER NOT NULL REFERENCES states(state_id),
    category_id INTEGER REFERENCES reform_categories(category_id),
    title       VARCHAR(200) NOT NULL,          -- e.g. 'Ranked-choice voting'
    path_description TEXT,
    path_status      VARCHAR(20)  NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','pending','passed','failed')),
    started_at  DATE,
    resolved_at DATE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- relevant news updates regarding democracy reform. every story, including national 
CREATE TABLE news_articles ( -- one article can update multiple states
    article_id   SERIAL PRIMARY KEY,
    headline     VARCHAR(500) NOT NULL,
    summary      TEXT,                                 -- 1-sentence impact detail
    source_name  VARCHAR(200),                         -- e.g. 'The Guardian'
    source_url   TEXT UNIQUE,
    published_at TIMESTAMPTZ NOT NULL,
    is_national  BOOLEAN NOT NULL DEFAULT FALSE,       
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- states affected by each news article. stories that affect specific states. national news stories not included
-- the only time a state is given a new reform score and updated category scores is when there is a news update article to cite
CREATE TABLE news_state_updates ( -- 
    article_id   INTEGER NOT NULL REFERENCES news_articles(article_id) ON DELETE CASCADE,
    state_id     INTEGER REFERENCES states(state_id) ON DELETE CASCADE,  
    score_id     INTEGER NOT NULL REFERENCES reform_scores(score_id) ON DELETE CASCADE,
    score_delta  NUMERIC(5,2),
    PRIMARY KEY (article_id, state_id),
    UNIQUE(score_id)
);

-- INDEXES
-- for the queries the app runs most
CREATE INDEX idx_reform_scores_state ON reform_scores(state_id);
CREATE INDEX idx_category_scores_score ON category_scores(score_id);
CREATE INDEX idx_pathways_state ON action_pathways(state_id);
CREATE INDEX idx_news_published ON news_articles(published_at DESC);
CREATE INDEX idx_reform_scores_state_latest ON reform_scores(state_id, scored_at DESC, score_id DESC);

-- TRIGGERS
-- state can have three scores at once and delete outdated (from reform_scores and category_scores due to delete cascade)
CREATE OR REPLACE FUNCTION keep_latest_3_reform_scores()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM reform_scores
    WHERE score_id IN (
        SELECT score_id
        FROM reform_scores
        WHERE state_id = NEW.state_id
        ORDER BY scored_at DESC, score_id DESC
        OFFSET 3
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_old_scores
AFTER INSERT ON reform_scores
FOR EACH ROW 
EXECUTE FUNCTION keep_latest_3_reform_scores();

-- calculate news_articles(score_delta) using reform_scores(score)
/* How it works:
    1. insert article into news_articles
    2. insert new reform_scores row for a specific state (related to news in the article)
    3. insert category_reform scores row(s) for the state in question
    4. insert news_state_updates row linking article_id -> state -> new score_id
*/
 
CREATE OR REPLACE FUNCTION calc_score_delta()
RETURNS TRIGGER AS $$
DECLARE 
    new_score NUMERIC(5,2);
    old_score NUMERIC(5,2);
BEGIN
    -- get new score created by article
    SELECT score
    INTO new_score
    FROM reform_scores
    WHERE state_id = NEW.state_id AND score_id = NEW.score_id;

    -- get old score (most recent one in reform_scores)
    SELECT score
    INTO old_score
    FROM reform_scores
    WHERE state_id = NEW.state_id
        AND score_id <> NEW.score_id
        AND scored_at < (
            SELECT scored_at
            FROM reform_scores
            WHERE score_id = NEW.score_id
        )
    ORDER BY scored_at DESC, score_id DESC
    LIMIT 1;

    -- if no prev score exists delta = new_score
    IF old_score IS NULL THEN
        NEW.score_delta := new_score;
    ELSE
        NEW.score_delta := new_score - old_score;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER fill_score_delta
BEFORE INSERT OR UPDATE ON news_state_updates
FOR EACH ROW
EXECUTE FUNCTION calc_score_delta();

