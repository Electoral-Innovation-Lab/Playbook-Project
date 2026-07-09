from flask import current_app as app

class Minimal_State:
    def __init__(self, state_id, state_name, grade, reform_score, 
                 top_category, top_category_score):
        self.state_id = state_id
        self.state_name = state_name
        self.grade = grade
        self.reform_score = reform_score
        self.top_category = top_category
        self.top_category_score = top_category_score
        
    # Get all states, corresponding grade and score, and top/leading reform category
    @staticmethod
    def get_state_table_overview():
        rows = app.db.execute("""
            SELECT DISTINCT ON (s.state_id)
                s.state_id,
                s.state_name,
                r.grade,
                r.score AS reform_score,
                c.category AS top_category,
                cs.score AS top_category_score
            FROM states s
            JOIN reform_scores r ON r.state_id = s.state_id
            JOIN category_scores cs ON cs.score_id = r.score_id
            JOIN reform_categories c ON c.category_id = cs.category_id
            ORDER BY 
                s.state_id,
                r.scored_at DESC,
                r.score_id DESC,
                cs.score DESC NULLS LAST,
                c.category ASC
        """)
        return [Minimal_State(**row) for row in rows]
    
    # get # of states graded, # dem indicators, # avg reform score
    @staticmethod
    def dem_indicators():
        row = app.db.execute("""
            SELECT COUNT(*) AS count
            FROM reform_category_variables                
        """)[0]
        return row["count"]
