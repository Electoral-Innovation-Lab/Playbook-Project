"""
Loads clean_state_scores.csv into the database.

Inserts all 50 states and their raw variable values.
Scores are left NULL — they will be computed separately once
the team defines the scoring methodology.

Run from the project root:
    python db/scripts/load_data.py

Skips states that already have an entry in reform_scores.
"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from dotenv import load_dotenv
load_dotenv()

from myapp import create_app
from myapp.models.state import ALL_STATES

DATA_PATH = Path(__file__).parent.parent / "data" / "clean_state_scores.csv"

NAME_TO_ABBR = {name: abbr for abbr, name in ALL_STATES.items()}

# CSV column → DB var_name
# Includes fallbacks for renamed variables between schema versions
CSV_TO_VARNAME = {
    'voter_turnout':                  'voter_turnout',
    'voter_registration':             'voter_registration',
    'partisan_fairness':              'partisan_fairness',
    'competitiveness':                'competitiveness',
    'compactness':                    'compactness',
    'county_split':                   'county_split',
    'per_county_split':               'per_county_split',
    'num_county':                     'num_county',
    'elected_supreme_justice':        'elected_supreme_justice',
    'retention_election_justice':     'retention_election_justice',
    'partisan_justice_election':      'partisan_justice_election',
    'court_curbing_bill':             'court_curbing_bill',
    'statutory_initiative':           'statutory_initiative',
    'constitutional_initiative':      'constitutional_initiative',
    'popular_referendum':             'popular_referendum',
    'congressional_money':            'congressional_money',
    'legislative_money':              'legislative_money',
    'congressional_money_percapita':  'congressional_money_percapita',
    'legislative_money_percapita':    'legislative_money_percapita',
    'lobbyist_money':                 'lobbyist_money',
    'campaign_finance_index':         'campaign_finance_index',
    'protest_index':                  'protest_index',
    'local_news':                     'local_news',
    'free_speech':                    'free_speech',
    'press_incidents':                'press_incidents',
    'democratic_leaning':             'democratic_leaning',
    'divided_government':             'divided_government',
    'divided_legislatures':           'divided_legislatures',
    'bachelor_share':                 'bachelor_share',
    'minority_share':                 'minority_share',
}

# Fallbacks for renamed vars between schema versions
VARNAME_FALLBACKS = {
    'county_split':      'count_splits',
    'democratic_leaning': 'partisan_leaning',
}


def main():
    app = create_app()
    with app.app_context():
        db = app.db

        df = pd.read_csv(DATA_PATH)
        for col in df.columns:
            if col != 'state':
                df[col] = pd.to_numeric(df[col], errors='coerce')
        df = df.reset_index(drop=True)

        # Fetch var_ids from whatever variables exist in this DB
        var_rows = db.execute("SELECT var_id, var_name FROM reform_category_variables")
        db_vars  = {r.var_name: r.var_id for r in var_rows}
        print(f"DB has {len(db_vars)} variables")

        col_to_var_id = {}
        for csv_col, primary_name in CSV_TO_VARNAME.items():
            if csv_col not in df.columns:
                continue
            if primary_name in db_vars:
                col_to_var_id[csv_col] = db_vars[primary_name]
            elif csv_col in VARNAME_FALLBACKS and VARNAME_FALLBACKS[csv_col] in db_vars:
                col_to_var_id[csv_col] = db_vars[VARNAME_FALLBACKS[csv_col]]
        print(f"Mapped {len(col_to_var_id)} CSV columns to DB vars\n")

        inserted = 0
        skipped  = 0

        for idx in range(len(df)):
            row        = df.iloc[idx]
            state_name = str(row['state']).strip()
            abbr       = NAME_TO_ABBR.get(state_name)
            if not abbr:
                print(f"  Unknown state: {state_name!r} — skipping")
                continue

            # Insert state if not already there
            existing = db.execute(
                "SELECT state_id FROM states WHERE abbreviation = :a", a=abbr
            )
            if existing:
                state_id = existing[0].state_id
            else:
                r = db.execute(
                    "INSERT INTO states (name, abbreviation) VALUES (:n, :a) RETURNING state_id",
                    n=state_name, a=abbr
                )
                state_id = r[0].state_id

            # Skip if already loaded
            if db.execute(
                "SELECT 1 FROM reform_scores WHERE state_id = :s LIMIT 1", s=state_id
            ):
                skipped += 1
                continue

            # Placeholder score row — score/grade left NULL until scoring is defined
            rs = db.execute(
                "INSERT INTO reform_scores (state_id) VALUES (:s) RETURNING score_id",
                s=state_id
            )
            score_id = rs[0].score_id

            # Insert raw variable values
            for csv_col, var_id in col_to_var_id.items():
                raw = row[csv_col]
                if pd.isna(raw):
                    continue
                db.execute(
                    "INSERT INTO category_variable_values (value, score_id, var_id)"
                    " VALUES (:v, :s, :vi)",
                    v=float(raw), s=score_id, vi=var_id
                )

            print(f"  {abbr}  {state_name}")
            inserted += 1

        print(f"\nDone — inserted {inserted} states, skipped {skipped}.")
        print("Scores are NULL. Run the scoring script once the methodology is defined.")


if __name__ == "__main__":
    main()
