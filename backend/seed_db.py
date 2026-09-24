from app import create_app
from app.models import db, Role, User, Institution
from app import bcrypt

app = create_app()

with app.app_context():
    # Ensure roles exist
    for role_name in ['DoSJE_Official', 'PMU_Inspector', 'NGO_Admin']:
        if not Role.query.filter_by(name=role_name).first():
            db.session.add(Role(name=role_name))
    db.session.commit()

    ngo_admin_role = Role.query.filter_by(name='NGO_Admin').first()
    
    ngos_data = [
        {"name": "NGO 1", "reg": "REG001", "lon": 92.727786, "lat": 23.793067, "rtsp": "rtsp://localhost:8554/ngo_1"},
        {"name": "NGO 2", "reg": "REG002", "lon": 92.720840, "lat": 23.748473, "rtsp": "rtsp://localhost:8554/ngo_2"},
        {"name": "NGO 3", "reg": "REG003", "lon": 92.72739487729815, "lat": 23.7519177223219, "rtsp": "rtsp://localhost:8554/ngo_3"},
    ]
    
    for idx, ngo_info in enumerate(ngos_data):
        username = f"ngo{idx+1}_admin"
        email = f"{username}@example.com"
        
        user = User.query.filter_by(email=email).first()
        if not user:
            hashed = bcrypt.generate_password_hash('password123').decode('utf-8')
            user = User(username=username, email=email, password_hash=hashed, role_id=ngo_admin_role.id)
            db.session.add(user)
            db.session.commit()
            
        inst = Institution.query.filter_by(registration_number=ngo_info["reg"]).first()
        if not inst:
            point = f"SRID=4326;POINT({ngo_info['lon']} {ngo_info['lat']})"
            inst = Institution(name=ngo_info["name"], registration_number=ngo_info["reg"], location=point, rtsp_url=ngo_info["rtsp"], admin_id=user.id)
            db.session.add(inst)
            db.session.commit()
            
    print("Seeding complete.")
