# from flask import current_app as app

# ALL_STATES = {
#     'AL': 'Alabama',              'AK': 'Alaska',           'AZ': 'Arizona',
#     'AR': 'Arkansas',             'CA': 'California',       'CO': 'Colorado',
#     'CT': 'Connecticut',          'DC': 'District of Columbia', 'DE': 'Delaware',
#     'FL': 'Florida',              'GA': 'Georgia',          'HI': 'Hawaii',
#     'ID': 'Idaho',                'IL': 'Illinois',         'IN': 'Indiana',
#     'IA': 'Iowa',                 'KS': 'Kansas',           'KY': 'Kentucky',
#     'LA': 'Louisiana',            'ME': 'Maine',            'MD': 'Maryland',
#     'MA': 'Massachusetts',        'MI': 'Michigan',         'MN': 'Minnesota',
#     'MS': 'Mississippi',          'MO': 'Missouri',         'MT': 'Montana',
#     'NE': 'Nebraska',             'NV': 'Nevada',           'NH': 'New Hampshire',
#     'NJ': 'New Jersey',           'NM': 'New Mexico',       'NY': 'New York',
#     'NC': 'North Carolina',       'ND': 'North Dakota',     'OH': 'Ohio',
#     'OK': 'Oklahoma',             'OR': 'Oregon',           'PA': 'Pennsylvania',
#     'RI': 'Rhode Island',         'SC': 'South Carolina',   'SD': 'South Dakota',
#     'TN': 'Tennessee',            'TX': 'Texas',            'UT': 'Utah',
#     'VT': 'Vermont',              'VA': 'Virginia',         'WA': 'Washington',
#     'WV': 'West Virginia',        'WI': 'Wisconsin',        'WY': 'Wyoming',
# }


# class State:
#     def __init__(self, state_id, name, abbreviation,
#                  score=None, grade=None, scored_at=None,
#                  category_scores=None, pathways=None, news=None):
#         self.state_id = state_id
#         self.name = name
#         self.abbreviation = abbreviation
#         self.score = score
#         self.grade = grade
#         self.scored_at = scored_at
#         self.category_scores = category_scores or []
#         self.pathways = pathways or []
#         self.news = news or []

#     @staticmethod
#     def get_by_abbreviation(abbr):
#         abbr_upper = abbr.upper()
#         if abbr_upper not in ALL_STATES:
#             return None

#         name = ALL_STATES[abbr_upper]

#         rows = app.db.execute("""
#             SELECT
#                 s.state_id,
#                 rs.score_id,
#                 rs.score,
#                 rs.grade,
#                 rs.scored_at
#             FROM states s
#             LEFT JOIN reform_scores rs ON rs.state_id = s.state_id
#             WHERE UPPER(s.abbreviation) = :abbr
#             ORDER BY rs.scored_at DESC, rs.score_id DESC
#             LIMIT 1
#         """, abbr=abbr_upper)

#         if not rows:
#             return State(None, name, abbr_upper)

#         row = rows[0]
#         state = State(
#             state_id=row.state_id,
#             name=name,
#             abbreviation=abbr_upper,
#             score=row.score,
#             grade=row.grade,
#             scored_at=row.scored_at,
#         )

#         if row.state_id is None:
#             return state

#         if row.score_id is not None:
#             cat_rows = app.db.execute("""
#                 SELECT rc.category, cs.score, cs.notes
#                 FROM category_scores cs
#                 JOIN reform_categories rc ON rc.category_id = cs.category_id
#                 WHERE cs.score_id = :score_id
#                 ORDER BY rc.category
#             """, score_id=row.score_id)
#             for cr in cat_rows:
#                 state.category_scores.append({
#                     'category': cr.category,
#                     'score': cr.score,
#                     'notes': cr.notes,
#                 })

#         pathway_rows = app.db.execute("""
#             SELECT ap.title, ap.path_description, ap.path_status, rc.category
#             FROM action_pathways ap
#             LEFT JOIN reform_categories rc ON rc.category_id = ap.category_id
#             WHERE ap.state_id = :state_id
#             ORDER BY ap.started_at DESC
#         """, state_id=row.state_id)
#         for pr in pathway_rows:
#             state.pathways.append({
#                 'title': pr.title,
#                 'description': pr.path_description,
#                 'status': pr.status,
#                 'category': pr.category,
#             })

#         news_rows = app.db.execute("""
#             SELECT na.headline, na.source_name, na.source_url,
#                    na.published_at, nsu.score_delta
#             FROM news_articles na
#             JOIN news_state_updates nsu ON nsu.article_id = na.article_id
#             WHERE nsu.state_id = :state_id
#             ORDER BY na.published_at DESC
#             LIMIT 5
#         """, state_id=row.state_id)
#         for nr in news_rows:
#             state.news.append({
#                 'headline': nr.headline,
#                 'source_name': nr.source_name,
#                 'source_url': nr.source_url,
#                 'published_at': nr.published_at.isoformat() if nr.published_at else None,
#                 'score_delta': float(nr.score_delta) if nr.score_delta is not None else None,
#             })

#         return state

#     @staticmethod
#     def get_all():
#         rows = app.db.execute("""
#             SELECT DISTINCT ON (s.abbreviation)
#                 s.state_id,
#                 s.abbreviation,
#                 rs.score,
#                 rs.grade,
#                 (
#                     SELECT string_agg(ap_inner.title, ', ')
#                     FROM (
#                         SELECT title FROM action_pathways
#                         WHERE state_id = s.state_id
#                           AND status IN ('active', 'pending')
#                         ORDER BY started_at DESC
#                         LIMIT 3
#                     ) ap_inner
#                 ) AS leading_reforms
#             FROM states s
#             LEFT JOIN reform_scores rs ON rs.state_id = s.state_id
#             ORDER BY s.abbreviation, rs.scored_at DESC, rs.score_id DESC
#         """)

#         db_data = {row.abbreviation.upper(): row for row in rows}

#         result = []
#         for abbr, name in sorted(ALL_STATES.items()):
#             row = db_data.get(abbr)
#             result.append({
#                 'abbreviation': abbr,
#                 'name': name,
#                 'score': float(row.score) if row and row.score is not None else None,
#                 'grade': row.grade if row else None,
#                 'leading_reforms': row.leading_reforms if row else None,
#             })
#         return result