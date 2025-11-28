import os
from pathlib import Path
from typing import Any, Sequence

from sqlalchemy import CursorResult, Row, create_engine, text


class __Controller:
    def __init__(self, credentials: dict[str, str]):
        self.user = credentials["PG_USER"]
        self.pwd = credentials["PG_PASSWORD"]
        self.server = "localhost"
        self.port = credentials["PG_PORT"]
        self.dbName = credentials["PG_DB"]
        self.dbUrl = credentials["DB_URL"]
        self.backupUrl = credentials.get("BACKUP_URL") or None
        self.dbEngine = create_engine(self.dbUrl)
        self.backupEngine = create_engine(self.backupUrl) if self.backupUrl else None

        self.engine = self.dbEngine
        self.sql_path = Path(__file__).parent / "sql"

    def switchEngine(self):
        if self.engine == self.dbEngine:
            self.engine = self.backupEngine
        else:
            self.engine = self.dbEngine

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

    def get_tables(self, schema_name: str) -> list[str]:
        query = """
        SELECT
            DISTINCT table_name
        FROM
            information_schema.columns
        WHERE
            table_schema = :schema_name;
        """
        args = {"schema_name": schema_name}
        result = controller_transactional.execute_sql_read(query, args)
        table_names = [row.tuple()[0] for row in result]
        return table_names

    def get_columns(self, schema_name: str, table_name: str) -> list[str]:
        columns_query = """
            SELECT
                column_name
            FROM
                information_schema.columns
            WHERE
                table_schema = :table_schema AND table_name = :table;
        """
        columns_query_args = {"table": table_name, "table_schema": schema_name}
        result = controller_transactional.execute_sql_read(
            columns_query, columns_query_args
        )
        column_names = []
        for row in result:
            column_names.append(row.tuple()[0])
        return column_names

    def get_rows(self, table_name: str) -> Sequence[Row[Any]]:
        """
        ! We can't put table names as args, so ensure that `table_name` is really
        ! just the name of a table via assertions
        ! e.g. `assert table_name in get_tables("transactional")`
        """
        query = f"SELECT * FROM {table_name}"
        result = controller_transactional.execute_sql_read(query)
        return result

    def read(
        self,
        schema: str,
        table: str,
        rows: list[str],
        where_data: dict[str, str] | None = None,
    ) -> CursorResult[Any]:
        if where_data is not None:
            where_fields = " AND ".join(
                [f"{key} = :where_{key}" for key, _ in where_data.items()]
            )
            where_clause = f"WHERE {where_fields}"
            rows_list = ", ".join(rows)
            query = f"SELECT {rows_list} FROM {schema}.{table} {where_clause}"
            return self.execute_sql_write(query, where_data)
        else:
            where_clause = ""
            rows_list = ", ".join(rows)
            query = f"SELECT {rows_list} FROM {schema}.{table} {where_clause}"
            return self.execute_sql_write(query)

    def insert(
        self, schema: str, table: str, data: dict[str, str]
    ) -> CursorResult[Any]:
        columns = ", ".join(data.keys())
        placeholders = ", ".join(map(lambda k: f":{k}", data.keys()))
        query = f"INSERT INTO {schema}.{table} ({columns}) VALUES ({placeholders})"
        print(f"{query = }\n{data = }")
        return self.execute_sql_write(query, data)

    def update(
        self,
        schema: str,
        table: str,
        set_data: dict[str, str],
        where_data: dict[str, str],
    ) -> CursorResult[Any]:
        """TODO: This is untested"""
        set_fields = ", ".join([f"{key} = :{key}" for key, _ in set_data.items()])
        where_fields = " AND ".join(
            [f"{key} = :where_{key}" for key, _ in where_data.items()]
        )
        query = f"UPDATE {schema}.{table} SET {set_fields} WHERE {where_fields}"
        data = set_data
        data.update({"where_" + key: value for key, value in where_data.items()})
        print(f"{query = }\n{data = }")
        return self.execute_sql_write(query, data)

    def delete(
        self, schema: str, table: str, where_data: dict[str, str]
    ) -> CursorResult[Any]:
        """TODO: This is untested"""
        where_fields = " AND ".join(
            [f"{key} = :{key}" for key, _ in where_data.items()]
        )
        query = f"DELETE FROM {schema}.{table} WHERE {where_fields}"
        return self.execute_sql_write(query, where_data)


credentials_transactional = {
    "PG_USER": "postgres",
    "PG_PASSWORD": "postgres",
    "PG_PORT": "5432",
    "PG_DB": "appdb_transactional",
    "DB_URL": os.getenv("DB_URL"),
    "BACKUP_URL": os.getenv("BACKUP_URL"),
}

credentials_analytical = {
    "PG_USER": "postgres",
    "PG_PASSWORD": "postgres",
    "PG_PORT": "5433",
    "PG_DB": "appdb_analytical",
    "DB_URL": os.getenv("DB2_URL"),
}

controller_transactional = __Controller(credentials_transactional)
controller_analytical = __Controller(credentials_analytical)
