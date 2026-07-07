-- SEED DATA — illustrative sample rows so the app renders against real data.
-- Run after schema.sql:  psql democracy < seed.sql
-- Safe to re-run after a fresh schema load; not idempotent on its own.

-- 1) States
INSERT INTO states (state_name, abbreviation) VALUES
    ('California',    'CA'),
    ('Texas',         'TX'),
    ('New York',      'NY'),
    ('Florida',       'FL'),
    ('Pennsylvania',  'PA'),
    ('Wisconsin',     'WI'),
    ('Georgia',       'GA'),
    ('Arizona',       'AZ');

-- 2) Reform categories
INSERT INTO reform_categories (category, cat_description, cat_weight) VALUES
    ('Electoral Participation', 'Voting access, registration, turnout, and ballot participation.', 1.50),
    ('Fair Representation', 'District fairness, competitiveness, compactness, and split minimization.', 1.50),
    ('Political Accountability', 'Judicial selection, direct democracy, and institutional accountability.', 1.00),
    ('Campaign Finance', 'Lobbying influence, campaign finance transparency, and donation rules.', 1.00),
    ('Civil Society', 'Public civic engagement and civil society strength.', 1.00),
    ('Political and Institutional Factors', 'Partisan leaning, divided government, and institutional context.', 1.00);
-- 3) Reform category variables
INSERT INTO reform_category_variables (var_name, var_description, category_id)
SELECT v.var_name, v.var_description, rc.category_id
FROM (VALUES
    ('voter_turnout', 'Voter turnout level or index.', 'Electoral Participation'),
    ('voter_registration', 'Voter registration access or rate.', 'Electoral Participation'),

    ('partisan_fairness', 'Partisan fairness of district maps.', 'Fair Representation'),
    ('competitiveness', 'Electoral competitiveness.', 'Fair Representation'),
    ('compactness', 'District compactness.', 'Fair Representation'),
    ('count_splits', 'Number or severity of jurisdictional splits.', 'Fair Representation'),

    ('elected_supreme_justice', 'Whether supreme court justices are elected.', 'Political Accountability'),
    ('retention_election_justice', 'Whether justices face retention elections.', 'Political Accountability'),
    ('partisan_justice_election', 'Whether judicial elections are partisan.', 'Political Accountability'),
    ('court_curbing_bill', 'Presence or severity of court-curbing legislation.', 'Political Accountability'),
    ('statutory_initiative', 'Availability of statutory initiatives.', 'Political Accountability'),
    ('constitutional_initiative', 'Availability of constitutional initiatives.', 'Political Accountability'),
    ('popular_referendum', 'Availability of popular referendum.', 'Political Accountability'),

    ('lobbyist_money', 'Lobbyist money influence indicator.', 'Campaign Finance'),
    ('campaign_finance_index', 'Campaign finance strength or transparency index.', 'Campaign Finance'),

    ('partisan_leaning', 'State partisan leaning indicator.', 'Political and Institutional Factors'),
    ('divided_government', 'Whether state government is divided.', 'Political and Institutional Factors'),
    ('divided_legislatures', 'Whether legislative chambers are divided.', 'Political and Institutional Factors')
) AS v(var_name, var_description, category)
JOIN reform_categories rc ON rc.category = v.category;

-- 4) Baseline composite scores
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

-- 5) Category scores for California baseline
INSERT INTO category_scores (score_id, category_id, score, notes)
SELECT rs.score_id, rc.category_id, v.score, v.notes
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id
JOIN (VALUES
    ('Electoral Participation', 88.0, 'Strong registration and turnout environment.'),
    ('Fair Representation', 90.0, 'Independent redistricting strengthens map fairness.'),
    ('Campaign Finance', 70.0, 'Strong disclosure with moderate limits.')
) AS v(category, score, notes) ON TRUE
JOIN reform_categories rc ON rc.category = v.category
WHERE s.abbreviation = 'CA';

