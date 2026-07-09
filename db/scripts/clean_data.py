"""
    CLEAN THE RAW DATA. 
    Script to clean the downloaded csv file. 
    This will create a new modified csv file, leaving the raw one untouched. 
    with data before loading into db via load.sql

"""

import pandas as pd
import numpy as np


""" CLEAN NORMALIZED CSV
        1. make category_variable_values.csv -- states and corresponding var scores
        2. make var_categories.csv -- match vars to categories
        3. make electoral_votes.csv -- match states to electoral vote count
"""
raw_path = "db/data/state_stress_test - normalization.csv"
pd.set_option("future.no_silent_downcasting", True)

"""
    1: MAKE CATEGORY_VARIABLE_VALUES.CSV
"""
# clean up column row structure, rename where necessary and drop empty cols and rows
df = pd.read_csv(raw_path, header = 1)
df = df.drop(df.index[0])
df.columns.values[0] = "state"
df.columns.values[1] = "electoral_college_votes"

# empty cells become NA 
df = df.replace(r"^\s*$", pd.NA, regex=True)

# remove columns with category score and electoral votes
df_clean_scores = df.drop(columns = ["electoral_college_votes","EP_SCORE", "FR_SCORE",  "PA_SCORE", "CF_SCORE", "CS_SCORE", "PIF_SCORE", "D_SCORE"])
# pivot the df and write to csv
df_clean_scores = df_clean_scores.melt(
                                id_vars=["state"],
                                value_vars = df_clean_scores.columns.difference(["state"]),
                                var_name = "variable",
                                value_name = "value"
                                )
df_clean_scores["var_value"] = pd.to_numeric(df_clean_scores["value"], errors="coerce")
df_clean_scores["no_score_reason"] = np.where(
    df_clean_scores["var_value"].isna() & df_clean_scores["value"].notna(),
    df_clean_scores["value"],
    np.nan
)
df_clean_scores = df_clean_scores[["state", "variable", "var_value", "no_score_reason"]]
df_clean_scores.to_csv("db/data/category_variable_values.csv", index=False)


""" 
    2. MAKE VAR_CATEGORIES.CSV
"""
raw_headers = pd.read_csv(raw_path, header=None, nrows=2)
categories = raw_headers.iloc[0].ffill()
variables = raw_headers.iloc[1]

df_categories = pd.DataFrame({
    "variable": variables,
    "category": categories
})
# remove unwanted score columns
df_categories = df_categories[
    ~df_categories["variable"].isin([
        "Electoral College",
        "EP_SCORE",
        "FR_SCORE",
        "PA_SCORE",
        "CF_SCORE",
        "CS_SCORE",
        "PIF_SCORE",
        "D_SCORE"
    ])
].reset_index(drop=True)
df_categories = df_categories.dropna(subset=["variable"]).reset_index(drop=True)

# write changes to csv
df_categories.to_csv("db/data/var_categories.csv", index=False)

"""
    3. MAKE ELECTORAL_VOTES.CSV
"""
df_electoral_votes = df[['state', 'electoral_college_votes']].copy()
df_electoral_votes['electoral_college_votes'] = df_electoral_votes['electoral_college_votes'].astype(int)
df_electoral_votes.to_csv("db/data/electoral_votes.csv", index=False)

"""
CLEAN FINAL_SCORE CSV
    1. make reform_scores.csv -- states and reform score
    2. make category_scores.csv - states and category score breakdown

"""
final_score_raw_path = "db/data/state_stress_test - final_score.csv"

"""
    1: MAKE REFORM_SCORES.CSV
"""
df_scores = pd.read_csv(final_score_raw_path, header = 0)
df_reform_scores = df_scores[['State', 'score_weightEqual']] #keep state and score_weightEqual
df_reform_scores.to_csv("db/data/reform_scores.csv", index=False)

"""
    2. MAKE CATEGORY_SCORES.CSV
"""
df_cat_scores = df_scores.drop(columns = ['score_weightByVars', 'score_weightEqual'])
df_cat_scores = df_cat_scores.replace(r'^\s*$', np.nan, regex=True)
df_cat_scores = df_cat_scores.melt(
                                id_vars=["State"],
                                value_vars = df_cat_scores.columns.difference(["State"]),
                                var_name = "category",
                                value_name = "value"
                                )

df_cat_scores.to_csv("db/data/category_scores.csv", index=False)

