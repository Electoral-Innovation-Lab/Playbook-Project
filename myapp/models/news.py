from flask import current_app as app
from sqlalchemy import text, bindparam
import traceback
# from myapp.db import get_connection


class News_Headline:
    def __init__(self, article_id, headline, summary, source_name,
                 source_url, published_at, is_national, created_at):
        self.article_id = article_id
        self.headline = headline
        self.summary = summary
        self.source_name = source_name
        self.source_url = source_url
        self.published_at = published_at
        self.is_national = is_national
        self.created_at = created_at

    # just displaying news stories for now -- will add in state connection later
    @staticmethod
    def get_news_stories():
        rows = app.db.execute("""
            SELECT
                article_id,
                headline,
                summary,
                source_name,
                source_url,
                published_at,
                is_national,
                created_at
            FROM news_articles
            ORDER BY published_at DESC, article_id DESC
        """)

        return [
            News_Headline(
                row.article_id,
                row.headline,
                row.summary,
                row.source_name,
                row.source_url,
                row.published_at,
                row.is_national,
                row.created_at
            )
            for row in rows
        ]