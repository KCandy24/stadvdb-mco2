from flask import Flask
from flask_session import Session
import os
import psycopg
from .db import close_db


def create_app() -> Flask:
    app = Flask(__name__)

    app.config["DB_URL"] = os.environ.get("DB_URL")
    
    app.config["SESSION_PERMANENT"] = False
    app.config["SESSION_TYPE"] = "filesystem"
    Session(app)

    from .routes import auth, public, gated_user, gated_admin, crud

    app.register_blueprint(auth.bp)
    app.register_blueprint(public.bp)
    app.register_blueprint(gated_admin.bp)
    app.register_blueprint(gated_user.bp)
    app.register_blueprint(crud.bp)
    app.teardown_appcontext(close_db)
    print("Blueprints loaded:", app.blueprints)

    return app
