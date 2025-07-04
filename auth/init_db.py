# init_db.py
from . import app, db

with app.app_context():
    db.create_all()
