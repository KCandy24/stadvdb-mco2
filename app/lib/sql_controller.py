import os
from sqlalchemy import create_engine, text
from pathlib import Path

class __Controller:
    def __init__(self, credentials: dict[str, str]):
        self.user = credentials["PG_USER"]
        self.pwd = credentials["PG_PASSWORD"]
        self.server = "localhost"
        self.port = credentials["PG_PORT"]
        self.dbName = credentials["PG_DB"]
        self.dbUrl = credentials["DB_URL"]
        self.engine = create_engine(self.dbUrl)

        self.sql_path = Path(__file__).parent / "sql"

    def execute_sql_write(self, query: str, data: dict = {}):
        with self.engine.connect() as conn:
            try:
                result = conn.execute(text(query), data or {})
                conn.commit()
                return result
            except Exception as e:
                conn.rollback()
                raise e

    def execute_sql_read(self, query: str, data: dict = {}):
        with self.engine.connect() as conn:
            try:
                result = conn.execute(text(query), data or {})
                rows = result.fetchall()
                return rows
            except Exception as e:
                conn.rollback()
                raise e

    def execute_sql_file(self, path: str):
        sql_path = self.sql_path / path

        with open(sql_path, "r", encoding="utf-8") as f:
            sql = f.read()

        with self.engine.connect() as conn:
            conn.execute(text(sql))
            conn.commit()
        print(f"Executed SQL file: {sql_path.name}")


credentials_transactional = {
    "PG_USER": "postgres",
    "PG_PASSWORD": "postgres",
    "PG_PORT": "5432",
    "PG_DB": "appdb_transactional",
    "DB_URL": os.getenv("DB_URL") 
}

credentials_analytical = {
    "PG_USER": "postgres",
    "PG_PASSWORD": "postgres",
    "PG_PORT": "5433",
    "PG_DB": "appdb_analytical",
    "DB_URL": os.getenv("DB2_URL") 
}

controller_transactional = __Controller(credentials_transactional)
controller_analytical = __Controller(credentials_analytical)
