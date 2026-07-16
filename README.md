# SET UP INSTRUCTIONS

# first time: 
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

4. **Create your local database and load schema + seed:**
   ```bash
   (dropdb playbook)
   createdb playbook

   psql playbook -f db/create.sql
   psql playbook -f db/load.sql
   psql playbook -f db/seed.sql
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

# To run locally after setting up once:
source venv/bin/activate
python run.py


