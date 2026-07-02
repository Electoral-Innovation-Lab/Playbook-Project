from flask import render_template, Blueprint
from myapp.models.news import News_Headline
# from humanize import naturaltime


bp = Blueprint('news', __name__)

# display all the news headlines - unfiltered
@bp.route('/news') 
def all_news():
    # render minimal news headlines page
    articles = News_Headline.get_news_stories()
    return render_template('news.html', articles=articles)
