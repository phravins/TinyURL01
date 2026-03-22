import http.server
import json
import os
import sys
import string
import random
from datetime import datetime, timedelta

# Change dir to serve the frontend files
project_root = os.path.dirname(os.path.abspath(__file__))
www_dir = os.path.join(project_root, 'apps', 'shortener_api', 'priv', 'www')
db_path = os.path.join(www_dir, 'links.json')

if not os.path.exists(www_dir):
    print(f"Error: Could not find UI directory at {www_dir}")
    sys.exit(1)

os.chdir(www_dir)

# Initialize DB
if not os.path.exists(db_path):
    with open(db_path, 'w') as f:
        json.dump({}, f)

def load_db():
    with open(db_path, 'r') as f:
        return json.load(f)

def save_db(data):
    with open(db_path, 'w') as f:
        json.dump(data, f, indent=2)

def generate_code(length=6):
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

class FunctionalHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/api/shorten':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            try:
                payload = json.loads(post_data.decode('utf-8'))
                long_url = payload.get('url')
                if not long_url:
                    self.send_error_json(400, "URL is required")
                    return
                
                custom_code = payload.get('custom_code')
                ttl = payload.get('ttl')
                
                db = load_db()
                code = custom_code if custom_code else generate_code()
                
                if code in db:
                    self.send_error_json(400, "Custom code already exists")
                    return
                
                created_at = datetime.utcnow()
                expires_at = None
                if ttl:
                    expires_at = created_at + timedelta(seconds=int(ttl))
                
                db[code] = {
                    "long_url": long_url,
                    "click_count": 0,
                    "created_at": created_at.isoformat() + "Z",
                    "expires_at": expires_at.isoformat() + "Z" if expires_at else None
                }
                save_db(db)
                
                short_url = f"http://localhost:8000/{code}"
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "short_url": short_url,
                    "short_code": code
                }).encode('utf-8'))
                return
            except Exception as e:
                self.send_error_json(400, str(e))
                return
                
        self.send_error(404)

    def do_GET(self):
        # 1. Stats API
        if self.path.startswith('/api/stats/'):
            code = self.path.split('/')[-1]
            db = load_db()
            if code in db:
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(db[code]).encode('utf-8'))
            else:
                self.send_error_json(404, "Short code not found")
            return
            
        # 2. QR API
        elif self.path.startswith('/api/qr/'):
            code = self.path.split('/')[-1]
            self.send_response(302)
            self.send_header('Location', f"https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=http://localhost:8000/{code}")
            self.end_headers()
            return

        # 3. Redirector
        path_segments = self.path.strip('/').split('/')
        if len(path_segments) == 1 and path_segments[0] and '.' not in path_segments[0]:
            code = path_segments[0]
            db = load_db()
            if code in db:
                db[code]["click_count"] += 1
                save_db(db)
                self.send_response(302)
                self.send_header('Location', db[code]["long_url"])
                self.end_headers()
                return
            else:
                # Fallthrough to 404 handler for files
                pass
            
        return super().do_GET()

    def send_error_json(self, status, message):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"error": message}).encode('utf-8'))

if __name__ == '__main__':
    sys.stdout.write("Starting fully functional local server on 8000...\n")
    sys.stdout.flush()
    http.server.test(HandlerClass=FunctionalHandler, port=8000, bind='127.0.0.1')
