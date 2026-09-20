from flask import Flask
from flask_jwt_extended import JWTManager
from flask_bcrypt import Bcrypt
from flask_cors import CORS
from .config import Config
from .models import db
from .celery_app import init_celery, celery

bcrypt = Bcrypt()
jwt = JWTManager()
cors = CORS()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize extensions
    db.init_app(app)
    bcrypt.init_app(app)
    jwt.init_app(app)
    cors.init_app(app)

    
    # Initialize Celery
    init_celery(app)

    # Create tables (for development only, use migrations in production)
    with app.app_context():
        # db.create_all() # Uncomment when PostGIS is fully available to create tables
        pass

    # Register blueprints
    from .routes import bp as main_bp
    app.register_blueprint(main_bp)

    return app
