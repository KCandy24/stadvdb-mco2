"""
These routes handle authentication.
"""

from flask import Blueprint, request, redirect, session
from app.lib.sql_controller import controller_transactional

bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@bp.post("/login")
def login():
    ERROR_INVALID_USER = "Invalid credentials"
    email = request.form.get("username")
    password = request.form.get("password")

    # TODO: Connect to database and check if valid user and password.

    query = "SELECT transactional.verify_user(:name, :password) AS v_user_id"
    data = {"name": email, "password": password}

    v_user_id = controller_transactional.execute_sql_read(query, data)[0]

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


@bp.post("/sign-up")
def sign_up():
    name = request.form.get("username")
    password = request.form.get("password")

    # TODO: Actually create an account.

    session["name"] = name
    return redirect("/dashboard")


@bp.get("/logout")
def logout():
    session.clear()
    return redirect("/")
