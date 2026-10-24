from dataDao import DataDao
# pyrefly: ignore [missing-import]
from flask import Flask, request, jsonify
from flask_cors import CORS
from routes.product_routes import product_bp
# pyrefly: ignore [missing-import]
from routes.auth_routes import auth_bp 
from routes.user_routes import user_bp
# pyrefly: ignore [missing-import]
from routes.invoice_routes import invoice_bp
from routes.manager_routes import manager_bp

app = Flask(__name__)

CORS(app) 

dao = DataDao()
app.register_blueprint(product_bp, url_prefix="/products")
app.register_blueprint(auth_bp)
app.register_blueprint(user_bp, url_prefix="/users")
app.register_blueprint(invoice_bp, url_prefix="/invoices")
app.register_blueprint(manager_bp, url_prefix="/manager")


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
