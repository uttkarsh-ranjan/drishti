from flask import Blueprint, jsonify, request
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from .models import db, User, Role
from . import bcrypt

bp = Blueprint('main', __name__)

@bp.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "Drishti API Gateway"}), 200

@bp.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    role_name = data.get('role', 'NGO_Admin') # Default role

    if User.query.filter_by(email=email).first():
        return jsonify({"msg": "Email already exists"}), 400

    role = Role.query.filter_by(name=role_name).first()
    if not role:
        role = Role(name=role_name)
        db.session.add(role)
        db.session.commit()

    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
    new_user = User(username=username, email=email, password_hash=hashed_password, role_id=role.id)
    
    db.session.add(new_user)
    db.session.commit()

    return jsonify({"msg": "User created successfully"}), 201

@bp.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    user = User.query.filter_by(email=email).first()
    if user and bcrypt.check_password_hash(user.password_hash, password):
        access_token = create_access_token(identity=user.id)
        return jsonify(access_token=access_token, role=user.role.name), 200

    return jsonify({"msg": "Bad email or password"}), 401

@bp.route('/api/assignments', methods=['GET'])
@jwt_required()
def get_assignments():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    if user.role.name != 'PMU_Inspector':
        return jsonify({"msg": "Unauthorized"}), 403

    # Placeholder for fetching assignments from DB
    assignments = [
        {"id": 1, "institution": "Sample NGO", "date": "2026-10-01", "status": "Pending"}
    ]
    return jsonify(assignments), 200

@bp.route('/api/evidence/submit', methods=['POST'])
@jwt_required()
def submit_evidence():
    # In a real scenario, handle multipart form data containing image/video, 
    # check EXIF, verify hash, and calculate Haversine distance via PostGIS.
    return jsonify({"msg": "Evidence accepted and sent to AI pipeline for review"}), 202
