import os
from flask import Blueprint, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename
from dao.invoice_dao import (
    create_invoice, 
    get_invoices_for_supplier, 
    get_all_invoices_for_employee,
    get_invoice_detail, 
    confirm_invoice, 
    reject_invoice, 
    create_delivery, 
    get_supplier_stats,
    get_invoice_ocr_verification,
    reconcile_stock_and_complete,
    ensure_delivery_pdf_exists
)

invoice_bp = Blueprint("invoices", __name__)

UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'static', 'deliveries')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@invoice_bp.route("/", methods=["POST"])
def add_invoice():
    data = request.get_json()
    supplier_id = data.get("supplier_id")
    created_by = data.get("created_by")
    items = data.get("items", [])

    if not supplier_id or not created_by or not items:
        return jsonify({"success": False, "message": "Missing required fields"}), 400

    invoice_id = create_invoice(supplier_id, created_by, items)
    return jsonify({"success": True, "invoice_id": invoice_id}), 201


@invoice_bp.route("/all", methods=["GET"])
def list_all_invoices():
    status = request.args.get("status", "all")
    invoices = get_all_invoices_for_employee(status)
    return jsonify({"success": True, "invoices": invoices}), 200


@invoice_bp.route("/supplier/<supplier_id>", methods=["GET"])
def list_supplier_invoices(supplier_id):
    status = request.args.get("status", "all")
    invoices = get_invoices_for_supplier(supplier_id, status)
    return jsonify({"success": True, "invoices": invoices}), 200


@invoice_bp.route("/supplier/<supplier_id>/stats", methods=["GET"])
def supplier_stats(supplier_id):
    stats = get_supplier_stats(supplier_id)
    return jsonify({"success": True, "stats": stats}), 200


@invoice_bp.route("/<int:invoice_id>", methods=["GET"])
def invoice_detail(invoice_id):
    invoice = get_invoice_detail(invoice_id)
    if not invoice:
        return jsonify({"success": False, "message": "Invoice not found"}), 404
    return jsonify({"success": True, "invoice": invoice}), 200


@invoice_bp.route("/<int:invoice_id>/confirm", methods=["PUT"])
def confirm(invoice_id):
    data = request.get_json() or {}
    items = data.get("items", [])
    confirm_invoice(invoice_id, items)
    return jsonify({"success": True, "message": "Invoice confirmed successfully"}), 200


@invoice_bp.route("/<int:invoice_id>/reject", methods=["PUT"])
def reject(invoice_id):
    data = request.get_json() or {}
    reason = data.get("reason", "").strip()
    reject_invoice(invoice_id, reason)
    return jsonify({"success": True, "message": "Invoice rejected"}), 200


@invoice_bp.route("/<int:invoice_id>/verify-ocr", methods=["POST"])
def verify_ocr(invoice_id):
    res = get_invoice_ocr_verification(invoice_id)
    return jsonify(res), 200 if res.get('success') else 400


@invoice_bp.route("/<int:invoice_id>/reconcile-stock", methods=["POST"])
def reconcile_stock(invoice_id):
    data = request.get_json() or {}
    items = data.get("items", [])
    reconcile_stock_and_complete(invoice_id, items)
    return jsonify({"success": True, "message": "Stock reconciled and invoice marked as completed"}), 200


@invoice_bp.route("/deliveries", methods=["POST"])
def add_delivery():
    if 'file' in request.files:
        file = request.files['file']
        invoice_id = request.form.get('invoice_id')
        delivery_date = request.form.get('delivery_date')
        note = request.form.get('note', '')

        if not invoice_id:
            return jsonify({"success": False, "message": "invoice_id is required"}), 400

        filename = secure_filename(file.filename or 'receipt.pdf')
        if not filename.endswith('.pdf'):
            filename += '.pdf'
        
        save_name = f"invoice_{invoice_id}_{filename}"
        file_path = os.path.join(UPLOAD_FOLDER, save_name)
        file.save(file_path)
        
        pdf_path = f"/static/deliveries/{save_name}"
        delivery_id = create_delivery(int(invoice_id), pdf_path, delivery_date, note)
        return jsonify({"success": True, "delivery_id": delivery_id, "pdf_path": pdf_path}), 201

    data = request.get_json() or {}
    invoice_id = data.get('invoice_id')
    pdf_path = data.get('pdf_path', '/static/deliveries/default_receipt.pdf')
    delivery_date = data.get('delivery_date')
    note = data.get('note', '')

    if not invoice_id:
        return jsonify({"success": False, "message": "invoice_id is required"}), 400

    delivery_id = create_delivery(int(invoice_id), pdf_path, delivery_date, note)
    return jsonify({"success": True, "delivery_id": delivery_id, "pdf_path": pdf_path}), 201
