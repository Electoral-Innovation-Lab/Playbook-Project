from flask import render_template, Blueprint
from myapp.models.news import News_Headline
# from humanize import naturaltime


bp = Blueprint('news', __name__)

@bp.route('/news') 

# display all the news headlines - unfiltered
def all_news():
    # render minimal news headlines page temporarily
    articles = News_Headline.get_news_stories()
    return render_template('news.html', articles=articles)
