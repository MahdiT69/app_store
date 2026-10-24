# pyrefly: ignore [missing-import]
from flask import Blueprint, request, jsonify
from dao.auth_dao import check_login

auth_bp = Blueprint("auth", __name__)

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    id_user = data.get('id_user')
    pw_user = data.get('pw_user')
    
    if not id_user or not pw_user:
        return jsonify({"error": "Missing username or password"}), 400
    
    user = check_login(id_user, pw_user)
    
    if user:
        return jsonify({"success": True, "user": user}), 200
    else:
        return jsonify({"success": False, "message": "Invalid credentials"}), 401