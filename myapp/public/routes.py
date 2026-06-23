"""PUBLIC blueprint  —  OWNED BY DEVELOPER 1

Covers states, composite scores, and category breakdowns:
the data behind the interactive map and the 50-state comparison table.

Endpoints:
  GET /api/states            -> every state with its latest composite score
  GET /api/states/<abbr>     -> one state's profile + per-category breakdown
"""
from flask import Blueprint, jsonify, abort
from myapp.db import get_connection

public_bp = Blueprint("public", __name__)


@public_bp.route("/api/states")
def list_states():
    """Every state with its most recent composite score and grade."""
    sql = """
        SELECT s.state_id, s.name, s.abbreviation, rs.score, rs.grade
        FROM states s
        LEFT JOIN LATERAL (
            SELECT score, grade
            FROM reform_scores
            WHERE state_id = s.state_id
            ORDER BY scored_at DESC
            LIMIT 1
        ) rs ON TRUE
        ORDER BY rs.score DESC NULLS LAST;
    """
    with get_connection() as conn:
        rows = conn.execute(sql).fetchall()
    # NUMERIC comes back as Decimal; cast to float for clean JSON.
    for r in rows:
        if r["score"] is not None:
            r["score"] = float(r["score"])
    return jsonify(rows)


@public_bp.route("/api/states/<abbr>")
def state_detail(abbr):
    """One state's latest score plus its per-category breakdown."""
    abbr = abbr.upper()
    with get_connection() as conn:
        state = conn.execute(
            "SELECT state_id, name, abbreviation FROM states WHERE abbreviation = %s",
            (abbr,),
        ).fetchone()
        if state is None:
            abort(404, description=f"No state with abbreviation {abbr}")

        latest = conn.execute(
            """
            SELECT score_id, score, grade, scored_at
            FROM reform_scores
            WHERE state_id = %s
            ORDER BY scored_at DESC
            LIMIT 1
            """,
            (state["state_id"],),
        ).fetchone()

        categories = []
        if latest:
            categories = conn.execute(
                """
                SELECT rc.category, cs.score, cs.notes
                FROM category_scores cs
                JOIN reform_categories rc ON rc.category_id = cs.category_id
                WHERE cs.score_id = %s
                ORDER BY rc.category
                """,
                (latest["score_id"],),
            ).fetchall()

    # Tidy Decimal -> float
    if latest and latest["score"] is not None:
        latest["score"] = float(latest["score"])
    for c in categories:
        if c["score"] is not None:
            c["score"] = float(c["score"])

    return jsonify({"state": state, "latest_score": latest, "categories": categories})
