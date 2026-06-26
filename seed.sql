-- SEED DATA — illustrative sample rows so the app renders against real data.
-- Run after schema.sql:  psql democracy < seed.sql
-- Safe to re-run after a fresh schema load; not idempotent on its own.

-- 1) States
INSERT INTO states (name, abbreviation) VALUES
    ('California',    'CA'),
    ('Texas',         'TX'),
    ('New York',      'NY'),
    ('Florida',       'FL'),
    ('Pennsylvania',  'PA'),
    ('Wisconsin',     'WI'),
    ('Georgia',       'GA'),
    ('Arizona',       'AZ');

-- 2) Reform categories
INSERT INTO reform_categories (category, description, weight) VALUES
    ('Voter Access',          'Ease of registration and casting a ballot.',          1.5),
    ('Map Fairness',          'Independence and fairness of district map-drawing.',   1.5),
    ('Finance Transparency',  'Disclosure and limits on campaign money.',             1.0),
    ('Election Security',     'Integrity and auditability of results.',               1.0),
    ('Participation',         'Turnout and civic engagement.',                        1.0);

-- 3) Baseline composite scores
INSERT INTO reform_scores (state_id, scored_at, score, grade)
SELECT s.state_id, NOW() - INTERVAL '30 days', v.score, v.grade
FROM states s
JOIN (VALUES
    ('CA', 82.5, 'B+'),
    ('TX', 54.0, 'C-'),
    ('NY', 71.0, 'B-'),
    ('FL', 49.5, 'D+'),
    ('PA', 63.0, 'C+'),
    ('WI', 58.0, 'C'),
    ('GA', 52.5, 'C-'),
    ('AZ', 66.0, 'C+')
) AS v(abbr, score, grade)
ON s.abbreviation = v.abbr;

-- 4) Category scores for California baseline
INSERT INTO category_scores (score_id, category_id, score, notes)
SELECT rs.score_id, rc.category_id, v.score, v.notes
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id
JOIN (VALUES
    ('Voter Access',         88.0, 'Automatic and same-day registration.'),
    ('Map Fairness',         90.0, 'Independent citizen redistricting commission.'),
    ('Finance Transparency', 70.0, 'Strong disclosure, moderate limits.')
) AS v(category, score, notes) ON TRUE
JOIN reform_categories rc ON rc.category = v.category
WHERE s.abbreviation = 'CA';

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

-- 6) News articles
INSERT INTO news_articles
    (headline, summary, source_name, source_url, published_at, is_national)
VALUES
    (
        'Wisconsin court orders new legislative maps',
        'Ruling requires redrawn districts before the next cycle.',
        'Sample Wire',
        'https://example.com/wisconsin-new-maps',
        NOW() - INTERVAL '2 days',
        FALSE
    ),
    (
        'Arizona extends early-voting access',
        'New law adds weekend early-voting days statewide.',
        'Sample Wire',
        'https://example.com/arizona-early-voting',
        NOW() - INTERVAL '5 days',
        FALSE
    ),
    (
        'Federal disclosure rule takes effect',
        'New nationwide campaign-finance disclosure requirements begin.',
        'Sample Wire',
        'https://example.com/federal-disclosure-rule',
        NOW() - INTERVAL '1 day',
        TRUE
    );

-- 7) New reform scores caused by state-specific news articles
INSERT INTO reform_scores (state_id, scored_at, score, grade)
SELECT s.state_id, NOW() - INTERVAL '2 days', 62.0, 'C+'
FROM states s
WHERE s.abbreviation = 'WI';

INSERT INTO reform_scores (state_id, scored_at, score, grade)
SELECT s.state_id, NOW() - INTERVAL '5 days', 68.5, 'B-'
FROM states s
WHERE s.abbreviation = 'AZ';

-- 8) Category scores for the new Wisconsin score
INSERT INTO category_scores (score_id, category_id, score, notes)
SELECT rs.score_id, rc.category_id, 64.0,
       'Court-ordered map changes improve map fairness outlook.'
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id
JOIN reform_categories rc ON rc.category = 'Map Fairness'
WHERE s.abbreviation = 'WI'
ORDER BY rs.scored_at DESC
LIMIT 1;

-- 9) Category scores for the new Arizona score
INSERT INTO category_scores (score_id, category_id, score, notes)
SELECT rs.score_id, rc.category_id, 76.0,
       'Weekend early-voting expansion improves access.'
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id
JOIN reform_categories rc ON rc.category = 'Voter Access'
WHERE s.abbreviation = 'AZ'
ORDER BY rs.scored_at DESC
LIMIT 1;

-- 10) Link state-specific news articles to the new scores.
-- score_delta is calculated automatically by trigger calc_score_delta().
INSERT INTO news_state_updates (article_id, state_id, score_id)
SELECT na.article_id, s.state_id, rs.score_id
FROM news_articles na
JOIN states s ON s.abbreviation = 'WI'
JOIN reform_scores rs ON rs.state_id = s.state_id
WHERE na.source_url = 'https://example.com/wisconsin-new-maps'
ORDER BY rs.scored_at DESC
LIMIT 1;

INSERT INTO news_state_updates (article_id, state_id, score_id)
SELECT na.article_id, s.state_id, rs.score_id
FROM news_articles na
JOIN states s ON s.abbreviation = 'AZ'
JOIN reform_scores rs ON rs.state_id = s.state_id
WHERE na.source_url = 'https://example.com/arizona-early-voting'
ORDER BY rs.scored_at DESC
LIMIT 1;