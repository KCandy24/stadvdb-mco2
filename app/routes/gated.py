"""
These routes are inaccessible when the user isn't logged in.
"""

from flask import Blueprint, render_template, session, redirect, request
from app.routes.dummy_data import SEAT_LAYOUTS

bp = Blueprint("gated", __name__)


@bp.before_request
def check_authentication():
    if "name" not in session.keys():
        return redirect("/login?error=You need to be logged in to access that page.")


@bp.get("/dashboard")
def dashboard():
    return render_template("dashboard.html")


@bp.get("/reserve")
def reserve_page():
    play = request.args.get("play")
    theater = request.args.get("theater")
    layout = next(filter(lambda layout: layout["theater"] == theater, SEAT_LAYOUTS))
    layout = layout["layout"].split("\n")
    return render_template("reserve.html", play=play, theater=theater, layout=layout)


@bp.post("/api/reserve")
def reserve_showing():
    play = request.form.get("play")
    theater = request.form.get("theater")
    seats = request.form.get("seats")
    reservation = {"play": play, "theater": theater, "seats": seats}

    if "reservations" not in session.keys():
        session.update({"reservations": []})

    print(reservation)
    session["reservations"].append(reservation)
    return redirect("/dashboard")


@bp.post("/api/unreserve")
def unreserve_showing():
    play = request.form.get("play")
    theater = request.form.get("theater")
    seats = request.form.get("seats")

    remove_value = {"play": play, "theater": theater, "seats": seats}

    if (
        "reservations" not in session.keys()
        or remove_value not in session["reservations"]
    ):
        print(remove_value)
        print(session["reservations"])
        return redirect("/dashboard?error=Reservation does not exist!")
    else:
        session["reservations"].remove(remove_value)
        return redirect("/dashboard")
