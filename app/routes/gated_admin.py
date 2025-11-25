"""
This should contain routes containing admin-side CRUD operations
"""

from flask import Blueprint, render_template, session, redirect, request
from app.routes.dummy_data import SEAT_LAYOUTS

bp = Blueprint("gated_admin", __name__)

