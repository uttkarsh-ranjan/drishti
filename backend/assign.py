from app import create_app
from app.models import db, Assignment, User, Institution
from datetime import datetime

app = create_app()
with app.app_context():
    insp = User.query.filter_by(username='inspector1').first()
    ngo = Institution.query.filter_by(name='NGO 1').first()
    if insp and ngo:
        a = Assignment(inspector_id=insp.id, institution_id=ngo.id, scheduled_date=datetime.utcnow().date())
        db.session.add(a)
        db.session.commit()
        print("Assigned!")
