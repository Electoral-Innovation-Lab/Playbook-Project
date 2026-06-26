from flask import Blueprint, jsonify
from myapp.db import get_connection

about_bp = Blueprint("about", __name__)

@about_bp.route("/api/about")
def get_about():
    sections_sql = "SELECT slug, title, body, sort_order FROM about_sections ORDER BY sort_order;"
    items_sql = "SELECT label, description, sort_order FROM index_guide_items ORDER BY sort_order;"

    with get_connection() as conn:
        sections = conn.execute(sections_sql).fetchall()
        items = conn.execute(items_sql).fetchall()

    return jsonify({
        "sections": sections,
        "index_items": items
    })