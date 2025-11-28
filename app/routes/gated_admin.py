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
        box_columns = [key.replace("_", " ").title() for key in result_box.keys()]
        box_rows = [list(row) for row in result_box.fetchall()]

        if box_rows:
            box_chart_labels = [row[1] for row in box_rows]
            box_chart_data = [
                float(row[3]) if row[3] is not None else 0 for row in box_rows
            ]
        else:
            box_chart_labels, box_chart_data = [], []

        result_cust = conn.execute(
            text("SELECT * FROM analytical.high_value_customers();")
        )
        cust_columns = [key.replace("_", " ").title() for key in result_cust.keys()]
        cust_rows = [list(row) for row in result_cust.fetchall()]

        if cust_rows:
            cust_chart_labels = [f"{row[1]} {row[2]}" for row in cust_rows]
            cust_chart_data = [
                float(row[5]) if row[5] is not None else 0 for row in cust_rows
            ]
        else:
            cust_chart_labels, cust_chart_data = [], []

        result_pop = conn.execute(
            text("SELECT * FROM analytical.popular_plays_per_theater();")
        )
        pop_columns = [key.replace("_", " ").title() for key in result_pop.keys()]
        pop_rows = [list(row) for row in result_pop.fetchall()]

        if pop_rows:
            pop_chart_labels = [f"{row[0]}: {row[1]}" for row in pop_rows]
            pop_chart_data = [
                int(row[2]) if row[2] is not None else 0 for row in pop_rows
            ]
        else:
            pop_chart_labels, pop_chart_data = [], []
    return render_template(
        "admin/dashboard.html",
        box_columns=box_columns,
        box_rows=box_rows,
        cust_columns=cust_columns,
        cust_rows=cust_rows,
        pop_columns=pop_columns,
        pop_rows=pop_rows,
        box_chart_labels=box_chart_labels,
        box_chart_data=box_chart_data,
        cust_chart_labels=cust_chart_labels,
        cust_chart_data=cust_chart_data,
        pop_chart_labels=pop_chart_labels,
        pop_chart_data=pop_chart_data,
    )


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


@bp.get("/seat-plan")
def seat_plan_route():
    theater_id = request.args.get("theater_id")
    return render_template("admin/seat_plan.html", theater_id=theater_id)

@bp.post("/make-seat")
def make_seat_route():
    ERROR_SEAT_PLAN_EXISTS = "Seat plan already exists"
    theater_id = request.form.get("theater_id")
    rows = request.form.get("rows")
    columns = request.form.get("columns")
    default_price = request.form.get("default_price")

    query = (
        "CALL transactional.batch_create_seat(:theater, :rows, :columns, :default_price)"
    )
    data = {
        "theater": theater_id,
        "rows": rows,
        "columns": columns,
        "default_price": default_price,
    }

    try:
        controller_transactional.execute_sql_write(query, data)
    except Exception:
        return redirect(f"/admin/crud?table=theater&error={ERROR_SEAT_PLAN_EXISTS}")

    return redirect("/admin/crud?table=theater")
