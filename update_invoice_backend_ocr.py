import os

dao_path = r'd:\oussema\Projet pfa\backend\dao\invoice_dao.py'
routes_path = r'd:\oussema\Projet pfa\backend\routes\invoice_routes.py'

dao_code = '''from dbConnection import get_connection

def create_invoice(supplier_id, created_by, items):
    """items = [{product_id, qty_requested}, ...]"""
    conn = get_connection()
    cursor = conn.cursor()
    query = """
    INSERT INTO purchase_invoices (supplier_id, created_by, status) 
    OUTPUT INSERTED.id
    VALUES (?, ?, 'pending')
    """
    cursor.execute(query, (supplier_id, created_by))
    invoice_id = cursor.fetchone()[0]

    for item in items:
        query = """
        INSERT INTO purchase_invoice_items (invoice_id, product_id, qty_requested)
        VALUES (?, ?, ?)    
        """
        cursor.execute(query, (invoice_id, item['product_id'], item['qty_requested']))

    conn.commit()
    cursor.close()
    conn.close()
    return invoice_id


def get_all_invoices_for_employee(status=None):
    conn = get_connection()
    cursor = conn.cursor()
    
    where_clauses = ["1=1"]
    params = []

    if status and status.lower() != 'all':
        where_clauses.append("LOWER(i.status) = ?")
        params.append(status.lower())

    where_sql = " AND ".join(where_clauses)

    query = f"""
        SELECT 
            i.id, 
            i.supplier_id, 
            i.created_by,
            COALESCE(u.prenom + ' ' + u.nom, u.id_user, 'Employee') AS employee_name,
            COALESCE(sup.prenom + ' ' + sup.nom, sup.id_user, i.supplier_id) AS supplier_name,
            i.status, 
            i.rejection_reason, 
            i.created_at,
            COUNT(pi.id) AS products_count,
            COALESCE(SUM(pi.qty_requested), 0) AS total_qty
        FROM purchase_invoices i
        LEFT JOIN users u ON i.created_by = u.id_user
        LEFT JOIN users sup ON i.supplier_id = sup.id_user
        LEFT JOIN purchase_invoice_items pi ON i.id = pi.invoice_id
        WHERE {where_sql}
        GROUP BY i.id, i.supplier_id, i.created_by, u.nom, u.prenom, u.id_user, sup.nom, sup.prenom, sup.id_user, i.status, i.rejection_reason, i.created_at
        ORDER BY i.created_at DESC
    """
    cursor.execute(query, params)
    columns = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    invoices = [dict(zip(columns, row)) for row in rows]
    cursor.close()
    conn.close()
    return invoices


def get_invoices_for_supplier(supplier_id, status=None):
    conn = get_connection()
    cursor = conn.cursor()
    
    where_clauses = ["i.supplier_id = ?"]
    params = [supplier_id]

    if status and status.lower() != 'all':
        where_clauses.append("LOWER(i.status) = ?")
        params.append(status.lower())

    where_sql = " AND ".join(where_clauses)

    query = f"""
        SELECT 
            i.id, 
            i.supplier_id, 
            i.created_by,
            COALESCE(u.prenom + ' ' + u.nom, u.id_user, 'Employee') AS employee_name,
            COALESCE(sup.prenom + ' ' + sup.nom, sup.id_user, i.supplier_id) AS supplier_name,
            i.status, 
            i.rejection_reason, 
            i.created_at,
            COUNT(pi.id) AS products_count,
            COALESCE(SUM(pi.qty_requested), 0) AS total_qty
        FROM purchase_invoices i
        LEFT JOIN users u ON i.created_by = u.id_user
        LEFT JOIN users sup ON i.supplier_id = sup.id_user
        LEFT JOIN purchase_invoice_items pi ON i.id = pi.invoice_id
        WHERE {where_sql}
        GROUP BY i.id, i.supplier_id, i.created_by, u.nom, u.prenom, u.id_user, sup.nom, sup.prenom, sup.id_user, i.status, i.rejection_reason, i.created_at
        ORDER BY i.created_at DESC
    """
    cursor.execute(query, params)
    columns = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    invoices = [dict(zip(columns, row)) for row in rows]
    cursor.close()
    conn.close()
    return invoices


def get_invoice_detail(invoice_id):
    conn = get_connection()
    cursor = conn.cursor()
    
    header_query = """
        SELECT i.id, i.supplier_id, i.created_by,
               COALESCE(u.prenom + ' ' + u.nom, u.id_user) AS employee_name,
               COALESCE(sup.prenom + ' ' + sup.nom, sup.id_user) AS supplier_name,
               sup.teleph AS supplier_phone,
               i.status, i.rejection_reason, i.created_at
        FROM purchase_invoices i
        LEFT JOIN users u ON i.created_by = u.id_user
        LEFT JOIN users sup ON i.supplier_id = sup.id_user
        WHERE i.id = ?
    """
    cursor.execute(header_query, (invoice_id,))
    row = cursor.fetchone()
    if not row:
        cursor.close()
        conn.close()
        return None

    columns = [c[0] for c in cursor.description]
    invoice = dict(zip(columns, row))

    items_query = """
        SELECT pi.id, pi.product_id, p.name AS product_name, p.image_url,
               p.category, p.price, pi.qty_requested, pi.qty_confirmed
        FROM purchase_invoice_items pi
        LEFT JOIN products p ON pi.product_id = p.id
        WHERE pi.invoice_id = ?
    """
    cursor.execute(items_query, (invoice_id,))
    item_cols = [c[0] for c in cursor.description]
    item_rows = cursor.fetchall()
    items = [dict(zip(item_cols, r)) for r in item_rows]

    invoice["items"] = items

    delivery_query = """
        SELECT id, pdf_path, delivery_date, note, uploaded_at
        FROM deliveries
        WHERE invoice_id = ?
        ORDER BY uploaded_at DESC
    """
    cursor.execute(delivery_query, (invoice_id,))
    del_cols = [c[0] for c in cursor.description]
    del_row = cursor.fetchone()
    if del_row:
        invoice["delivery"] = dict(zip(del_cols, del_row))
    else:
        invoice["delivery"] = None

    cursor.close()
    conn.close()
    return invoice


def confirm_invoice(invoice_id, items_confirmed):
    conn = get_connection()
    cursor = conn.cursor()

    for item in items_confirmed:
        query = "UPDATE purchase_invoice_items SET qty_confirmed = ? WHERE id = ?"
        qty = item.get('qty_confirmed') if item.get('qty_confirmed') is not None else item.get('qty_requested')
        cursor.execute(query, (qty, item['id']))

    cursor.execute("UPDATE purchase_invoices SET status = 'confirmed' WHERE id = ?", (invoice_id,))

    conn.commit()
    cursor.close()
    conn.close()
    return True


def reject_invoice(invoice_id, rejection_reason=None):
    conn = get_connection()
    cursor = conn.cursor()
    query = "UPDATE purchase_invoices SET status = 'rejected', rejection_reason = ? WHERE id = ?"
    cursor.execute(query, (rejection_reason, invoice_id))
    conn.commit()
    cursor.close()
    conn.close()
    return True


def create_delivery(invoice_id, pdf_path, delivery_date=None, note=None):
    conn = get_connection()
    cursor = conn.cursor()
    query = """
    INSERT INTO deliveries (invoice_id, pdf_path, delivery_date, note)
    OUTPUT INSERTED.id
    VALUES (?, ?, ?, ?)
    """
    cursor.execute(query, (invoice_id, pdf_path, delivery_date, note))
    delivery_id = cursor.fetchone()[0]

    cursor.execute("UPDATE purchase_invoices SET status = 'shipped' WHERE id = ?", (invoice_id,))

    conn.commit()
    cursor.close()
    conn.close()
    return delivery_id


def reconcile_invoice_stock(invoice_id, items_received):
    """items_received = [{'product_id': 123, 'qty_received': 15}, ...]"""
    conn = get_connection()
    cursor = conn.cursor()

    for item in items_received:
        p_id = item.get('product_id')
        qty_rec = int(item.get('qty_received', 0))
        if p_id and qty_rec > 0:
            cursor.execute("UPDATE products SET stock = stock + ? WHERE id = ?", (qty_rec, p_id))

    cursor.execute("UPDATE purchase_invoices SET status = 'completed' WHERE id = ?", (invoice_id,))
    conn.commit()
    cursor.close()
    conn.close()
    return True


def get_supplier_stats(supplier_id):
    conn = get_connection()
    cursor = conn.cursor()

    query = """
    SELECT 
        SUM(CASE WHEN LOWER(status) = 'pending' THEN 1 ELSE 0 END) AS pending_count,
        SUM(CASE WHEN LOWER(status) = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_count,
        SUM(CASE WHEN LOWER(status) IN ('shipped', 'completed') THEN 1 ELSE 0 END) AS shipped_count,
        COUNT(*) AS total_count
    FROM purchase_invoices
    WHERE supplier_id = ?
    """
    cursor.execute(query, (supplier_id,))
    row = cursor.fetchone()
    
    stats = {
        "pending": row[0] or 0 if row else 0,
        "confirmed": row[1] or 0 if row else 0,
        "shipped": row[2] or 0 if row else 0,
        "total": row[3] or 0 if row else 0
    }
    
    cursor.close()
    conn.close()
    return stats
'''

