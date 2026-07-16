from flask import render_template, abort, Blueprint
from myapp.models.state import State
from myapp.models.news import News_Headline

bp = Blueprint('state', __name__)

@bp.route('/<state_abbr>')
def state_details(state_abbr):
    state = State.get_by_abbreviation(state_abbr)
    if state is None:
        abort(404)
    stories = News_Headline.get_news_stories(abbr=state_abbr)
    # float(...) guards against Decimal (common with Postgres NUMERIC columns);
    # scores with no data yet are dropped since there's nothing to chart.
    category_scores_json = {
        category: float(score)
        for category, score in state.category_scores.items()
        if score is not None
    }
    return render_template('state_details.html',
                           state=state,
                           stories=stories,
                           category_scores_json=category_scores_json,
                           current_state_abbr = state_abbr.upper())
