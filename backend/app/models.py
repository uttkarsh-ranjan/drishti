from flask_sqlalchemy import SQLAlchemy
from geoalchemy2 import Geometry
from datetime import datetime

db = SQLAlchemy()

class Role(db.Model):
    __tablename__ = 'roles'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False) # e.g., 'DoSJE_Official', 'PMU_Inspector', 'NGO_Admin'

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role_id = db.Column(db.Integer, db.ForeignKey('roles.id'), nullable=False)
    role = db.relationship('Role', backref=db.backref('users', lazy=True))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Institution(db.Model):
    __tablename__ = 'institutions'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    registration_number = db.Column(db.String(100), unique=True, nullable=False)
    location = db.Column(Geometry(geometry_type='POINT', srid=4326), nullable=False) # Store as PostGIS Point
    rtsp_url = db.Column(db.String(255), nullable=True)
    admin_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True) # NGO Admin

class Assignment(db.Model):
    __tablename__ = 'assignments'
    id = db.Column(db.Integer, primary_key=True)
    inspector_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    institution_id = db.Column(db.Integer, db.ForeignKey('institutions.id'), nullable=False)
    scheduled_date = db.Column(db.Date, nullable=False)
    status = db.Column(db.String(20), default='Pending') # Pending, Completed, Missed
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class InspectionLog(db.Model):
    __tablename__ = 'inspection_logs'
    id = db.Column(db.Integer, primary_key=True)
    assignment_id = db.Column(db.Integer, db.ForeignKey('assignments.id'), nullable=False)
    inspector_gps = db.Column(Geometry(geometry_type='POINT', srid=4326), nullable=False)
    distance_from_centroid = db.Column(db.Float, nullable=False) # In meters
    evidence_hash = db.Column(db.String(64), nullable=False) # SHA-256 hash
    capture_time = db.Column(db.DateTime, nullable=False) # EXIF time
    status = db.Column(db.String(20), nullable=False) # Accepted, Rejected
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Anomaly(db.Model):
    __tablename__ = 'anomalies'
    id = db.Column(db.Integer, primary_key=True)
    inspection_id = db.Column(db.Integer, db.ForeignKey('inspection_logs.id'), nullable=False)
    anomaly_type = db.Column(db.String(50), nullable=False) # e.g., 'Proxy', 'Crowd'
    risk_score = db.Column(db.Float, nullable=False) # 0.0 to 1.0
    shap_explanation = db.Column(db.JSON, nullable=True)
    reviewer_action = db.Column(db.String(50), default='Pending') # Validated, False Positive
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
