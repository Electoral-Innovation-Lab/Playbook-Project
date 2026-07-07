"""
    CLEAN THE RAW DATA. TRANSFORM INTO clean_state_scores.csv
    Script to clean the downloaded csv file. 
    This will create a new modified csv file, leaving the raw one untouched. 
    with data before loading into db via load.sql

"""
    
# TO DO
# 1. empty cells become NA
# 2. remove special characters are gone ($ and ,)
# 3. ignore first 3 rows (category, variable, +/-)
# 4. make schema match new updates in the data - done
# 5. structure: final result should look like top row has var names and state
# 6. make separate df to track variables and corresponding categories

import pandas as pd
import numpy as np

raw_path = "db/data/state_stress_test - raw.csv"
pd.set_option("future.no_silent_downcasting", True)

# 6. get df of category titles and vars
raw_headers = pd.read_csv(raw_path, header=None, nrows=2)

categories = raw_headers.iloc[0].ffill()
variables = raw_headers.iloc[1]

df_categories = pd.DataFrame({
    "variable": variables,
    "category": categories
})
    # rename state and electoral college and match to category
df_categories.loc[0, "variable"] = "state"
df_categories.loc[0, "category"] = "state"
df_categories.loc[1, "variable"] = "electoral_college_votes"
df_categories.loc[1, "category"] = "Electoral College"

# Clean main data
# 3. and 5. clean up column row structure, rename where necessary and drop empty cols and rows
df = pd.read_csv(raw_path, header = 1)
df = df.drop(df.index[0])
df.columns.values[0] = "state"
df.columns.values[1] = "electoral_college_votes"

# 1. empty cells become NA and 2. remove special characters
df = df.replace({
    r"^\s*$": np.nan,
    r"\$": "",
    ",": ""
}, regex=True)

 # write changes to clean csv 
df.to_csv("db/data/clean_state_scores.csv", index=False)
df_categories.to_csv("db/data/var_categories.csv", index=False)


