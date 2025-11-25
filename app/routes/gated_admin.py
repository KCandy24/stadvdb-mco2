"""
This should contain routes containing admin-side CRUD operations
"""

from flask import Blueprint, render_template, session, redirect, request
from sqlalchemy import Row
from typing import Sequence, Any
from app.lib.sql_controller import controller_transactional

bp = Blueprint("gated_admin", __name__, url_prefix="/admin")


@bp.before_request
def check_authentication():
    if "name" not in session.keys() and session["name"] == "admin":
        error = "You need to be logged in as `admin` to access that page."
        return redirect(f"/login?error={error}")


@bp.get("/dashboard")
def admin_dashboard():
    return render_template("admin/dashboard.html")


@bp.get("/crud")
def admin_crud():
    table_name = request.args.get("table")
    assert table_name is not None
    assert table_name in get_tables("transactional")
    columns = get_columns(table_name)
    rows = get_rows(f"transactional.{table_name}")
    return render_template(
        "admin/crud.html", table_name=table_name, columns=columns, rows=rows
    )


def get_tables(schema_name: str) -> list[str]:
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


def get_columns(table_name: str) -> list[str]:
    columns_query = """
        SELECT
            column_name
        FROM
            information_schema.columns
        WHERE
            table_schema = 'transactional' AND table_name = :table;
    """
    columns_query_args = {"table": table_name}
    result = controller_transactional.execute_sql_read(
        columns_query, columns_query_args
    )
    column_names = []
    for row in result:
        column_names.append(row.tuple()[0])
    return column_names


def get_rows(table_name: str) -> Sequence[Row[Any]]:
    """
    ! We can't put table names as args, so ensure that `table_name` is really
    ! just the name of a table via assertions
    ! e.g. `assert table_name in get_tables("transactional")`
    """
    query = f"SELECT * FROM {table_name}"
    result = controller_transactional.execute_sql_read(query)
    return result
