from contextlib import contextmanager

from dbConnection import get_connection
from dao.invoice_dao import get_all_invoices_for_employee, get_invoice_detail


@contextmanager
def _database():
    conn = get_connection()
    cursor = conn.cursor()
    try:
        yield conn, cursor
    finally:
        cursor.close()
        conn.close()


def _rows(cursor):
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def get_manager_users():
    with _database() as (_, cursor):
        cursor.execute("""
            SELECT id_user, nom, prenom, cin, date_naiss, teleph, role
            FROM users WHERE role IN ('employee', 'supplier')
            ORDER BY role, nom, prenom
        """)
        return _rows(cursor)


def get_manager_dashboard():
    with _database() as (_, cursor):
        cursor.execute("""
            SELECT id, name, description, category, price, stock, image_url
            FROM products WHERE is_active = 1 ORDER BY name
        """)
        products = _rows(cursor)
    invoices = get_all_invoices_for_employee()
    users = get_manager_users()
    statuses = {}
    for invoice in invoices:
        status = (invoice.get('status') or 'pending').lower()
        statuses[status] = statuses.get(status, 0) + 1
    return {
        'stats': {
            'products': len(products),
            'stock_units': sum(p['stock'] or 0 for p in products),
            'stock_value': sum(float(p['price'] or 0) * (p['stock'] or 0) for p in products),
            'low_stock': sum(1 for p in products if (p['stock'] or 0) <= 10),
            'invoices': len(invoices),
            'invoice_statuses': statuses,
            'employees': sum(1 for u in users if u['role'] == 'employee'),
            'suppliers': sum(1 for u in users if u['role'] == 'supplier'),
        },
        'products': products,
        'invoices': invoices,
        'users': users,
    }


def get_manager_invoice(invoice_id):
    return get_invoice_detail(invoice_id)


def create_manager_user(data):
    with _database() as (conn, cursor):
        try:
            cursor.execute("""
                INSERT INTO users (id_user, nom, prenom, cin, date_naiss, teleph, role, pw_user)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (data['id_user'], data['nom'], data['prenom'], int(data['cin']),
                  data.get('date_naiss'), data.get('teleph') or None,
                  data['role'], data['pw_user']))
            conn.commit()
        except Exception:
            conn.rollback()
            raise
    return {key: value for key, value in data.items() if key != 'pw_user'}
