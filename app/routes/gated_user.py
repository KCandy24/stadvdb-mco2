"""
These routes are inaccessible when the user isn't logged in.
"""

from flask import Blueprint, redirect, render_template, request, session

from app.lib.sql_controller import controller_transactional
from app.routes.dummy_data import SEAT_LAYOUTS

bp = Blueprint("gated_user", __name__)


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
    # Get seats for this theater id
    # calling the function `transactional.read_seats_by_theater` seems to
    # return results in a weird format so I just directly query
    seats = controller_transactional.execute_sql_read(
        "SELECT * FROM transactional.seat WHERE theater_id = :theater_id;",
        {"theater_id": theater},
    )
    rows = list(map(lambda entry: entry[2], seats))
    cols = list(map(lambda entry: entry[3], seats))
    max_row, max_col = max(rows), max(cols)
    layout = [
        [(row, col) in zip(rows, cols) for row in range(max_row)]
        for col in range(max_col)
    ]
    print(f"{layout = }")
    # Generate matrix -- Place price for each row, col entry
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
