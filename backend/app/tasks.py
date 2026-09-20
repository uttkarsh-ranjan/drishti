import random
import time
from datetime import datetime, timedelta
from .celery_app import celery
from .models import db, User, Institution, Assignment, InspectionLog, Anomaly, Role
from sqlalchemy import func

# --- MODULE D: AI Anomaly Detection Pipeline ---

@celery.task(bind=True)
def process_evidence(self, log_id, file_path_or_bytes=None):
    """
    Asynchronously processes submitted evidence using the AI pipeline (Module D).
    """
    log = InspectionLog.query.get(log_id)
    if not log:
        return {"status": "error", "msg": "Inspection log not found"}

    # Mocking AI Inference times and logic
    # In production, this would call PyTorch / OpenCV models directly
    
    time.sleep(2) # Simulate processing time

    # 1. Crowd & Attendance Estimation (MobileNetV3-Small mock)
    # Alerts if |Estimated - Reported| / Reported > 0.25
    crowd_discrepancy = random.random() # Mock discrepancy ratio
    
    if crowd_discrepancy > 0.25:
        anomaly1 = Anomaly(
            inspection_id=log.id,
            anomaly_type='Crowd Size Discrepancy',
            risk_score=min(crowd_discrepancy + 0.3, 1.0),
            shap_explanation={"feature_contributions": {"crowd_density_map": 0.8, "reported_attendance": 0.2}}
        )
        db.session.add(anomaly1)

    # 2. Proxy Beneficiary Detection (dlib ResNet mock)
    # L2 distance < 0.45 threshold
    proxy_detected = random.choice([True, False, False, False]) # 25% chance for mock
    
    if proxy_detected:
        anomaly2 = Anomaly(
            inspection_id=log.id,
            anomaly_type='Proxy Beneficiary Detected',
            risk_score=0.92,
            shap_explanation={"feature_contributions": {"l2_face_distance": 0.95, "facial_landmarks": 0.05}}
        )
        db.session.add(anomaly2)

    db.session.commit()
    return {"status": "success", "log_id": log_id, "anomalies_found": int(crowd_discrepancy > 0.25) + int(proxy_detected)}


# --- MODULE B: Constraint-Satisfaction Assignment Engine ---

@celery.task(bind=True)
def generate_daily_assignments(self):
    """
    Weighted Constraint-Satisfaction Problem (WCSP) Engine for routing.
    Runs as a daily cron job to assign PMU Inspectors to NGOs without predictability.
    """
    # Fetch all PMU Inspectors and Institutions
    pmu_role = Role.query.filter_by(name='PMU_Inspector').first()
    if not pmu_role:
        return {"status": "error", "msg": "Role PMU_Inspector not found"}
        
    inspectors = User.query.filter_by(role_id=pmu_role.id).all()
    institutions = Institution.query.all()
    
    if not inspectors or not institutions:
        return {"status": "skipped", "msg": "No inspectors or institutions available"}

    assignments_created = []
    
    # Constants for Eq 2 from the report
    ALPHA = 0.4  # Distance weight
    BETA = 0.3   # Workload weight
    GAMMA = 0.3  # Repetition penalty weight
    SIGMA = 5.0  # Noise variance
    
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    
    for ngo in institutions:
        best_inspector = None
        min_cost = float('inf')
        
        for inspector in inspectors:
            # 1. Geodesic distance (d) - In a real setup, we need the inspector's home base or current location.
            # For the mock, we assume a random distance or query if we track base locations.
            d_i_n = random.uniform(1, 50) # Mock distance in km
            
            # 2. Workload count (w) - Active assignments today
            w_i = Assignment.query.filter(
                Assignment.inspector_id == inspector.id, 
                func.date(Assignment.scheduled_date) == datetime.utcnow().date()
            ).count()
            
            # 3. Repetition penalty (h) - Assigned to this NGO within 30 days
            recent_assignment = Assignment.query.filter(
                Assignment.inspector_id == inspector.id,
                Assignment.institution_id == ngo.id,
                Assignment.scheduled_date >= thirty_days_ago
            ).first()
            
            h_i_n = 1 if recent_assignment else 0
            
            # 4. Random noise (epsilon)
            epsilon_i = random.uniform(0, SIGMA)
            
            # Weighted CSP Cost Function (Eq 2)
            # Cost = alpha*d + beta*w + gamma*h + epsilon
            # Note: We ADD gamma*h because repetition is bad (higher cost).
            cost = (ALPHA * d_i_n) + (BETA * w_i) + (GAMMA * h_i_n * 100) + epsilon_i
            
            if cost < min_cost:
                min_cost = cost
                best_inspector = inspector
                
        if best_inspector:
            new_assignment = Assignment(
                inspector_id=best_inspector.id,
                institution_id=ngo.id,
                scheduled_date=datetime.utcnow().date(),
                status='Pending'
            )
            db.session.add(new_assignment)
            assignments_created.append(f"Assigned Inspector {best_inspector.username} to NGO {ngo.name}")
            
    db.session.commit()
    
    # In production, dispatch FCM Push Notifications here!
    
    return {"status": "success", "assignments": assignments_created}
