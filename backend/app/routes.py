from flask import Blueprint, jsonify

bp = Blueprint('main', __name__)

@bp.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "Drishti API Gateway"}), 200
