from typing import Any
from flask import Blueprint, session, redirect, request
from sqlalchemy import CursorResult
from app.lib.sql_controller import controller_transactional

bp = Blueprint("crud", __name__, url_prefix="/api/crud")


def insert(table: str, data: dict[str, str]) -> CursorResult[Any]:
    columns = ", ".join(data.keys())
    placeholders = ", ".join(map(lambda k: f":{k}", data.keys()))
    query = f"INSERT INTO transactional.{table} ({columns}) VALUES ({placeholders})"
    print(f"{query = }\n{data = }")
    return controller_transactional.execute_sql_write(query, data)


def update(
    table: str, set_data: dict[str, str], where_data: dict[str, str]
) -> CursorResult[Any]:
    """TODO: This is untested"""
    set_fields = ", ".join([f"{key} = :{key}" for key, _ in set_data.items()])
    where_fields = ", ".join([f"{key} = :{key}" for key, _ in where_data.items()])
    query = f"UPDATE {table} SET {set_fields} WHERE {where_fields}"
    data = set_data
    data.update(where_data)
    return controller_transactional.execute_sql_write(query, data)


def delete(table: str, where_data: dict[str, str]) -> CursorResult[Any]:
    """TODO"""
    ...


@bp.post("create")
def create_route():
    COLUMN_PREFIX = "column."
    create_request = dict(request.form.items())
    table = create_request["table"]
    data = {
        key.removeprefix(COLUMN_PREFIX): value
        for key, value in create_request.items()
        if key.startswith(COLUMN_PREFIX) and value
    }
    insert(table, data)
    return redirect(request.referrer)


@bp.post("update")
def update_route():
    """TODO"""
    return redirect(request.referrer)


@bp.post("delete")
def delete_route():
    """TODO"""
    return redirect(request.referrer)
