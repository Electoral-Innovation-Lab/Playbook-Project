from flask import current_app as app

class State:
    def __init__(self, name, state_id, abbreviation, electoral_votes,
                 reform_score_id, reform_score, grade, scored_at,
                 category_scores, pathways):
        self.name = name
        self.state_id = state_id
        self.abbreviation = abbreviation
        self.electoral_votes = electoral_votes
        self.reform_score_id = reform_score_id
        self.reform_score = reform_score
        self.grade = grade
        self.scored_at = scored_at
        self.category_scores = category_scores or {} # dict with category:score mapping
        self.pathways = pathways or [] # list of pathways
        
    @staticmethod
    def get_all_states():
        rows = app.db.execute("""
            SELECT state_name, abbreviation
            FROM states       
                              """)
        return {row["abbreviation"].upper(): row["state_name"] for row in rows}

    @staticmethod
    def get_by_abbreviation(abbr):
        abbr_upper = abbr.upper()
        states_dict = State.get_all_states()
        if abbr_upper not in states_dict :
            return None

        state_name = states_dict[abbr_upper]

        rows = app.db.execute("""
            SELECT
                s.state_name,
                s.state_id,
                s.abbreviation,
                s.electoral_votes,
                rs.score_id,
                rs.score AS reform_score,
                rs.grade,
                rs.scored_at
            FROM states s
            JOIN reform_scores rs ON rs.state_id = s.state_id
            WHERE UPPER(s.abbreviation) = :abbr
            ORDER BY rs.scored_at DESC, rs.score_id DESC
            LIMIT 1
        """, abbr=abbr_upper)

        if not rows :
            return State(name=state_name, state_id=None, abbreviation = abbr_upper, electoral_votes=0,
                 reform_score_id=None,reform_score=None, grade=None, scored_at=None,
                 category_scores=None, pathways=None)
            
        row = rows[0]

        # get category scores for the state
        # category_scores dict (category:score)
        cat_rows = app.db.execute("""
                SELECT rc.category, cs.score
                FROM category_scores cs
                JOIN reform_categories rc ON rc.category_id = cs.category_id
                WHERE cs.score_id = :score_id
                ORDER BY rc.category
            """, score_id=row.score_id)
        category_scores = {cat.category: cat.score for cat in cat_rows}
        
        # get list of action pathways for the state
        # pathways[] list 
        pathway_rows = app.db.execute("""
            SELECT ap.title
            FROM action_pathways ap
            WHERE ap.state_id = :state_id
            ORDER BY ap.state_id
        """, state_id=row.state_id)
        pathways = [pr.title for pr in pathway_rows]
        
        return State(
            name=row.state_name,
            state_id=row.state_id,
            abbreviation=row.abbreviation,
            electoral_votes=row.electoral_votes,
            reform_score_id=row.score_id,
            reform_score=row.reform_score,
            grade=row.grade,
            scored_at=row.scored_at,
            category_scores=category_scores,
            pathways=pathways
        )
