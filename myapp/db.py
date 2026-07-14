from sqlalchemy import create_engine, text


class DB:
    def __init__(self, app):
        self.engine = create_engine(
            app.config["SQLALCHEMY_DATABASE_URI"],
            execution_options={"isolation_level": "SERIALIZABLE"}
        )

    def execute(self, sqlstr, **kwargs):
        with self.engine.begin() as conn:
            result = conn.execute(text(sqlstr), kwargs)
            if result.returns_rows:
                return result.mappings().all()
            else:
                return result.rowcount