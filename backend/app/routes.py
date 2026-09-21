from flask import Blueprint, jsonify, request
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from .models import db, User, Role, Assignment, Institution, InspectionLog, Anomaly
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

@bp.route('/api/anomalies', methods=['GET'])
def get_anomalies():
    """Fetch real anomalies from DB, fall back to demo data if none exist yet."""
    real_anomalies = Anomaly.query.order_by(Anomaly.created_at.desc()).limit(20).all()

    if real_anomalies:
        result = []
        for a in real_anomalies:
            shap = []
            if a.shap_explanation and 'feature_contributions' in a.shap_explanation:
                for feat, impact in a.shap_explanation['feature_contributions'].items():
                    impact_pct = int(impact * 100) if isinstance(impact, float) and impact <= 1.0 else int(impact)
                    color = "bg-red-500" if impact_pct >= 50 else "bg-orange-400"
                    shap.append({"feature": feat, "impact": impact_pct, "color": color})
            result.append({
                "id": a.id,
                "ngo": f"NGO (Inspection #{a.inspection_id})",
                "type": a.anomaly_type,
                "score": round(a.risk_score, 2),
                "time": a.created_at.strftime('%d %b %Y, %H:%M UTC') if a.created_at else "N/A",
                "shap": shap,
                "reviewer_action": a.reviewer_action,
            })
        return jsonify(result), 200

    # Demo seed data (shown before any real inspections are processed)
    mock_anomalies = [
        {
            "id": 101,
            "ngo": "Bright Future Institute",
            "type": "Proxy Beneficiary Detected",
            "score": 0.92,
            "time": "10 mins ago",
            "shap": [
                { "feature": "L2 Face Distance", "impact": 85, "color": "bg-red-500" },
                { "feature": "Facial Landmarks", "impact": 15, "color": "bg-orange-400" }
            ]
        },
        {
            "id": 102,
            "ngo": "Skill India Hub - Delhi",
            "type": "Crowd Size Discrepancy",
            "score": 0.84,
            "time": "2 hours ago",
            "shap": [
                { "feature": "Density Map Count (20)", "impact": 70, "color": "bg-red-500" },
                { "feature": "Reported Attendance (55)", "impact": 30, "color": "bg-orange-400" }
            ]
        }
    ]

from .utils import verify_hash, get_exif_datetime, verify_timestamp
from sqlalchemy import func

@bp.route('/api/evidence/submit', methods=['POST'])
@jwt_required()
def submit_evidence():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    if user.role.name != 'PMU_Inspector':
        return jsonify({"msg": "Unauthorized. Only PMU Inspectors can submit evidence."}), 403

    # Parse request data
    assignment_id = request.form.get('assignment_id')
    submitted_hash = request.form.get('evidence_hash')
    inspector_lat = request.form.get('latitude')
    inspector_lon = request.form.get('longitude')
    
    if 'media' not in request.files:
        return jsonify({"msg": "No media file provided."}), 400
        
    media_file = request.files['media']
    file_bytes = media_file.read()

    # 1. Zero-Trust Check: Cryptographic Hash
    if not verify_hash(file_bytes, submitted_hash):
        return jsonify({"msg": "Evidence rejected: Media payload has been tampered with or corrupted in transit.", "error_code": "HASH_MISMATCH"}), 403

    # 2. Zero-Trust Check: EXIF Timestamp Validation
    exif_datetime = get_exif_datetime(file_bytes)
    if not verify_timestamp(exif_datetime):
        return jsonify({"msg": "Evidence rejected: EXIF timestamp is missing or deviates more than 30 seconds from server UTC (Potential pre-captured image).", "error_code": "TIMESTAMP_VIOLATION"}), 403

    # 3. Zero-Trust Check: Haversine Geo-fence
    assignment = Assignment.query.get(assignment_id)
    if not assignment or assignment.inspector_id != current_user_id:
        return jsonify({"msg": "Invalid assignment."}), 400
        
    institution = Institution.query.get(assignment.institution_id)
    
    # Construct PostGIS Point for inspector
    inspector_point = f'SRID=4326;POINT({inspector_lon} {inspector_lat})'
    
    # Query database to calculate distance using ST_DistanceSphere (returns meters)
    distance_query = db.session.query(
        func.ST_DistanceSphere(
            func.ST_GeomFromEWKT(inspector_point), 
            institution.location
        ).label('distance')
    ).first()
    
    distance = distance_query.distance if distance_query else float('inf')
    
    if distance > 200:
        return jsonify({"msg": f"Evidence rejected: Inspector is {distance:.2f} meters away. Must be within 200 meters of the institution.", "error_code": "GEOFENCE_VIOLATION"}), 403

    # If all checks pass, save to Object Store (placeholder for S3 upload) and save log to DB
    log = InspectionLog(
        assignment_id=assignment_id,
        inspector_gps=inspector_point,
        distance_from_centroid=distance,
        evidence_hash=submitted_hash,
        capture_time=exif_datetime,
        status='Accepted'
    )
    
    db.session.add(log)
    db.session.commit()

    # Trigger async AI Analytics here (Celery task placeholder)
    from .tasks import process_evidence
    process_evidence.delay(log.id)

    return jsonify({"msg": "Evidence accepted, verified, and sent to AI pipeline for review", "distance_meters": distance}), 202

import os
from livekit import api

@bp.route('/api/livekit/token', methods=['GET'])
@jwt_required()
def get_livekit_token():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    room_name = request.args.get('room', 'command_centre')
    
    # We allow both Admin and Inspectors, or maybe just DoSJE officials?
    if user.role.name not in ['DoSJE_Official', 'NGO_Admin', 'PMU_Inspector']:
        return jsonify({"msg": "Unauthorized"}), 403

    # Generate token using livekit-api
    token = api.AccessToken(os.getenv('LIVEKIT_API_KEY', 'devkey'), os.getenv('LIVEKIT_API_SECRET', 'secret'))
    token = token.with_identity(f"{user.username}_{user.id}").with_name(user.username)
    token = token.with_grants(api.VideoGrants(
        room_join=True,
        room=room_name,
        can_publish=True,
        can_subscribe=True
    ))

    return jsonify({"token": token.to_jwt()}), 200
