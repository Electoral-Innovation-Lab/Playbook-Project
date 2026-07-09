import os
from flask import render_template, Blueprint
from myapp.models.index import Minimal_State

bp = Blueprint('index', __name__)

@bp.route('/') # says that whenever user hits the landing (root) page of the website (with URL '/'), this endpoint function should be called.  
                # Flask will maintain a mapping between URL patterns and all endpoint functions
def index():
    states_minimal = Minimal_State.get_state_table_overview() # create 50 states table
    num_dem_indicators = Minimal_State.dem_indicators()
    
    # calc home page metrics: graded stages,number of vars, avg reform score
    states_with_grade = sum(1 for s in states_minimal if s.grade is not None)
    scores = [s.reform_score for s in states_minimal if s.reform_score is not None]
    avg_reform_score = sum(scores) / len(scores) if scores else None
    
    # Render homepage 
    return render_template('index.html', 
                           states_minimal=states_minimal,
                           states_with_grade = states_with_grade,
                           avg_reform_score = avg_reform_score,
                           num_dem_indicators=num_dem_indicators
                           ) 