routes_code = '''import os
from flask import Blueprint, request, jsonify, send_file
from werkzeug.utils import secure_filename
from dao.invoice_dao import (
    create_invoice, 
    get_invoices_for_supplier, 
    get_all_invoices_for_employee,
    get_invoice_detail, 
    confirm_invoice, 
    reject_invoice, 
    create_delivery, 
    reconcile_invoice_stock,
    get_supplier_stats
)
from utils.pdf_generator import generate_delivery_receipt_pdf
from utils.ocr_service import extract_delivery_receipt_data

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
    
    if not invoice_id:
        return jsonify({"success": False, "message": "invoice_id is required"}), 400

    # Auto-generate PDF Receipt if no custom file provided
    inv_detail = get_invoice_detail(int(invoice_id))
    save_name = f"invoice_{invoice_id}_receipt.pdf"
    pdf_dest = os.path.join(UPLOAD_FOLDER, save_name)
    
    if inv_detail:
        generate_delivery_receipt_pdf(pdf_dest, inv_detail)

    pdf_path = f"/static/deliveries/{save_name}"
    delivery_date = data.get('delivery_date')
    note = data.get('note', '')

    delivery_id = create_delivery(int(invoice_id), pdf_path, delivery_date, note)
    return jsonify({"success": True, "delivery_id": delivery_id, "pdf_path": pdf_path}), 201


@invoice_bp.route("/<int:invoice_id>/verify-ocr", methods=["POST"])
def verify_ocr(invoice_id):
    invoice = get_invoice_detail(invoice_id)
    if not invoice:
        return jsonify({"success": False, "message": "Invoice not found"}), 404

    delivery = invoice.get('delivery')
    pdf_path = None
    if delivery and delivery.get('pdf_path'):
        raw_p = delivery['pdf_path']
        if raw_p.startswith('/static/'):
            raw_p = raw_p[len('/static/'):]
        pdf_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'static', raw_p)

    # Auto-generate PDF receipt if not present on disk
    if not pdf_path or not os.path.exists(pdf_path):
        save_name = f"invoice_{invoice_id}_receipt.pdf"
        pdf_path = os.path.join(UPLOAD_FOLDER, save_name)
        generate_delivery_receipt_pdf(pdf_path, invoice)

    ocr_result = extract_delivery_receipt_data(pdf_path)
    
    # Compare OCR results with database invoice items
    db_items = invoice.get('items', [])
    comparison_items = []
    discrepancy_found = False

    for item in db_items:
        p_name = item['product_name'].lower().strip()
        q_ord = item['qty_requested']
        q_conf = item.get('qty_confirmed') if item.get('qty_confirmed') is not None else q_ord

        # Find matching OCR item
        match_ocr = None
        for ocr_i in ocr_result.get('items', []):
            if ocr_i['product_name'].lower().strip() in p_name or p_name in ocr_i['product_name'].lower().strip():
                match_ocr = ocr_i
                break

        qty_ocr = match_ocr['qty_delivered'] if match_ocr else q_conf
        discrepancy = qty_ocr - q_ord
        if discrepancy < 0:
            discrepancy_found = True

        comparison_items.append({
            "product_id": item['product_id'],
            "product_name": item['product_name'],
            "image_url": item['image_url'],
            "qty_ordered": q_ord,
            "qty_confirmed": q_conf,
            "qty_ocr_detected": qty_ocr,
            "discrepancy": discrepancy,
            "has_discrepancy": discrepancy < 0,
            "note": match_ocr['note'] if match_ocr else ("" if discrepancy >= 0 else f"Backorder {abs(discrepancy)}")
        })

    pdf_url = f"/static/deliveries/invoice_{invoice_id}_receipt.pdf"

    return jsonify({
        "success": True,
        "invoice_id": invoice_id,
        "receipt_no": ocr_result.get('receipt_no', f"BL-2026-{invoice_id:04d}"),
        "pdf_url": pdf_url,
        "discrepancy_found": discrepancy_found,
        "comparison_items": comparison_items,
        "raw_ocr": ocr_result
    }), 200


@invoice_bp.route("/<int:invoice_id>/reconcile-stock", methods=["POST"])
def reconcile_stock(invoice_id):
    data = request.get_json() or {}
    items = data.get("items", [])
    if not items:
        return jsonify({"success": False, "message": "No items provided for stock reconciliation"}), 400

    reconcile_invoice_stock(invoice_id, items)
    return jsonify({"success": True, "message": "Stock reconciled successfully and invoice marked completed"}), 200
'''

with open(dao_path, 'w', encoding='utf-8') as f:
    f.write(dao_code)
print("Updated invoice_dao.py for OCR & reconciliation")

with open(routes_path, 'w', encoding='utf-8') as f:
    f.write(routes_code)
print("Updated invoice_routes.py for OCR & reconciliation")
