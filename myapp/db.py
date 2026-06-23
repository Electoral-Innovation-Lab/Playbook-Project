"""Database connection helper. Shared by all blueprints.

Reads DATABASE_URL from the environment (loaded from .env in development).
Uses psycopg 3. Each call opens a short-lived connection; for a small app
this is perfectly fine. If you later need pooling, swap this one function.
"""
import os
import psycopg
from psycopg.rows import dict_row
from dotenv import load_dotenv

load_dotenv()


def get_connection():
    """Return a new database connection with dict-style rows.

    dict_row means query results come back as dictionaries
    ({'name': 'California', ...}) instead of tuples, which makes
    turning them into JSON straightforward.
    """
    return psycopg.connect(os.environ["DATABASE_URL"], row_factory=dict_row)
