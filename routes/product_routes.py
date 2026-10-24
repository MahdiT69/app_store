# pyrefly: ignore [missing-import]
from flask import Blueprint, request, jsonify
from dao.product_dao import get_products, get_categories,create_product, get_all_products_for_employee

product_bp = Blueprint("products", __name__)

@product_bp.route("/", methods=["GET"])
def list_products():
    search = request.args.get("search", "")
    category = request.args.get("category", "all")
    page = int(request.args.get("page", 1))
    page_size = int(request.args.get("page_size", 6))
    sort = request.args.get("sort", "recent")

    result = get_products(search, category, page, page_size, sort)
    return jsonify({
        "success": True,
        "products": result["products"],
        "total": result["total"],
        "page": page,
        "page_size": page_size
    }), 200


@product_bp.route("/categories", methods=["GET"])
def list_categories():
    return jsonify({"success": True, "categories": get_categories()}), 200

@product_bp.route("/employee-list", methods=["GET"])
def employee_products():
    products = get_all_products_for_employee()
    return jsonify({"success": True, "products": products}), 200

@product_bp.route("/", methods=["POST"])
def add_product():
    data = request.get_json()
    required = ["name", "price", "stock"]
    if not all(k in data for k in required):
        return jsonify({"success": False, "message": "Missing required fields"}), 400

    create_product(
        data.get("name"),
        data.get("description", ""),
        data.get("category", ""),
        data.get("price"),
        data.get("stock"),
        data.get("image_url", "")
    )
    return jsonify({"success": True}), 201