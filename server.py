import socket
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
import urllib.parse
import json

TCP_HOST = "localhost" 
TCP_PORT = 1111       

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client_socket.connect((TCP_HOST, TCP_PORT))

messages = []

def listen_tcp():
    global messages
    while True:
        data = client_socket.recv(1024)
        if not data:
            break
        messages.append(data.decode("utf-8"))
        messages = messages[-10:]

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global messages
        parsed_path = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed_path.query)

        if parsed_path.path == "/send_msg":
            msg = params.get("msg", [""])[0]
            if msg:
                send_to_tcp(msg)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"Message sent")
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Message is empty")

        elif parsed_path.path == "/get_msgs":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(messages).encode())

        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not found")

def send_to_tcp(msg):
    client_socket.send(msg.encode("utf-8"))

def run_http_server():
    server_address = ("", 8080)
    httpd = HTTPServer(server_address, RequestHandler)
    print("HTTP server started on port 8080")
    httpd.serve_forever()

threading.Thread(target=listen_tcp, daemon=True).start()
run_http_server()
