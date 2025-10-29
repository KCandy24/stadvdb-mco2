from flask import Flask
from flask_session import Session


def create_app() -> Flask:
    app = Flask(__name__)

    app.config["SESSION_PERMANENT"] = False
    app.config["SESSION_TYPE"] = "filesystem"
    Session(app)

    from .routes import auth, public, gated

    app.register_blueprint(auth.bp)
    app.register_blueprint(public.bp)
    app.register_blueprint(gated.bp)

    return app
