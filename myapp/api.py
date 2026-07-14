# from flask import Blueprint, jsonify, abort
# from myapp.models.state import State, ALL_STATES

# bp = Blueprint('api', __name__, url_prefix='/api')


# @bp.route('/states')
# def all_states():
#     return jsonify(State.get_all())


# @bp.route('/states/<abbr>')
# def state_detail(abbr):
#     if abbr.upper() not in ALL_STATES:
#         abort(404)
#     state = State.get_by_abbreviation(abbr)
#     return jsonify({
#         'abbreviation': state.abbreviation,
#         'name': state.name,
#         'score': float(state.score) if state.score is not None else None,
#         'grade': state.grade,
#         'scored_at': state.scored_at.isoformat() if state.scored_at else None,
#         'category_scores': [
#             {
#                 'category': cs['category'],
#                 'score': float(cs['score']) if cs['score'] is not None else None,
#                 'notes': cs['notes'],
#             }
#             for cs in state.category_scores
#         ],
#         'pathways': state.pathways,
#         'news': state.news,
#     })
