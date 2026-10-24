from datetime import date

import pyodbc
from flask import Blueprint, jsonify, request

from dao.manager_dao import (
    create_manager_user, get_manager_dashboard, get_manager_invoice, get_manager_users,
)

manager_bp = Blueprint('manager', __name__)


@manager_bp.get('/dashboard')
def dashboard():
    return jsonify(success=True, **get_manager_dashboard()), 200


@manager_bp.get('/invoices/<int:invoice_id>')
def invoice_detail(invoice_id):
    invoice = get_manager_invoice(invoice_id)
    if invoice is None:
        return jsonify(success=False, message='Invoice not found'), 404
    return jsonify(success=True, invoice=invoice), 200


@manager_bp.get('/users')
def users():
    return jsonify(success=True, users=get_manager_users()), 200


@manager_bp.post('/users')
def create_user():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify(success=False, message='A JSON object is required'), 400
    clean = {}
    for field in ('id_user', 'nom', 'prenom', 'pw_user', 'role'):
        value = data.get(field)
        if not isinstance(value, str) or not value.strip():
            return jsonify(success=False, message=f'{field} is required'), 400
        clean[field] = value if field == 'pw_user' else value.strip()
    if clean['role'] not in ('employee', 'supplier'):
        return jsonify(success=False, message='Role must be employee or supplier'), 400
    for field in ('id_user', 'nom', 'prenom', 'pw_user'):
        if len(clean[field]) > 50:
            return jsonify(success=False, message=f'{field} must be at most 50 characters'), 400
    cin = str(data.get('cin', '')).strip()
    if len(cin) != 8 or not cin.isascii() or not cin.isdigit():
        return jsonify(success=False, message='CIN must contain 8 digits'), 400
    clean['cin'] = cin
    phone = data.get('teleph') or ''
    if not isinstance(phone, str) or len(phone.strip()) > 20:
        return jsonify(success=False, message='Phone must be at most 20 characters'), 400
    clean['teleph'] = phone.strip()
    birthday = data.get('date_naiss')
    if birthday:
        try:
            birthday = date.fromisoformat(birthday)
        except (ValueError, TypeError):
            return jsonify(success=False, message='Birth date must use YYYY-MM-DD'), 400
        if birthday > date.today():
            return jsonify(success=False, message='Birth date cannot be in the future'), 400
        birthday = birthday.isoformat()
    clean['date_naiss'] = birthday or None
    try:
        user = create_manager_user(clean)
    except pyodbc.IntegrityError:
        return jsonify(success=False, message='Username or CIN already exists'), 409
    return jsonify(success=True, user=user), 201
