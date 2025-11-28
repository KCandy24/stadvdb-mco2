"""
These routes are accessible to the public, i.e. even when not logged in.
"""

from flask import Blueprint, render_template, request, session

from app.db import get_db
from app.lib.sql_controller import controller_transactional

bp = Blueprint("pages", __name__)


@bp.get("/")
def index():
    return render_template("index.html")


@bp.get("/login")
def login():
    error = request.args.get("error")
    return render_template("login.html", error=error)


@bp.get("/sign-up")
def sign_up():
    return render_template("sign-up.html")


@bp.get("/search")
def search():
    search_type = request.args.get("by")  # either "play" or "theater"
    page = request.args.get("page")  # pagination, TODO: currently unused

    assert search_type

    columns = {
        "play": ["play_id", "play_name"],
        "theater": ["theater_id", "theater_name", "location"],
    }

    elements = controller_transactional.read(
        "transactional", search_type, columns[search_type]
    )

    return render_template(
        "search.html",
        session=session,
        search_type=search_type,
        elements=elements,
        columns=columns[search_type],
    )


@bp.get("/showings")
def showings_route():
    play = request.args.get("play") or ""
    theater = request.args.get("theater") or ""
    page = request.args.get("page")  # pagination, TODO: currently unused

    columns = [
        "showing_id",
        "play_id",
        "theater_id",
        "play_name",
        "theater_name",
        "basefee",
        "reservation_period_start",
        "reservation_period_end",
    ]

    showings = []

    if play:
        showings = controller_transactional.execute_sql_read(
            "SELECT * FROM transactional.read_showings_by_play(:play_id)",
            {"play_id": play},
        )
    elif theater:
        showings = controller_transactional.execute_sql_read(
            "SELECT * FROM transactional.read_showings_by_theater(:theater_id)",
            {"theater_id": theater},
        )

    return render_template(
        "showings.html",
        session=session,
        play=play,
        theater=theater,
        columns=columns,
        showings=showings,
    )


@bp.get("/runs")
def runs_route():
    showing = request.args.get("showing")
    play = request.args.get("play")
    theater = request.args.get("theater")
    runs = controller_transactional.execute_sql_read(
        "SELECT * FROM transactional.read_runs_by_showing(:showing_id)",
        {"showing_id": showing},
    )
    return render_template(
        "runs.html",
        showing=showing,
        play=play,
        theater=theater,
        runs=runs,
        columns=controller_transactional.get_columns("transactional", "run"),
    )


@bp.route("/db-test")
def db_test():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT 1;")
    result = cur.fetchone()
    return {"db_response": result[0]}
