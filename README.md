# Democracy Reform — Backend Starter

A minimal, verified Flask + PostgreSQL backend for the Democracy Reform project.
No Alembic, no Pydantic — just the essentials, built so two people can work
independently. Every endpoint here has been tested against a live database.

## What's inside

```
Playbook-Project/
├── create.sql            # database structure — the single source of truth
├── seed.sql              # sample data so the app renders against real rows
├── run.py                # local dev entry point (python run.py)
├── requirements.txt      # dependencies
├── .env.example          # template for secrets — COPY to .env, never commit .env
├── .gitignore            # keeps .env and junk out of Git
└── myapp/
    ├── __init__.py       # app factory — registers both blueprints   [SHARED]
    ├── db.py             # database connection helper                [SHARED]
    ├── public/
    │   └── routes.py     # states + scores endpoints           [DEVELOPER 1]
    └── content/
        └── routes.py     # pathways + news endpoints           [DEVELOPER 2]
```

## Ownership split (how you work separately)

- **Developer 1 owns `myapp/public/`** — the states, scores, and category data
  behind the map and the 50-state comparison table.
- **Developer 2 owns `myapp/content/`** — the action pathways and the news feed.

You each work almost entirely inside your own folder, so you rarely touch the
same file and merge conflicts stay rare. `__init__.py`, `db.py`, `schema.sql`,
and `seed.sql` are shared — change those together and tell each other.

## One-time setup (each person, on their own machine)

1. **Install PostgreSQL** (Postgres.app on Mac, the installer on Windows, or
   `apt install postgresql` on Linux) and make sure `psql` works.

2. **Clone the repo and enter it:**
   ```bash
   git clone <your-repo-url>
   cd Playbook-Project
   ```

3. **Create a Python virtual environment and install dependencies:**
   ```bash
   python -m venv venv
   source venv/bin/activate        # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

4. **Create your local database and load schema + seed:**
   ```bash
   createdb playbook
   psql playbook < create.sql (or psql playbook -e -f create.sql)
   psql playbook < seed.sql
   ```

5. **Create your own `.env`** (this holds YOUR local secrets; it is never committed):
   ```bash
   cp .env.example .env
   ```
   Then edit `.env` and set `DATABASE_URL` to your local connection string, e.g.:
   ```
   DATABASE_URL=postgresql+psycopg://milishah@localhost:5432/playbook
   ```
   Generate a SECRET_KEY with:
   `python -c "import secrets; print(secrets.token_hex(32))"`

## Running locally

```bash
source venv/bin/activate
python run.py
```

Open http://localhost:5000/api/health — you should see `{"status": "ok"}`.

Try the data endpoints:
- http://localhost:5000/api/states
- http://localhost:5000/api/states/CA
- http://localhost:5000/api/pathways
- http://localhost:5000/api/news

`debug=True` auto-reloads when you save a file — just refresh the browser.
You and your collaborator each run this independently against your own local
database. Nobody's local work affects the other until code is merged in Git.

## Endpoints

| Method | Path                  | Owner | Returns                                   |
|--------|-----------------------|-------|-------------------------------------------|
| GET    | /api/health           | both  | health check                              |
| GET    | /api/states           | Dev 1 | all states + latest composite score       |
| GET    | /api/states/<abbr>    | Dev 1 | one state's profile + category breakdown  |
| GET    | /api/pathways         | Dev 2 | reform pathways (optional ?state=CA)      |
| GET    | /api/news             | Dev 2 | news feed, newest first (optional ?limit) |

## Git workflow

`main` is always the working version. Don't commit directly to it.

```bash
git checkout -b my-feature      # branch off for your work
# ... edit files in YOUR folder ...
git add .
git commit -m "Add state detail endpoint"
git push origin my-feature
# open a pull request on GitHub; the other person reviews, then merge into main
```

## Connecting the front-end

Your existing Netlify prototype currently has sample data baked into its
JavaScript. Replace those hardcoded values with `fetch()` calls to these
endpoints, e.g. `fetch("https://your-api-url/api/states")`. During local
development that URL is `http://localhost:5000`.

## Deploying (when you're ready)

Netlify can't run Flask. Use a host that runs Python + Postgres — Render,
Railway, or Fly.io. General steps (Render shown):

1. Push your repo to GitHub.
2. On Render, create a **PostgreSQL** instance; copy its connection URL.
3. Load your schema into it once: `psql <render-db-url> < schema.sql`
   (and `seed.sql` if you want sample data there too).
4. Create a **Web Service** from your GitHub repo with:
   - Build command: `pip install -r requirements.txt`
   - Start command: `gunicorn "myapp:create_app()"`
5. In the service's **Environment** settings, add `DATABASE_URL` (the Render DB
   URL) and `SECRET_KEY`. Do NOT upload your `.env` — set these in the dashboard.
6. Every push to `main` auto-redeploys. You now have three databases with the
   same schema: yours (local), your collaborator's (local), and production.

## A note on security

This starter follows the essentials: parameterized SQL everywhere (no string
interpolation, so no SQL injection), secrets kept in `.env` and out of Git, and
a clean separation of config from code. When you add user logins later, hash
passwords with `bcrypt` or `argon2` and serve over HTTPS (your host handles the
certificate).
