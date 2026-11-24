import os, hmac
import psycopg
from flask import Flask, request, jsonify
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16384

def connect():
    return psycopg.connect(host=os.environ['DB_HOST'], dbname=os.getenv('DB_NAME','orders'), user=os.environ['DB_USER'], password=os.environ['DB_PASSWORD'], sslmode=os.getenv('DB_SSLMODE','verify-full'), connect_timeout=5)

@app.before_request
def authorize():
    if request.path == '/health':
        return None
    token = os.getenv('DEMO_TOKEN','')
    if not token or not hmac.compare_digest(request.headers.get('Authorization','').encode(), ('Bearer '+token).encode()):
        return jsonify(error='Unauthorized'), 401

@app.get('/health')
def health():
    return jsonify(status='ok')

@app.get('/api/products')
def products():
    with connect() as db:
        rows=db.execute('SELECT id,name,price FROM products ORDER BY id').fetchall()
    return jsonify([dict(id=i,name=n,price=str(p)) for i,n,p in rows])

@app.get('/api/orders')
def orders():
    with connect() as db:
        rows=db.execute('SELECT id,product_id,quantity,status FROM orders ORDER BY id DESC LIMIT 100').fetchall()
    return jsonify([dict(id=i,product_id=p,quantity=q,status=s) for i,p,q,s in rows])

@app.post('/api/orders')
def create_order():
    data=request.get_json(silent=True)
    if not isinstance(data,dict): return jsonify(error='Invalid JSON'),400
    p,q=data.get('product_id'),data.get('quantity')
    if type(p) is not int or type(q) is not int or not 1<=p<=2147483647 or not 1<=q<=100:
        return jsonify(error='Invalid product or quantity'),400
    with connect() as db:
        if not db.execute('SELECT 1 FROM products WHERE id=%s',(p,)).fetchone(): return jsonify(error='Unknown product'),404
        row=db.execute('INSERT INTO orders(product_id,quantity) VALUES (%s,%s) RETURNING id',(p,q)).fetchone()
    return jsonify(id=row[0]),201
