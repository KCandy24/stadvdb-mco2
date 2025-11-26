from flask import Blueprint, session, redirect, request
from app.lib.sql_controller import controller_transactional

bp = Blueprint("crud", __name__, url_prefix="/api/crud")

COLUMN_PREFIX = "column."

@bp.post("create")
def create_route():
    create_request = dict(request.form.items())
    table = create_request["table"]
    data = {
        key.removeprefix(COLUMN_PREFIX): value
        for key, value in create_request.items()
        if key.startswith(COLUMN_PREFIX) and value
    }
    controller_transactional.insert("transactional", table, data)
    return redirect(request.referrer)


@bp.post("update")
def update_route():
    """TODO"""
    return redirect(request.referrer)


@bp.post("delete")
def delete_route():
    delete_request = dict(request.form.items())
    table = delete_request["table"]
    data = {
        key.removeprefix(COLUMN_PREFIX): value
        for key, value in delete_request.items()
        if key.startswith(COLUMN_PREFIX) and value
    }
    controller_transactional.delete("transactional", table, data)
    return redirect(request.referrer)
