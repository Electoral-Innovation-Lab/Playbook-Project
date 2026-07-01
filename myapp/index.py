import os
from flask import render_template, Blueprint

bp = Blueprint('index', __name__)

@bp.route('/') # says that whenever user hits the landing (root) page of the website (with URL '/'), this endpoint function should be called.  
                # Flask will maintain a mapping between URL patterns and all endpoint functions
def index():
    # Render minimal homepage temporarily
    return render_template('index.html')