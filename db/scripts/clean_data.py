"""
    CLEAN THE RAW DATA. TRANSFORM INTO clean_state_scores.csv
    Script to clean the downloaded csv file. 
    This will create a new modified csv file, leaving the raw one untouched. 
    with data before loading into db via load.sql

"""
    
# TO DO
# 1. empty cells become NA
# 3. ignore first 3 rows (category, variable, +/-)
# 4. make schema match new updates in the data - done
# 5. structure: final result should look like top row has var names and state
# 6. make separate df to track variables and corresponding categories
# 7. calc reform score (temporarily do simple average until policy research gives direction)

import pandas as pd
import numpy as np

raw_path = "db/data/state_stress_test - normalization.csv"
pd.set_option("future.no_silent_downcasting", True)

""" 
CREATE CSV OF VARS MATCHED TO CORRESPONDING CATEGORIES
var_categories.csv
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

""" CLEAN NORMALIZED CSV
        1. make clean_state_scores.csv -- states and corresponding var scores
        2. make reform_scores.csv -- states and reform score
        3. make 

"""

# clean up column row structure, rename where necessary and drop empty cols and rows
df = pd.read_csv(raw_path, header = 1)
df = df.drop(df.index[0])
df.columns.values[0] = "state"
df.columns.values[1] = "electoral_college_votes"

# empty cells become NA 
df = df.replace(r"^\s*$", pd.NA, regex=True)

# add reform score temp calculation
exclude_cols = ["state", "electoral_college_votes"]
score_cols = df.columns.difference(exclude_cols)
df[score_cols] = df[score_cols].apply(pd.to_numeric, errors="coerce")
df["reform_score"] = df[score_cols].mean(axis=1).round().astype("Int64")

# write changes to csv 
df.to_csv("db/data/clean_state_scores.csv", index=False)

# save separate csv for only reform_scores
df_reform_scores = df[["state", "reform_score"]]
df_reform_scores.to_csv("db/data/reform_scores.csv", index=False)

# save separate csv for variable values
df_values = df.melt(
    id_vars=["state"],
    value_vars = score_cols,
    var_name="variable",
    value_name="value"
)
df_values.to_csv("db/data/category_variable_values.csv", index=False)

# save separate csv for electoral votes
df_votes = df[["state", "electoral_college_votes"]].copy()
df_votes["electoral_college_votes"] = df_votes["electoral_college_votes"].astype(int)
df_votes.to_csv("db/data/electoral_votes.csv", index=False)
