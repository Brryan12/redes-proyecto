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
        <h2>Parte 2: creación, automatización y despliegue de una aplicación web sencilla</h2>
        <p>Aplicación desplegada en AKS.</p>
        <p>Estudiantes: Sebas</p> 
        <p>Gloriana Mojica Rojas</p>
        <p>Priscilla Murillo</p>
        <p>Steven Moya</p>
        <p>Pod: <strong>{hostname}</strong></p>
    </body>
    </html>
    """

@app.route("/health")
def health():
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)