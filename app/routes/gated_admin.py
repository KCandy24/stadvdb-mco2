"""
This should contain routes containing admin-side CRUD operations
"""
from sqlalchemy import text
from flask import Blueprint, render_template, session, redirect, request
from app.lib.sql_controller import controller_transactional, controller_analytical

bp = Blueprint("gated_admin", __name__, url_prefix="/admin")


@bp.before_request
def check_authentication():
    if "name" not in session.keys() and session["name"] == "admin":
        error = "You need to be logged in as `admin` to access that page."
        return redirect(f"/login?error={error}")


@bp.get("/dashboard")
def admin_dashboard():
    with controller_analytical.engine.connect() as conn:
        result_box = conn.execute(text("SELECT * FROM analytical.box_office_report();"))
        box_columns = [key.replace('_', ' ').title() for key in result_box.keys()]
        box_rows = [list(row) for row in result_box.fetchall()]

        result_cust = conn.execute(text("SELECT * FROM analytical.high_value_customers();"))
        cust_columns = [key.replace('_', ' ').title() for key in result_cust.keys()]
        cust_rows = [list(row) for row in result_cust.fetchall()]

        result_pop = conn.execute(text("SELECT * FROM analytical.popular_plays_per_theater();"))
        pop_columns = [key.replace('_', ' ').title() for key in result_pop.keys()]
        pop_rows = [list(row) for row in result_pop.fetchall()]

    return render_template('admin/dashboard.html', 
                           box_columns=box_columns, 
                           box_rows=box_rows,
                           cust_columns=cust_columns,
                           cust_rows=cust_rows,
                           pop_columns=pop_columns,
                           pop_rows=pop_rows)


@bp.get("/crud")
def admin_crud():
    table_name = request.args.get("table")
    assert table_name is not None
    assert table_name in controller_transactional.get_tables("transactional")
    columns = controller_transactional.get_columns("transactional", table_name)
    rows = controller_transactional.get_rows("transactional", table_name)
    return render_template(
        "admin/crud.html", table_name=table_name, columns=columns, rows=rows
    )
