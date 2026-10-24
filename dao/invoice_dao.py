from dbConnection import get_connection
import os
from utils.pdf_generator import generate_delivery_receipt_pdf
from utils.ocr_service import extract_delivery_receipt_data
from datetime import datetime

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
            i.status, 
            i.rejection_reason, 
            i.created_at,
            COUNT(pi.id) AS products_count,
            COALESCE(SUM(pi.qty_requested), 0) AS total_qty
        FROM purchase_invoices i
        LEFT JOIN users u ON i.created_by = u.id_user
        LEFT JOIN purchase_invoice_items pi ON i.id = pi.invoice_id
        WHERE {where_sql}
        GROUP BY i.id, i.supplier_id, i.created_by, u.nom, u.prenom, u.id_user, i.status, i.rejection_reason, i.created_at
        ORDER BY i.created_at DESC
    """
    cursor.execute(query, params)
    columns = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    invoices = [dict(zip(columns, row)) for row in rows]
    cursor.close()
    conn.close()
    return invoices


def get_all_invoices_for_employee(status=None):
    conn = get_connection()
    cursor = conn.cursor()

    where_clauses = []
    params = []

    if status and status.lower() != 'all':
        where_clauses.append("LOWER(i.status) = ?")
        params.append(status.lower())

    where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""

    query = f"""
        SELECT 
            i.id, 
            i.supplier_id,
            COALESCE(sup.prenom + ' ' + sup.nom, sup.id_user, i.supplier_id) AS supplier_name,
            i.created_by,
            COALESCE(u.prenom + ' ' + u.nom, u.id_user, 'Employee') AS employee_name,
            i.status, 
            i.rejection_reason, 
            i.created_at,
            COUNT(pi.id) AS products_count,
            COALESCE(SUM(pi.qty_requested), 0) AS total_qty,
            COALESCE(SUM(COALESCE(pi.qty_confirmed, pi.qty_requested)), 0) AS total_confirmed_qty
        FROM purchase_invoices i
        LEFT JOIN users u ON i.created_by = u.id_user
        LEFT JOIN users sup ON i.supplier_id = sup.id_user
        LEFT JOIN purchase_invoice_items pi ON i.id = pi.invoice_id
        {where_sql}
        GROUP BY i.id, i.supplier_id, sup.prenom, sup.nom, sup.id_user, i.created_by, u.nom, u.prenom, u.id_user, i.status, i.rejection_reason, i.created_at
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
        SELECT i.id, i.supplier_id,
               COALESCE(sup.prenom + ' ' + sup.nom, sup.id_user) AS supplier_name,
               i.created_by,
               COALESCE(u.prenom + ' ' + u.nom, u.id_user) AS employee_name,
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

    cursor.execute("UPDATE purchase_invoices SET status = 'shipped' WHERE id = ?", (invoice_id,))

    conn.commit()
    cursor.close()
    conn.close()

    # Generate Delivery Receipt PDF automatically
    ensure_delivery_pdf_exists(invoice_id)
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


