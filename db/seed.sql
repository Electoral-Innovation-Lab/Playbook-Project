BEGIN;
----------------------------------------------------
-- temporarily insert grades into REFORM_SCORES until that is calculated 
----------------------------------------------------
--UPDATE reform_scores
--SET grade = 'A';

----------------------------------------------------
-- ACTION_PATHWAYS
----------------------------------------------------

INSERT INTO action_pathways
(state_id, category_id, title, path_description, path_status, started_at)
VALUES
(
    (SELECT state_id FROM states WHERE state_name = 'Texas'),
    (SELECT category_id FROM reform_categories WHERE category = 'Campaign Finance'),
    'Strengthen Campaign Finance Transparency',
    'Require clearer disclosure of campaign contributions and independent expenditures.',
    'active',
    CURRENT_DATE - INTERVAL '30 days'
),
(
    (SELECT state_id FROM states WHERE state_name = 'Wisconsin'),
    (SELECT category_id FROM reform_categories WHERE category = 'Fair Representation'),
    'Create Independent Redistricting Commission',
    'Establish an independent process for drawing congressional and legislative districts.',
    'pending',
    CURRENT_DATE - INTERVAL '15 days'
);

----------------------------------------------------
-- NEWS_ARTICLES
----------------------------------------------------

INSERT INTO news_articles
(headline, summary, source_name, source_url, published_at, is_national)
VALUES
(
    'Texas Lawmakers Consider Campaign Finance Disclosure Bill',
    'A proposed bill would expand transparency requirements for state campaign spending.',
    'Sample News',
    'https://example.com/texas-campaign-finance-disclosure',
    NOW() - INTERVAL '5 days',
    FALSE
),
(
    'Wisconsin Reform Groups Renew Redistricting Push',
    'Advocacy groups are calling for an independent redistricting process before the next map cycle.',
    'Sample News',
    'https://example.com/wisconsin-redistricting-reform',
    NOW() - INTERVAL '2 days',
    FALSE
);

----------------------------------------------------
-- NEWS_STATE_UPDATES
-- Do not insert score_delta manually.
-- Your trigger calc_score_delta() fills it automatically.
----------------------------------------------------

INSERT INTO news_state_updates
(article_id, state_id, score_id)
VALUES
(
    (SELECT article_id
     FROM news_articles
     WHERE source_url = 'https://example.com/texas-campaign-finance-disclosure'),

    (SELECT state_id
     FROM states
     WHERE state_name = 'Texas'),

    (SELECT rs.score_id
     FROM reform_scores rs
     JOIN states s ON rs.state_id = s.state_id
     WHERE s.state_name = 'Texas'
     ORDER BY rs.scored_at DESC, rs.score_id DESC
     LIMIT 1)
),
(
    (SELECT article_id
     FROM news_articles
     WHERE source_url = 'https://example.com/wisconsin-redistricting-reform'),

    (SELECT state_id
     FROM states
     WHERE state_name = 'Wisconsin'),

    (SELECT rs.score_id
     FROM reform_scores rs
     JOIN states s ON rs.state_id = s.state_id
     WHERE s.state_name = 'Wisconsin'
     ORDER BY rs.scored_at DESC, rs.score_id DESC
     LIMIT 1)
);

COMMIT;