"""
These routes handle authentication.
"""
from flask import Blueprint, request, redirect, session

bp = Blueprint("auth", __name__, url_prefix="/api/auth")

@bp.post("/login")
def login():
    name = request.form.get("username")
    password = request.form.get("password")

    # TODO: Connect to database and check if valid user and password.

    session["name"] = name
    if name == "user":
        session["type"] = "user"
    elif name == "admin":
        session["type"] = "admin"
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