-- 6) Sample variable values for California baseline
INSERT INTO category_variable_values (var_value, score_id, var_id)
SELECT v.var_value, rs.score_id, rcv.var_id
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id
JOIN (VALUES
    ('voter_turnout', 0.8200),
    ('voter_registration', 0.8800),
    ('partisan_fairness', 0.9100),
    ('competitiveness', 0.7400),
    ('compactness', 0.8600),
    ('campaign_finance_index', 0.7000)
) AS v(var_name, var_value) ON TRUE
JOIN reform_category_variables rcv ON rcv.var_name = v.var_name
WHERE s.abbreviation = 'CA'
ORDER BY rs.scored_at DESC
LIMIT 6;

-- 7) Sample action pathways
INSERT INTO action_pathways (state_id, category_id, title, path_description, path_status, started_at)
SELECT s.state_id, rc.category_id, v.title, v.descr, v.path_status, CURRENT_DATE - 90
FROM (VALUES
    ('WI', 'Fair Representation', 'Independent redistricting commission',
        'Ballot initiative to remove map-drawing from the legislature.', 'pending'),
    ('AZ', 'Electoral Participation', 'Expand early voting hours',
        'Bill to standardize early-voting windows statewide.', 'active'),
    ('GA', 'Political Accountability', 'Risk-limiting audits',
        'Mandate statistical post-election audits for all federal races.', 'active')
) AS v(abbr, category, title, descr, path_status)
JOIN states s ON s.abbreviation = v.abbr
JOIN reform_categories rc ON rc.category = v.category;

-- 8) News articles
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

-- 9) New reform scores caused by state-specific news articles
INSERT INTO reform_scores (state_id, scored_at, score, grade)
SELECT s.state_id, NOW() - INTERVAL '2 days', 62.0, 'C+'
FROM states s
WHERE s.abbreviation = 'WI';

INSERT INTO reform_scores (state_id, scored_at, score, grade)
SELECT s.state_id, NOW() - INTERVAL '5 days', 68.5, 'B-'
FROM states s
WHERE s.abbreviation = 'AZ';

-- 10) Category scores for the new Wisconsin score
INSERT INTO category_scores (score_id, category_id, score, notes)
SELECT rs.score_id, rc.category_id, 64.0,
       'Court-ordered map changes improve fair representation outlook.'
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id
JOIN reform_categories rc ON rc.category = 'Fair Representation'
WHERE s.abbreviation = 'WI'
ORDER BY rs.scored_at DESC
LIMIT 1;

-- 11) Category scores for the new Arizona score
INSERT INTO category_scores (score_id, category_id, score, notes)
SELECT rs.score_id, rc.category_id, 76.0,
       'Weekend early-voting expansion improves electoral participation.'
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id
JOIN reform_categories rc ON rc.category = 'Electoral Participation'
WHERE s.abbreviation = 'AZ'
ORDER BY rs.scored_at DESC
LIMIT 1;

-- 12) Variable values for new Wisconsin score
INSERT INTO category_variable_values (var_value, score_id, var_id)
SELECT v.var_value, rs.score_id, rcv.var_id
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id
JOIN (VALUES
    ('partisan_fairness', 0.6400),
    ('competitiveness', 0.6100),
    ('compactness', 0.5900),
    ('count_splits', 0.5200)
) AS v(var_name, var_value) ON TRUE
JOIN reform_category_variables rcv ON rcv.var_name = v.var_name
WHERE s.abbreviation = 'WI'
ORDER BY rs.scored_at DESC
LIMIT 4;

-- 13) Variable values for new Arizona score
INSERT INTO category_variable_values (var_value, score_id, var_id)
SELECT v.var_value, rs.score_id, rcv.var_id
FROM reform_scores rs
JOIN states s ON s.state_id = rs.state_id
JOIN (VALUES
    ('voter_turnout', 0.6900),
    ('voter_registration', 0.7600)
) AS v(var_name, var_value) ON TRUE
JOIN reform_category_variables rcv ON rcv.var_name = v.var_name
WHERE s.abbreviation = 'AZ'
ORDER BY rs.scored_at DESC
LIMIT 2;

-- 14) Link state-specific news articles to the new scores.
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