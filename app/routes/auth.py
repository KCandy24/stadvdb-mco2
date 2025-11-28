"""
These routes handle authentication.
"""

from flask import Blueprint, request, redirect, session, render_template
from app.lib.sql_controller import controller_transactional

bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@bp.errorhandler(AssertionError)
def handle_assertion_error(e):
    return redirect(request.referrer)

ERROR_INVALID_USER = "Invalid user credentials"


def login(email: str, password: str):
    query = "SELECT transactional.verify_user(:name, :password) AS v_user_id"
    data = {"name": email, "password": password}

    try:
        v_user_id = controller_transactional.execute_sql_read(query, data)[0]
    except Exception:
        return redirect(request.referrer)

    if not v_user_id:
        return redirect(f"/login?error={ERROR_INVALID_USER}")

    if v_user_id[0] is None:
        return redirect(f"/login?error={ERROR_INVALID_USER}")
    
    session["name"] = email # str
    session["id"] = v_user_id[0] # int

    if email == "admin@admin.com" or session["id"] == 1:
        session["type"] = "admin"
    else:
        session["type"] = "user"

    return redirect("/dashboard")


@bp.post("/login")
def login_route():
    email = request.form.get("username")
    password = request.form.get("password")
    assert email
    assert password
    return login(email, password)


@bp.post("/sign-up")
def sign_up_route():
    email = request.form.get("username")
    password = request.form.get("password")
    last_name = request.form.get("last_name")
    first_name = request.form.get("first_name")
    birthday = request.form.get("birthday")

    assert email
    assert password

    query = "CALL transactional.create_user(:lastname, :firstname, :birthday, :email, :password)"
    data = {
        "lastname": last_name,
        "firstname": first_name,
        "birthday": birthday,
        "email": email,
        "password": password
    }
    try:
        controller_transactional.execute_sql_write(query, data)
    except Exception:
        return render_template("sign-up.html", error=ERROR_INVALID_USER)

    return login(email, password)


@bp.get("/logout")
def logout():
    session.clear()
    return redirect("/")
