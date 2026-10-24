# pyrefly: ignore [missing-import]
from flask import Blueprint, request, jsonify
from dao.user_dao import get_user_by_id, update_user, update_password, get_suppliers

user_bp = Blueprint("users", __name__)

@user_bp.route("/<id_user>", methods=["GET"])
def get_user(id_user):
    user = get_user_by_id(id_user)
    if user:
        return jsonify({"success": True, "user": user}), 200
    return jsonify({"success": False, "message": "User not found"}), 404


@user_bp.route("/<id_user>", methods=["PUT"])
def edit_user(id_user):
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify({"success": False, "message": "A JSON object is required"}), 400

    full_name = data.get("full_name", data.get("nom"))
    phone = data.get("phone", data.get("teleph"))
    if full_name is None and phone is None:
        return jsonify({"success": False, "message": "Provide full_name or phone"}), 400

    updated = update_user(id_user, full_name, phone)
    if updated:
        user = get_user_by_id(id_user)
        return jsonify({"success": True, "user": user}), 200
    return jsonify({"success": False, "message": "No changes made or user not found"}), 400


@user_bp.route("/<id_user>/password", methods=["PUT"])
def change_password(id_user):
    data = request.get_json()
    new_pw_user = data.get("new_pw_user")

    if not new_pw_user:
        return jsonify({"success": False, "message": "Password is required"}), 400

    updated = update_password(id_user, new_pw_user)
    if updated:
        return jsonify({"success": True, "message": "Password updated"}), 200
    return jsonify({"success": False, "message": "Update failed"}), 400

@user_bp.route("/suppliers", methods=["GET"])
def list_suppliers():
    suppliers = get_suppliers()
    return jsonify({"success": True, "suppliers": suppliers}), 200
