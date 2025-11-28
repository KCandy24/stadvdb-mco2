"""
These routes are inaccessible when the user isn't logged in.
"""

from flask import Blueprint, redirect, render_template, request, session
from sqlalchemy import Row, Sequence
from typing import Any

from app.lib.sql_controller import controller_transactional

bp = Blueprint("gated_user", __name__)


@bp.before_request
def check_authentication():
    if "name" not in session.keys():
        return redirect("/login?error=You need to be logged in to access that page.")


def check_if_reserved(seat_ids: int, run_id: int) -> Sequence[Row[Any]]:
    query = "SELECT seat_id, taken FROM transactional.seats_taken_for_run(:run, :seats)"
    data = {"run": run_id, "seats": seat_ids}
    return controller_transactional.execute_sql_read(query, data)


@bp.get("/dashboard")
def dashboard():
    query = """
    SELECT * FROM transactional.read_reservations_of_user(:user_id);
    """
    reservations = controller_transactional.execute_sql_read(
        query, {"user_id": session["id"]}
    )
    print(reservations)
    return render_template("dashboard.html", reservations=reservations)


@bp.get("/reserve")
def reserve_page():
    showing = request.args.get("showing")
    play = request.args.get("play")
    theater = request.args.get("theater")
    run = request.args.get("run")
    seats = controller_transactional.execute_sql_read(
        "SELECT * FROM transactional.read_seats_by_theater(:theater_id)",
        {"theater_id": theater},
    )
    ids = list(map(lambda entry: entry[0], seats))
    rows = list(map(lambda entry: entry[2], seats))
    cols = list(map(lambda entry: entry[3], seats))
    rows_cols = list(zip(rows, cols))
    prices = list(map(lambda entry: entry[4], seats))
    rows_cols_prices_ids = list(zip(rows_cols, prices, ids))
    max_row, max_col = max(rows), max(cols)

    layout = [[0 for _ in range(max_col + 1)] for _ in range(max_row + 1)]
    seat_ids = [[0 for _ in range(max_col + 1)] for _ in range(max_row + 1)]
    i = 1
    for row in range(1, max_row + 1):
        for col in range(1, max_col + 1):
            if (row, col) in rows_cols:
                price = rows_cols_prices_ids[i - 1][1]
                seat = rows_cols_prices_ids[i - 1][2]
                layout[row][col] = price
                seat_ids[row][col] = seat
            i += 1

    reserved = check_if_reserved(ids, run)
    reserved = filter(lambda x: x[1], reserved)
    reserved = map(lambda x: x[0], reserved)
    reserved = list(reserved)

    base_fee = controller_transactional.execute_sql_read(
        "SELECT basefee FROM transactional.read_showing(:showing_id)",
        {"showing_id": showing},
    )[0][0]

    return render_template(
        "reserve.html",
        run=run,
        showing=showing,
        play=play,
        theater=theater,
        layout=layout,
        base_fee=base_fee,
        seat_ids=seat_ids,
        reserved=reserved
    )


@bp.post("/api/reserve")
def reserve_showing():
    run = request.form.get("run")
    play = request.form.get("play")
    theater = request.form.get("theater")
    run = request.form.get("run")
    seats = request.form.get("seats")

    assert play
    assert theater
    assert run
    assert seats

    reservation = {"play": play, "theater": theater, "run": run, "seats": seats}
    seat_ids = list(map(int, seats.split(",")))

    if "reservations" not in session.keys():
        session.update({"reservations": []})

    print(reservation)

    query = "CALL transactional.batch_create_reservation(:user_id, :run_id, :seat_ids)"
    data = {"user_id": session["id"], "run_id": run, "seat_ids": seat_ids}

    print(f"{query = }\n{data = }")
    controller_transactional.execute_sql_write(query, data)

    session["reservations"].append(reservation)
    return redirect("/dashboard")


@bp.post("/api/unreserve")
def unreserve_showing():
    reservation = request.form.get("reservation_id")

    assert reservation

    controller_transactional.delete(
        "transactional", "reservation", {"reservation_id": reservation}
    )

    return redirect("/dashboard")
