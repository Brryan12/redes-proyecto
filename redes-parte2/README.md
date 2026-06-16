\# Proyecto de Redes - Parte 2



Aplicación web sencilla en Python Flask, contenerizada con Docker y desplegada automáticamente en Azure Kubernetes Service mediante GitHub Actions.



\## Ejecutar localmente



```bash

python -m venv venv

pip install -r requirements.txt

python app.py

Abrir:

http://localhost:5000

```

\## Docker

\## Construir la imagen 

```bash

docker build -t redes-parte2 .

```

\## Ejecutar el contenedor 

```bash

docker run -p 5000:5000 redes-parte2

```

\## Acceder a la aplicación

```bash

http://localhost:5000

```



