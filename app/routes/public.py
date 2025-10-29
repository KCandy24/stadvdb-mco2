"""
These routes are accessible to the public, i.e. even when not logged in.
"""
from flask import Blueprint, render_template, session, request
from app.routes.dummy_data import PLAYS, THEATERS, SHOWINGS

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
    page = request.args.get("page")

    # TODO: Use an actual database.
    # TODO: Pagination.

    return render_template(
        "search.html",
        session=session,
        search_type=search_type,
        elements=PLAYS if search_type == "play" else THEATERS,
    )


@bp.get("/showings")
def showings():
    play = request.args.get("play") or ""
    theater = request.args.get("theater") or ""

    # TODO: Use an actual database.
    # TODO: Pagination.

    filtered_showings = SHOWINGS
    if play:
        filtered_showings = filter(
            lambda showing: showing["play"] == play, filtered_showings
        )
    if theater:
        filtered_showings = filter(
            lambda showing: showing["theater"] == theater, filtered_showings
        )

    return render_template(
        "showings.html",
        session=session,
        play=play,
        theater=theater,
        showings=filtered_showings,
    )

