from dbConnection import get_connection

def check_login(id_user, pw_user):
    conn = get_connection()
    cursor = conn.cursor()

    query = """SELECT * FROM users
    WHERE id_user = ? 
    AND pw_user = ?"""
    cursor.execute(query, (id_user, pw_user))

    row = cursor.fetchone()

    user = None
    if row:
        columns = [column[0] for column in cursor.description]
        user = dict(zip(columns, row))

    cursor.close()
    conn.close()

    return user