def ensure_delivery_pdf_exists(invoice_id):
    invoice = get_invoice_detail(invoice_id)
    if not invoice:
        return None

    rel_folder = os.path.join('static', 'deliveries')
    abs_folder = os.path.join(os.path.dirname(os.path.dirname(__file__)), rel_folder)
    os.makedirs(abs_folder, exist_ok=True)

    filename = f"invoice_{invoice_id}_receipt.pdf"
    abs_path = os.path.join(abs_folder, filename)
    rel_path = f"/static/deliveries/{filename}"

    # Build PDF items structure
    pdf_items = []
    discrepancy_notes = []
    for idx, item in enumerate(invoice.get('items', []), start=1):
        q_ord = item.get('qty_requested', 0)
        q_del = item.get('qty_confirmed') if item.get('qty_confirmed') is not None else q_ord
        note = ''
        if q_del < q_ord:
            diff = q_ord - q_del
            note = f"Backorder {diff}"
            discrepancy_notes.append(f"{item.get('product_name')}: only {q_del} of {q_ord} available. Remaining {diff} units will follow within 7 days.")

        pdf_items.append({
            'num': idx,
            'name': item.get('product_name', 'Product'),
            'sku': f"PRD-00{item.get('product_id', idx)}",
            'qty_ordered': q_ord,
            'qty_delivered': q_del,
            'note': note
        })

    notes_text = "\n".join(discrepancy_notes) if discrepancy_notes else "Goods travel at supplier's risk until signed for by the receiving party."

    invoice_data = {
        'receipt_no': f"BL-2026-{invoice_id:04d}",
        'invoice_ref': f"INV-{invoice_id:04d}",
        'ship_date': datetime.now(),
        'order_date': datetime.now(),
        'supplier_name': invoice.get('supplier_name', 'Supplier'),
        'supplier_company': 'Distribution Partner',
        'supplier_address': "12 Rue de l'Industrie, Tunis",
        'supplier_contact': '+216 71 000 000 | supplier@shopyme.tn',
        'deliver_to_name': 'ShopYme Warehouse',
        'deliver_to_attn': f"Attn: {invoice.get('employee_name', 'Stock Dept')}",
        'deliver_to_address': 'Zone Industrielle, Tunis',
        'deliver_to_contact': '+216 70 000 000 | stock@shopyme.tn',
        'carrier': 'Express Tunis',
        'packages': '3',
        'tracking': f"TN-{invoice_id}84209",
        'status': 'SHIPPED',
        'items': pdf_items,
        'notes': notes_text
    }

    generate_delivery_receipt_pdf(abs_path, invoice_data)
    create_delivery(invoice_id, rel_path, None, notes_text)
    return abs_path


def get_invoice_ocr_verification(invoice_id):
    invoice = get_invoice_detail(invoice_id)
    if not invoice:
        return {'success': False, 'message': 'Invoice not found'}

    # Ensure PDF exists
    rel_folder = os.path.join('static', 'deliveries')
    abs_folder = os.path.join(os.path.dirname(os.path.dirname(__file__)), rel_folder)
    filename = f"invoice_{invoice_id}_receipt.pdf"
    abs_path = os.path.join(abs_folder, filename)

    if not os.path.exists(abs_path):
        abs_path = ensure_delivery_pdf_exists(invoice_id)

    ocr_result = extract_delivery_receipt_data(abs_path)
    
    # Process item comparison
    db_items = invoice.get('items', [])
    ocr_items = ocr_result.get('items', [])

    comparison = []
    has_any_discrepancy = False

    for idx, item in enumerate(db_items):
        q_ord = item.get('qty_requested', 0)
        q_conf = item.get('qty_confirmed') if item.get('qty_confirmed') is not None else q_ord
        
        # Match by index or product_name
        matched_ocr = None
        if idx < len(ocr_items):
            matched_ocr = ocr_items[idx]
        else:
            for o in ocr_items:
                if item.get('product_name', '').lower() in o.get('product_name', '').lower():
                    matched_ocr = o
                    break

        q_ocr = matched_ocr.get('qty_delivered', q_conf) if matched_ocr else q_conf
        discrepancy = q_ocr - q_ord

        if discrepancy < 0:
            has_any_discrepancy = True

        comparison.append({
            'product_id': item.get('product_id'),
            'product_name': item.get('product_name'),
            'image_url': item.get('image_url'),
            'qty_ordered': q_ord,
            'qty_confirmed': q_conf,
            'qty_ocr_detected': q_ocr,
            'discrepancy': discrepancy,
            'has_discrepancy': discrepancy < 0,
            'note': matched_ocr.get('note', '') if matched_ocr else ''
        })

    return {
        'success': True,
        'invoice_id': invoice_id,
        'receipt_no': ocr_result.get('receipt_no', f"BL-2026-{invoice_id:04d}"),
        'invoice_ref': ocr_result.get('invoice_ref', f"INV-{invoice_id:04d}"),
        'pdf_url': f"/static/deliveries/invoice_{invoice_id}_receipt.pdf",
        'has_discrepancy': has_any_discrepancy,
        'items': comparison,
        'reference_coords': ocr_result.get('reference_coords', [])
    }


def reconcile_stock_and_complete(invoice_id, items_received):
    """items_received = [{product_id: int, qty_received: int}, ...]"""
    conn = get_connection()
    cursor = conn.cursor()

    for item in items_received:
        prod_id = item.get('product_id')
        q_rec = item.get('qty_received', 0)
        if prod_id and q_rec > 0:
            cursor.execute("UPDATE products SET stock = stock + ? WHERE id = ?", (q_rec, prod_id))

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
