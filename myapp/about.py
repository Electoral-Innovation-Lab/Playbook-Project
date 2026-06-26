from flask import Blueprint, render_template

bp = Blueprint("about", __name__)

@bp.route("/about")
def get_about():
    # print all about eil and playbook project description
    
    return render_template('about.html')