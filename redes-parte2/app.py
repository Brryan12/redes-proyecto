from flask import Flask
import socket

app = Flask(__name__)

@app.route("/")
def home():
    hostname = socket.gethostname()
    return f"""
    <!DOCTYPE html>
    <html>
    <head><title>Proyecto Redes - K8s</title></head>
    <body>
        <h1>Proyecto Redes EIF-208</h1>
        <p>Aplicación desplegada en AKS.</p>
        <p>Pod: <strong>{hostname}</strong></p>
    </body>
    </html>
    """

@app.route("/health")
def health():
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)