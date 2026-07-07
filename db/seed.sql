BEGIN;

----------------------------------------------------
-- ACTION_PATHWAYS
----------------------------------------------------

INSERT INTO action_pathways
(state_id, category_id, title, path_description, path_status)
VALUES
(
    (SELECT state_id FROM states WHERE state_name = 'Texas'),
    (SELECT category_id FROM reform_categories
        WHERE category = 'Campaign Finance'),
    'Strengthen Campaign Finance Transparency',
    'Require more frequent disclosure of campaign contributions and independent expenditures.',
    'active'
),
(
    (SELECT state_id FROM states WHERE state_name = 'Wisconsin'),
    (SELECT category_id FROM reform_categories
        WHERE category = 'Fair Representation'),
    'Create Independent Redistricting Commission',
    'Establish a bipartisan commission responsible for congressional and legislative redistricting.',
    'pending'
);

----------------------------------------------------
-- NEWS_ARTICLES
----------------------------------------------------

INSERT INTO news_articles
(headline, summary, source_name, source_url, published_at, is_national)
VALUES
(
    'State Legislature Considers Voting Reform Package',
    'Lawmakers introduced legislation expanding early voting and voter registration opportunities.',
    'Associated Press',
    'https://apnews.com/example1',
    NOW() - INTERVAL '5 days',
    FALSE
),
(
    'Election Officials Announce New Security Measures',
    'Election administrators announced updated cybersecurity protocols ahead of the next election.',
    'Reuters',
    'https://reuters.com/example2',
    NOW() - INTERVAL '2 days',
    TRUE
);

----------------------------------------------------
-- NEWS_STATE_UPDATES
----------------------------------------------------

INSERT INTO news_state_updates
(article_id, state_id, score_id, score_delta)
VALUES
(
    (SELECT article_id
        FROM news_articles
        WHERE headline = 'State Legislature Considers Voting Reform Package'),
    (SELECT state_id
        FROM states
        WHERE state_name = 'Texas'),
    (
        SELECT score_id
        FROM reform_scores rs
        JOIN states s
            ON rs.state_id = s.state_id
        WHERE s.state_name = 'Texas'
        ORDER BY scored_at DESC
        LIMIT 1
    ),
    2
),
(
    (SELECT article_id
        FROM news_articles
        WHERE headline = 'Election Officials Announce New Security Measures'),
    (SELECT state_id
        FROM states
        WHERE state_name = 'Wisconsin'),
    (
        SELECT score_id
        FROM reform_scores rs
        JOIN states s
            ON rs.state_id = s.state_id
        WHERE s.state_name = 'Wisconsin'
        ORDER BY scored_at DESC
        LIMIT 1
    ),
    1
);

COMMIT;