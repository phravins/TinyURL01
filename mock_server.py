import http.server
import os
import sys

# Change dir to serve the frontend files
project_root = os.path.dirname(os.path.abspath(__file__))
www_dir = os.path.join(project_root, 'apps', 'shortener_api', 'priv', 'www')

if not os.path.exists(www_dir):
    print(f"Error: Could not find UI directory at {www_dir}")
    sys.exit(1)

os.chdir(www_dir)

class MockHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/api/shorten':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"short_url":"http://localhost:8000/XyZ123","short_code":"XyZ123"}')
            return
        self.send_error(404)

    def do_GET(self):
        if self.path.startswith('/api/stats/'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"click_count": 1337, "long_url": "https://erlang.org", "created_at": "2026-03-12T10:00:00Z", "expires_at": null}')
            return
        elif self.path.startswith('/api/qr/'):
            # Just return a dummy image instead of failing
            self.send_response(200)
            self.send_header('Content-Type', 'image/png')
            self.end_headers()
            self.wfile.write(b'fake-image-data')
            return
            
        return super().do_GET()

if __name__ == '__main__':
    sys.stdout.write("Starting mock server on 8000...\n")
    sys.stdout.flush()
    http.server.test(HandlerClass=MockHandler, port=8000, bind='127.0.0.1')
