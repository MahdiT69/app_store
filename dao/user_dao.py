from dbConnection import get_connection

def get_user_by_id(user_id):
    conn = get_connection()
    cursor = conn.cursor()
    query="""SELECT id_user, nom, prenom, teleph, role 
        FROM users WHERE id_user = ?"""
    cursor.execute(query,(user_id))
    row = cursor.fetchone()
    user = None
    if row:
        columns = [c[0] for c in cursor.description]
        user = dict(zip(columns, row))
    cursor.close()
    conn.close()
    return user


def update_user(user_id, full_name=None, phone=None):
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if full_name is not None:
        updates.append("nom = ?")
        params.append(full_name)
  
    if phone is not None:
        updates.append("teleph = ?")
        params.append(phone)

    if not updates:
        cursor.close()
        conn.close()
        return False

    params.append(user_id)
    query = f"UPDATE users SET {', '.join(updates)} WHERE id_user = ?"
    cursor.execute(query, params)
    conn.commit()

    affected = cursor.rowcount
    cursor.close()
    conn.close()
    return affected > 0


def update_password(user_id, new_password):
    conn = get_connection()
    cursor = conn.cursor()
    query ="""
    UPDATE users SET pw_user = ? WHERE id_user = ?
    """
    cursor.execute(query, (new_password, user_id))
    conn.commit()
    affected = cursor.rowcount
    cursor.close()
    conn.close()
    return affected > 0


def get_suppliers():
    conn = get_connection()
    cursor = conn.cursor()
    query = """
    SELECT id_user, nom, prenom FROM users WHERE role = 'supplier'
    """
    cursor.execute(query)
    columns = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    suppliers = [dict(zip(columns, row)) for row in rows]
    cursor.close()
    conn.close()
    return suppliers