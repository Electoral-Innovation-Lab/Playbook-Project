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
# 4. make schema match new updates in the data
# 5. structure: final result should look like top row has var names and state

import pandas as pd

# 5. clean up column row structure, rename where necessary and drop empty cols and rows
df = pd.read_csv("db/data/state_stress_test - raw.csv", header = 1)
df = df.drop(df.index[0])
df.columns.values[0] = "state"
df.columns.values[1] = "electoral_college_votes"

df.to_csv("db/data/clean_state_scores.csv", index=False)

