from flask import render_template, Blueprint

bp = Blueprint('state_details', __name__)

@bp.route('/<state_name>')

def state_details(state_name):
    return render_template('state_details.html', state_name=state_name) 