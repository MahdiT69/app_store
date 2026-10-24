from dbConnection import get_connection

def get_products(search=None, category=None, page=1, page_size=6, sort="recent"):
    conn = get_connection()
    cursor = conn.cursor()

    where_clauses = ["is_active = 1"]
    params = []

    if search:
        where_clauses.append("(name LIKE ? OR description LIKE ?)")
        params.extend([f"%{search}%", f"%{search}%"])

    if category and category != "all":
        where_clauses.append("category = ?")
        params.append(category)

    where_sql = " AND ".join(where_clauses)

    order_sql = "created_at DESC"
    if sort == "price-asc":
        order_sql = "price ASC"
    elif sort == "price-desc":
        order_sql = "price DESC"
    elif sort == "name":
        order_sql = "name ASC"

    # total count for pagination
    count_query = f"SELECT COUNT(*) FROM products WHERE {where_sql}"
    cursor.execute(count_query, params)
    total = cursor.fetchone()[0]

    offset = (page - 1) * page_size
    query = f"""
        SELECT id, name, description, category, price, stock, image_url
        FROM products
        WHERE {where_sql}
        ORDER BY {order_sql}
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
    """
    cursor.execute(query, params + [offset, page_size])

    columns = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    products = [dict(zip(columns, row)) for row in rows]

    cursor.close()
    conn.close()

    return {"products": products, "total": total}


def get_categories():
    conn = get_connection()
    cursor = conn.cursor()
    query="""
    SELECT DISTINCT category FROM products WHERE is_active = 1
    """
    cursor.execute(query)
    categories = [row[0] for row in cursor.fetchall()]
    cursor.close()
    conn.close()
    return categories

def create_product(name, description, category, price, stock, image_url):
    conn = get_connection()
    cursor = conn.cursor()
    query = """
    INSERT INTO products (name, description, category, price, stock, image_url, is_active)
    VALUES (?, ?, ?, ?, ?, ?, 1)
    """
    cursor.execute(query, (name, description, category, price, stock, image_url))
    
    conn.commit()
    cursor.close()
    conn.close()
    return True


def get_all_products_for_employee():
    conn = get_connection()
    cursor = conn.cursor()
    query="""
        SELECT id, name, description, category, price, stock, image_url
        FROM products
        WHERE is_active = 1
        ORDER BY name ASC
    """
    cursor.execute(query)
    columns = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    products = [dict(zip(columns, row)) for row in rows]
    cursor.close()
    conn.close()
    return products