# """CONTENT blueprint  —  OWNED BY DEVELOPER 2

# Covers action pathways and the news feed.

# Endpoints:
#   GET /api/pathways            -> active/pending reform pathways (optionally by state)
#   GET /api/news                -> latest news items, newest first
# """
# from flask import Blueprint, jsonify, request
# from myapp.db import get_connection

# content_bp = Blueprint("content", __name__)


# @content_bp.route("/api/pathways")
# def list_pathways():
#     """Reform pathways, newest first. Optional ?state=CA filter."""
#     state_abbr = request.args.get("state")
#     params = []
#     sql = """
#         SELECT p.pathway_id, s.abbreviation, p.title, p.description,
#                p.status, rc.category, p.started_at, p.resolved_at
#         FROM action_pathways p
#         JOIN states s ON s.state_id = p.state_id
#         LEFT JOIN reform_categories rc ON rc.category_id = p.category_id
#     """
#     if state_abbr:
#         sql += " WHERE s.abbreviation = %s"
#         params.append(state_abbr.upper())
#     sql += " ORDER BY p.created_at DESC;"

#     with get_connection() as conn:
#         rows = conn.execute(sql, params).fetchall()
#     return jsonify(rows)


# @content_bp.route("/api/news")
# def list_news():
#     """News items, newest first. Optional ?limit=N (default 20)."""
#     try:
#         limit = min(int(request.args.get("limit", 20)), 100)
#     except ValueError:
#         limit = 20

#     sql = """
#         SELECT n.article_id, s.abbreviation, rc.category,
#                n.headline, n.summary, n.source_name, n.source_url,
#                n.published_at, n.score_delta
#         FROM news_articles n
#         LEFT JOIN states s ON s.state_id = n.state_id
#         LEFT JOIN reform_categories rc ON rc.category_id = n.category_id
#         ORDER BY n.published_at DESC NULLS LAST
#         LIMIT %s;
#     """
#     with get_connection() as conn:
#         rows = conn.execute(sql, (limit,)).fetchall()
#     for r in rows:
#         if r["score_delta"] is not None:
#             r["score_delta"] = float(r["score_delta"])
#     return jsonify(rows)
