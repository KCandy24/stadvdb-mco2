"""
This should contain routes containing admin-side CRUD operations
"""

from flask import Blueprint, render_template, session, redirect, request
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
    assert table_name in controller_transactional.get_tables("transactional")
    columns = controller_transactional.get_columns("transactional", table_name)
    rows = controller_transactional.get_rows(f"transactional.{table_name}")
    return render_template(
        "admin/crud.html", table_name=table_name, columns=columns, rows=rows
    )
