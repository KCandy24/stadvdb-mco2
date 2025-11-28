from pkgutil import get_data
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
    old_prefix = COLUMN_PREFIX + "old."
    update_request = dict(request.form.items())
    table = update_request["table"]
    where_data = {
        key.removeprefix(old_prefix): value
        for key, value in update_request.items()
        if key.startswith(old_prefix) and value
    }
    set_data = {
        key.removeprefix(COLUMN_PREFIX): value
        for key, value in update_request.items()
        if key.startswith(COLUMN_PREFIX) and not key.startswith(old_prefix) and value
    }
    controller_transactional.update("transactional", table, set_data, where_data)
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
