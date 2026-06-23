"""Entry point. Run with:  python run.py

Starts the development server at http://localhost:5000 with auto-reload.
This is for LOCAL DEVELOPMENT ONLY — in production a host like Render runs
the app via gunicorn (see README), not this file.
"""
from myapp import create_app

app = create_app()

if __name__ == "__main__":
    app.run(debug=True, port=5000)
