from flask import current_app as app

class News_Headline:
    def __init__(self, article_id, headline, summary, source_name,
                 source_url, published_at, is_national, created_at, states=None):
        self.article_id = article_id
        self.headline = headline
        self.summary = summary
        self.source_name = source_name
        self.source_url = source_url
        self.published_at = published_at
        self.is_national = is_national
        self.created_at = created_at
        self.states = states or [] # list of dicts [{state_id, abbrev, score_delta},...]
        
    # just displaying news stories for now -- will add in state connection later
    @staticmethod
    def get_news_stories():
        rows = app.db.execute("""
            SELECT
                na.article_id,
                na.headline,
                na.summary,
                na.source_name,
                na.source_url,
                na.published_at,
                na.is_national,
                na.created_at,
                nsu.score_delta,
                s.state_id,
                s.abbreviation
            FROM news_articles na
            LEFT JOIN news_state_updates nsu ON na.article_id = nsu.article_id
            LEFT JOIN states s ON nsu.state_id = s.state_id 
            ORDER BY na.published_at DESC, s.abbreviation ASC, na.article_id DESC
        """)
        articles = {}
        for row in rows:
            if row.article_id not in articles:
                articles[row['article_id']] = News_Headline(
                    row['article_id'],
                    row['headline'],
                    row['summary'],
                    row['source_name'],
                    row['source_url'],
                    row['published_at'],
                    row['is_national'],
                    row['created_at']
                )
            if row['state_id'] is not None:
                articles[row['article_id']].states.append({
                    'state_id': row['state_id'],
                    'abbreviation': row['abbreviation'],
                    'score_delta': row['score_delta']
                })
        return list(articles.values())