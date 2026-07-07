-- WRAP LOAD.SQL IN ONE TRANSACTION
BEGIN;

CREATE TEMP TABLE staging_abbrevs (
    state_name text,
    abbreviation text
);
CREATE TEMP TABLE staging_electoral_votes (
    state_name text,
    electoral_votes integer
);
CREATE TEMP TABLE staging_cats (
    variable text,
    category text
);
CREATE TEMP TABLE staging_reform_scores (
    state text,
    reform_score NUMERIC(5,3)
);
CREATE TEMP TABLE staging_category_scores (
    state text,
    electoral_participation NUMERIC(5,3),
    fair_representation NUMERIC(5,3),
    political_accountability NUMERIC(5,3),
    campaign_finance NUMERIC(5,3),
    civil_society NUMERIC(5,3),
    political_and_institutional_factors NUMERIC(5,3),
    demographics NUMERIC(5,3)
);

\COPY staging_abbrevs FROM 'db/data/state-abbrevs.csv' WITH (FORMAT csv, HEADER true, NULL '');
\COPY staging_electoral_votes FROM 'db/data/electoral_votes.csv' WITH (FORMAT csv, HEADER true, NULL '');
\COPY staging_cats FROM 'db/data/var_categories.csv' WITH (FORMAT csv, HEADER true);
\COPY staging_reform_scores FROM 'db/data/reform_scores.csv' WITH (FORMAT csv, HEADER true, NULL '');
\COPY staging_category_scores FROM 'db/data/category_scores.csv' WITH (FORMAT csv, HEADER true, NULL '');

/*STATES relation 
        id auto generated.
        csv supplies name, abbrev. 
        another csv provides electoral votes
*/
INSERT INTO states(state_name, abbreviation, electoral_votes)
SELECT 
    a.state_name,
    a.abbreviation,
    b.electoral_votes
FROM staging_abbrevs a 
JOIN staging_electoral_votes b ON a.state_name = b.state_name;

/* REFORM_CATEGORIES relation
    category_id
    category
    cat_description
    cat_weight
*/
INSERT INTO reform_categories(category)
SELECT DISTINCT category
FROM staging_cats
WHERE category IS NOT NULL
ORDER BY category;

/* REFORM_CATEGORY_VARIABLES relation
    var_id
    var_name
    var_description
    category_id
*/
INSERT INTO reform_category_variables(var_name, category_id)
SELECT
    x.variable,
    y.category_id
FROM staging_cats x
JOIN reform_categories y ON x.category = y.category;


/* REFORM_SCORES relation
    score_id
    state_id
    scored_at
    score - from clean_state_scores.csv
    grade
*/
INSERT INTO reform_scores(state_id, scored_at, score)
SELECT 
    x.state_id,
    NOW(), 
    y.score_weightEqual
FROM states x
JOIN staging_reform_scores y ON x.state_name = y.State;
    
/* CATEGORY_SCORES relation
    cat_score_id
    score_id (from reform_scores)
    category_id (from reform cats)
    score
    notes
*/
INSERT INTO category_scores(score_id, category_id, score)
SELECT
    x.score_id,
    y.category_id,
    z.score
FROM staging_category_scores cs
JOIN states s ON states.state_name = cs.state
JOIN reform_scores x ON x.state_id = s.state_id
CROSS JOIN LATERAL (
    VALUES
        ('Electoral Participation', cs.electoral_participation),
        ('Fair Representation', cs.fair_representation),
        ('Political Accountability', cs.political_accountability),
        ('Campaign Finance', cs.campaign_finance),
        ('Civil Society', cs.civil_society),
        ('Political and Institutional Factors', cs.political_and_institutional_factors),
        ('Demographics', cs.demographics)
) AS z(category,score)
JOIN reform_categories rc ON rc.category = z.category;


/* CATEGORY_VARIABLE_VALUES relation
    value_id 
    var_value (from csv)
    score_id (from reform_scores)
    var_id (from reform_cat_vars)
*/
INSERT INTO category_variable_values(var_value, score_id, var_id)
SELECT 
    x.value,
    y.score_id,
    z.var_id
FROM staging_var_values x 
JOIN states s ON x.state = s.state_name
JOIN reform_scores y ON s.state_id = y.state_id AND y.scored_at = NOW()
JOIN reform_category_variables z ON x.reform_variable  = z.var_name;

/* ACTION_PATHWAYS relation
    pathway_id  
    state_id   
    category_id 
    title      
    path_description
    path_status    
    started_at
    resolved_at
    created_at 
*/
-- empty for now until get data

/* NEWS_ARTICLES relation
    article_id  
    headline    
    summary 
    source_name  
    source_url   
    published_at 
    is_national       
    created_at
*/
-- empty for now until get data

/* NEWS_STATE_UPDATES relation
    article_id 
    state_id 
    score_id
    score_delta
*/
-- empty for now until get data

COMMIT;
