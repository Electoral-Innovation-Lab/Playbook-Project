-- SEED DATA — illustrative sample rows so the app renders against real data.
-- Run after schema.sql:  psql democracy < seed.sql
-- Safe to re-run after a fresh schema load; not idempotent on its own.

-- 1) A handful of states (expand to all 50 later)
INSERT INTO states (name, abbreviation) VALUES
    ('California',    'CA'),
    ('Texas',         'TX'),
    ('New York',      'NY'),
    ('Florida',       'FL'),
    ('Pennsylvania',  'PA'),
    ('Wisconsin',     'WI'),
    ('Georgia',       'GA'),
    ('Arizona',       'AZ');

-- 2) Reform categories (the composite-score dimensions)
INSERT INTO reform_categories (category, description, weight) VALUES
    ('Voter Access',          'Ease of registration and casting a ballot.',          1.5),
    ('Map Fairness',          'Independence and fairness of district map-drawing.',   1.5),
    ('Finance Transparency',  'Disclosure and limits on campaign money.',             1.0),
    ('Election Security',     'Integrity and auditability of results.',               1.0),
    ('Participation',         'Turnout and civic engagement.',                        1.0);

-- 3) One composite score per state (today's date)
INSERT INTO reform_scores (state_id, score, grade)
SELECT state_id, v.score, v.grade
FROM states
JOIN (VALUES
    ('CA', 82.5, 'B+'),
    ('TX', 54.0, 'C-'),
    ('NY', 71.0, 'B-'),
    ('FL', 49.5, 'D+'),
    ('PA', 63.0, 'C+'),
    ('WI', 58.0, 'C'),
    ('GA', 52.5, 'C-'),
    ('AZ', 66.0, 'C+')
) AS v(abbr, score, grade) ON states.abbreviation = v.abbr;

-- 4) A couple of per-category scores for California, as an example of the rollup
INSERT INTO category_scores (score_id, category_id, score, notes)
SELECT rs.score_id, rc.category_id, v.score, v.notes
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id AND s.abbreviation = 'CA'
JOIN (VALUES
    ('Voter Access',         88.0, 'Automatic and same-day registration.'),
    ('Map Fairness',         90.0, 'Independent citizen redistricting commission.'),
    ('Finance Transparency', 70.0, 'Strong disclosure, moderate limits.')
) AS v(category, score, notes) ON TRUE
JOIN reform_categories rc ON rc.category = v.category;

-- 5) Sample action pathways
INSERT INTO action_pathways (state_id, category_id, title, description, status, started_at)
SELECT s.state_id, rc.category_id, v.title, v.descr, v.status, CURRENT_DATE - 90
FROM (VALUES
    ('WI', 'Map Fairness', 'Independent redistricting commission',
        'Ballot initiative to remove map-drawing from the legislature.', 'pending'),
    ('AZ', 'Voter Access', 'Expand early voting hours',
        'Bill to standardize early-voting windows statewide.', 'active'),
    ('GA', 'Election Security', 'Risk-limiting audits',
        'Mandate statistical post-election audits for all federal races.', 'active')
) AS v(abbr, category, title, descr, status)
JOIN states s ON s.abbreviation = v.abbr
JOIN reform_categories rc ON rc.category = v.category;

-- 6) Sample news (one national, two state-specific)
INSERT INTO news_articles
    (state_id, category_id, headline, summary, source_name, published_at, score_delta)
SELECT s.state_id, rc.category_id, v.headline, v.summary, v.source, NOW() - (v.days_ago || ' days')::interval, v.delta
FROM (VALUES
    ('WI', 'Map Fairness', 'Wisconsin court orders new legislative maps',
        'Ruling requires redrawn districts before the next cycle.',
        'Sample Wire', 2, 4.0),
    ('AZ', 'Voter Access', 'Arizona extends early-voting access',
        'New law adds weekend early-voting days statewide.',
        'Sample Wire', 5, 2.5)
) AS v(abbr, category, headline, summary, source, days_ago, delta)
JOIN states s ON s.abbreviation = v.abbr
JOIN reform_categories rc ON rc.category = v.category;

-- A national story (no state_id)
INSERT INTO news_articles (state_id, category_id, headline, summary, source_name, published_at, score_delta)
VALUES (NULL, NULL,
    'Federal disclosure rule takes effect',
    'New nationwide campaign-finance disclosure requirements begin.',
    'Sample Wire', NOW() - INTERVAL '1 day', NULL);
