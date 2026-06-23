"""Application factory.

create_app() builds and configures the Flask app, then registers each
developer's blueprint. Keeping setup in a factory function (rather than a
module-level `app = Flask(...)`) makes testing and deployment cleaner.

Ownership split:
  - public/  -> states, scores, categories  (the map + 50-state table)
  - content/ -> action pathways + news feed
Each person works almost entirely inside their own blueprint file.
"""
from flask import Flask, jsonify


def create_app():
    app = Flask(__name__)

    # Register feature blueprints. Each is owned by one developer.
    from myapp.public.routes import public_bp
    from myapp.content.routes import content_bp

    app.register_blueprint(public_bp)
    app.register_blueprint(content_bp)

    # A tiny health-check so you can confirm the server is up.
    @app.route("/api/health")
    def health():
        return jsonify({"status": "ok"})

    return app
